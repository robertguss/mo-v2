"""Lead-authored public TCP checks. Freeze before builder implementation."""
import argparse
import concurrent.futures
import json
import select
import socket
import statistics
import subprocess
import threading
import time
from pathlib import Path

import model_oracle

FIELDS = set("status now_us epoch schema phase pending work_held queue flight accepted completed attempts".split())
ATTEMPT_FIELDS = set("id mode status base_epoch finished_epoch started_us deadline_us finished_us stage worker_returned late_discarded".split())


def require(condition, message):
    if not condition:
        raise AssertionError(message)


class Client:
    def __init__(self, server):
        self.server = server
        self.conn = socket.create_connection(("127.0.0.1", server.port), timeout=2)
        self.conn.settimeout(2)
        self.stream = self.conn.makefile("rwb", buffering=0)
        self.number = len(server.clients)
        server.clients.append(self)

    def call(self, command):
        start = time.monotonic()
        self.stream.write((command + "\n").encode())
        data = self.stream.readline()
        require(bool(data), "connection closed: " + command)
        reply = json.loads(data)
        self.server.events.append(dict(connection=self.number, command=command, reply=reply,
                                       at_ms=(start-self.server.origin)*1000,
                                       elapsed_ms=(time.monotonic()-start)*1000))
        return reply

    def ok(self, command):
        require(self.call(command) == {"status": "ok"}, "expected ok: " + command)

    def close(self):
        self.stream.close()
        self.conn.close()


class Server:
    def __init__(self, binary):
        self.events, self.clients, self.previous = [], [], None
        self.origin = time.monotonic()
        self.proc = subprocess.Popen([binary, "--listen", "127.0.0.1:0"],
                                     stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        self.teardown = None
        try:
            require(select.select([self.proc.stdout], [], [], 5)[0], "listener startup timeout")
            line = self.proc.stdout.readline().strip()
            require(line.startswith("LISTEN 127.0.0.1:"), "invalid listener announcement")
            self.port = int(line.rsplit(":", 1)[1])
            self.control = Client(self)
        except BaseException:
            self.close()
            raise

    def snapshot(self):
        s = self.control.call("snapshot")
        require(set(s) == FIELDS and s["status"] == "ok", "snapshot schema")
        require(s["schema"] == ("deque" if s["epoch"] % 2 == 0 else "map"), "representation parity")
        accepted, done, queue, flight = s["accepted"], s["completed"], s["queue"], s["flight"]
        require([r[0] for r in accepted] == list(range(1,len(accepted)+1)), "accepted sequence")
        require(len({r[1] for r in accepted}) == len(accepted), "duplicate accepted ID")
        require(all(len(r) == 3 for r in accepted+queue), "job schema")
        require(all(len(r) == 4 for r in done), "completion schema")
        require([r[0] for r in done] == list(range(1,len(done)+1)), "completion duplicated or out of order")
        require([r[:3] for r in done] == accepted[:len(done)], "completed payload changed")
        require([r[3] for r in done] == sorted(r[3] for r in done), "completion epoch regressed")
        require(all(0 <= r[3] <= s["epoch"] for r in done), "invalid completion epoch")
        require(flight is None or len(flight)==4 and flight[3]==s["epoch"], "old flight crossed activation")
        outstanding = ([] if flight is None else [flight[:3]]) + queue
        require(outstanding == accepted[len(done):], "accepted work lost or duplicated")
        require(len(outstanding) <= 8 and len(accepted) <= 256, "capacity exceeded")
        require(s["phase"] in ("running", "draining", "copying"), "invalid phase")
        require(s["phase"] != "copying" or flight is None, "copying with live work")
        require((s["pending"] == 0) == (s["phase"] == "running"), "authority phase")
        require(len(s["attempts"]) <= 32, "attempt bound")
        committed = 0
        for i, a in enumerate(s["attempts"], 1):
            require(set(a) == ATTEMPT_FIELDS and a["id"] == i, "attempt schema/identity")
            require(a["deadline_us"] == a["started_us"]+200000, "deadline interval")
            require(a["base_epoch"] == committed, "attempt base epoch")
            if a["status"] == "pending":
                require(a["finished_us"] is None and a["finished_epoch"] is None, "pending marked finished")
                require(a["id"]==s["pending"] and a["stage"]==s["phase"], "pending stage")
            else:
                require(a["status"] in ("activated", "invalid", "timeout"), "outcome")
                require(a["stage"]=="done" and a["started_us"] <= a["finished_us"] <= s["now_us"], "finish time/stage")
                if a["status"]=="activated":
                    require(a["finished_us"] < a["deadline_us"], "expired candidate activated")
                    committed += 1
                if a["status"]=="timeout":
                    require(a["deadline_us"] <= a["finished_us"] <= a["deadline_us"]+750000, "timeout outside fixed tolerance")
                require(a["finished_epoch"]==committed, "finish epoch")
        require(committed == s["epoch"], "epoch changed without activation")
        require(sum(a["status"]=="pending" for a in s["attempts"]) == bool(s["pending"]), "multiple pending attempts")
        if self.previous:
            p = self.previous
            require(s["accepted"][:len(p["accepted"])]==p["accepted"], "ack ledger rewritten")
            require(s["completed"][:len(p["completed"])]==p["completed"], "completion ledger rewritten")
            require(s["epoch"] >= p["epoch"], "epoch regression")
            for old, new in zip(p["attempts"], s["attempts"]):
                if old["status"] != "pending":
                    for k in ATTEMPT_FIELDS-{"worker_returned", "late_discarded"}:
                        require(old[k]==new[k], "terminal attempt rewritten: " + k)
                for k in ("worker_returned", "late_discarded"):
                    require(not old[k] or new[k], "worker event reverted")
        self.previous = s
        return s

    def wait(self, predicate, label, seconds=2):
        end = time.monotonic()+seconds
        while True:
            s = self.snapshot()
            if predicate(s):
                return s
            require(time.monotonic()<end, "timed out waiting for " + label)
            time.sleep(.002)

    def update(self, mode):
        reply = self.control.call("update " + mode)
        require(set(reply)=={"status","attempt"} and reply["status"]=="started", "update did not start")
        return reply["attempt"]

    def terminal(self, attempt, outcome):
        s = self.wait(lambda s:s["attempts"][attempt-1]["status"]!="pending", "update terminal", .95)
        require(s["attempts"][attempt-1]["status"]==outcome, "wrong update outcome: " + str(s["attempts"][attempt-1]))
        return s

    def close(self):
        forced = False
        try:
            if self.clients and self.proc.poll() is None:
                try:
                    self.control.ok("shutdown")
                except Exception:
                    pass
            for client in self.clients:
                client.close()
            try:
                self.proc.wait(timeout=2)
            except subprocess.TimeoutExpired:
                forced = True
                self.proc.kill()
                self.proc.wait(timeout=2)
        finally:
            if self.proc.poll() is None:
                forced = True
                self.proc.kill()
                self.proc.wait(timeout=2)
            stderr = self.proc.stderr.read()
            self.proc.stdout.close()
            self.proc.stderr.close()
            self.teardown = dict(forced=forced, exit=self.proc.returncode, stderr=stderr, reaped=True)


def submit(client, job, payload):
    reply = client.call(f"submit {job} {payload}")
    require(set(reply)=={"status","seq"} and reply["status"]=="accepted", "submit failed")
    return [reply["seq"], job, payload]


def seed(server):
    c = server.control
    c.ok("hold_work")
    rows = [submit(c,10,101)]
    server.wait(lambda s:s["flight"] is not None, "held old work")
    rows += [submit(c,30,303), submit(c,20,202)]
    return rows


def finish_jobs(server, rows):
    s = server.wait(lambda s:len(s["completed"])==len(rows), "all acknowledged completions", 5)
    require(s["accepted"]==sorted(rows), "receipt/accepted mismatch")
    require([r[:3] for r in s["completed"]]==sorted(rows), "receipt/completion mismatch")
    return s


def stale(server):
    c = server.control
    rows = seed(server)
    a = server.update("hold")
    c.ok("release_work")
    server.wait(lambda s:s["phase"]=="copying", "held migration")
    require(c.call("submit 40 404")=={"status":"busy"}, "copying admission not closed")
    require(c.call("update normal")=={"status":"busy"}, "overlapping update admitted")
    time.sleep(1.1)  # No client request can drive the deadline during this interval.
    s = server.terminal(a,"timeout")
    require(s["now_us"]-s["attempts"][a-1]["finished_us"]>=50000, "timeout occurred only when observed")
    require(not s["attempts"][a-1]["worker_returned"], "timeout waited for held migration")
    require(s["epoch"]==0, "timeout changed authority")
    rows.append(submit(c,40,404))
    finish_jobs(server,rows)
    b = server.update("normal")
    server.terminal(b,"activated")
    c.ok(f"release {a}")
    s = server.wait(lambda s:s["attempts"][a-1]["worker_returned"], "late worker return")
    require(s["attempts"][a-1]["late_discarded"], "stale result not discarded")
    require(s["epoch"]==1 and s["pending"]==0, "stale result published")
    rows.append(submit(c,50,505))
    finish_jobs(server,rows)
    return dict(timeout_attempt=a,newer_activation=b,late_result_rejected=True)


def drain(server):
    c = server.control
    rows = seed(server)
    a = server.update("normal")
    s = server.terminal(a,"timeout")
    require(s["flight"]==[1,10,101,0] and not s["completed"], "held active work changed")
    c.ok("release_work")
    finish_jobs(server,rows)
    b=server.update("normal")
    server.terminal(b,"activated")
    return dict(drain_timeout=a,recovery_activation=b)


def conservation(server):
    c=server.control
    require(c.call("unknown")=={"status":"invalid"},"unknown command accepted")
    require(c.call("submit 0 1")=={"status":"invalid"},"invalid ID accepted")
    require(c.call("submit 1 1000001")=={"status":"invalid"},"invalid payload accepted")
    rows=seed(server)
    require(c.call("submit 10 101")=={"status":"duplicate","seq":1},"retry duplicated")
    require(c.call("submit 10 102")=={"status":"conflict"},"conflicting retry accepted")
    a=server.update("normal")
    c.ok("release_work")
    server.terminal(a,"activated")
    finish_jobs(server,rows)
    for i in range(3):
        rows.append(submit(c,100+i,800+i))
        a=server.update("normal")
        server.terminal(a,"activated")
        finish_jobs(server,rows)
    require(server.snapshot()["epoch"]==4,"repeated update count")
    return dict(activations=4,jobs=len(rows))


def corrupt(server):
    c=server.control
    rows=seed(server)
    a=server.update("corrupt")
    c.ok("release_work")
    server.terminal(a,"invalid")
    finish_jobs(server,rows)
    a=server.update("normal")
    server.terminal(a,"activated")
    a=server.update("corrupt")
    s=server.terminal(a,"invalid")
    require(s["epoch"]==1,"empty corrupt candidate activated")
    return dict(nonempty_and_empty_corruption_refused=True)


def load(server):
    clients=[Client(server) for _ in range(4)]
    barrier=threading.Barrier(5)
    def produce(index):
        client=clients[index]
        receipts=[]
        barrier.wait(timeout=3)
        for j in range(40):
            job=(index+1)*1000+j
            payload=job*7
            end=time.monotonic()+10
            while True:
                reply=client.call(f"submit {job} {payload}")
                if reply["status"]=="accepted":
                    require(set(reply)=={"status","seq"},"submit response fields")
                    receipts.append([reply["seq"],job,payload])
                    retry=client.call(f"submit {job} {payload}")
                    require(retry=={"status":"duplicate","seq":reply["seq"]},"concurrent duplicate")
                    break
                require(reply=={"status":"busy"},"unexpected load rejection")
                require(time.monotonic()<end,"producer stalled")
                time.sleep(.002)
        return receipts
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        futures=[pool.submit(produce,i) for i in range(4)]
        barrier.wait(timeout=3)
        server.wait(lambda s:len(s["accepted"])>=4 and bool(s["completed"]),"load overlap")
        for i in range(8):
            a=server.update("normal")
            server.terminal(a,"activated")
            time.sleep(.02)
        rows=[r for future in futures for r in future.result(timeout=12)]
    s=finish_jobs(server,rows)
    require(len(rows)==160 and s["epoch"]==8,"load counts")
    first_row=sorted(rows)[0]
    require(server.control.call(f"submit {first_row[1]} {first_row[2]}")=={"status":"duplicate","seq":first_row[0]},"cross-client deduplication")
    epochs={r[3] for r in s["completed"]}
    require(len(epochs)>1,"no activation overlapped completed work")
    snaps=[e for e in server.events if e["command"]=="snapshot"]
    first=next(e for e in snaps if e["reply"]["completed"])
    last=next(e for e in snaps if len(e["reply"]["completed"])==160)
    require(any(first["reply"]["now_us"]<a["finished_us"]<last["reply"]["now_us"] for a in s["attempts"]),"no measured overlap")
    latencies=[e["elapsed_ms"] for e in server.events]
    busy=sum(e["reply"]=={"status":"busy"} for e in server.events)
    require(busy>0,"load did not exercise admission pressure")
    observed_completions=[e for e in snaps if e["reply"]["completed"]]
    gaps=[]
    previous=observed_completions[0]
    for event in observed_completions[1:]:
        if len(event["reply"]["completed"])>len(previous["reply"]["completed"]):
            gaps.append(event["at_ms"]-previous["at_ms"])
            previous=event
    windows=[]
    for attempt in range(1,9):
        samples=[e["at_ms"] for e in snaps if e["reply"]["pending"]==attempt and e["reply"]["phase"]=="copying"]
        windows.append(max(samples)-min(samples) if samples else None)
    return dict(jobs=160,activations=8,producer_connections=4,busy_replies=busy,
                request_ms=dict(median=statistics.median(latencies),p95=sorted(latencies)[int(.95*(len(latencies)-1))],max=max(latencies)),
                sampled_copying_windows_ms=windows,max_observed_completion_gap_ms=max(gaps,default=0))


SCENARIOS=dict(stale=stale,drain=drain,conservation=conservation,corrupt=corrupt,load=load)


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--binary",required=True)
    parser.add_argument("--dot")
    parser.add_argument("--scenario",choices=SCENARIOS)
    parser.add_argument("--output",required=True)
    args=parser.parse_args()
    out=Path(args.output);out.mkdir(parents=True,exist_ok=True)
    result={"runs":[]}
    if not args.scenario:
        require(args.dot is not None,"full acceptance requires TLC graph")
        result["model"]=model_oracle.check(args.dot)
    names=[args.scenario] if args.scenario else ["stale","drain","conservation","corrupt","load","load","load"]
    for index,name in enumerate(names):
        server=Server(args.binary)
        passed=False
        try:
            result["runs"].append(dict(scenario=name,result=SCENARIOS[name](server)))
            passed=True
        finally:
            server.close()
            (out/f"{index}-{name}-events.json").write_text(json.dumps(server.events)+"\n")
            (out/f"{index}-{name}-teardown.json").write_text(json.dumps(server.teardown)+"\n")
        if passed:
            require(not server.teardown["forced"] and server.teardown["exit"]==0,"unclean process teardown")
    result["result"]="PASS"
    (out/"results.json").write_text(json.dumps(result,indent=2)+"\n")
    print(json.dumps(result,indent=2))


if __name__=="__main__":
    main()
