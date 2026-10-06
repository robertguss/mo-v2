"""Supplementary measurement, not a replacement for locked acceptance.

The frozen load driver stops controller polling while awaiting producers. Its
largest observed completion gap therefore includes a sampling gap. This extra
run adds a dedicated observer, retaining its overhead and sampling uncertainty.
"""
import json
import threading
import time
from pathlib import Path

import run


def main():
    base=Path(__file__).resolve().parents[1]
    out=base/"evidence/continuous-observer"
    out.mkdir(exist_ok=True)
    binary=json.loads((base/"evidence/build-02.json").read_text())["binary"]
    server=run.Server(binary)
    observer=run.Client(server)
    stopped=threading.Event()
    observations,errors=[],[]
    def observe():
        try:
            while not stopped.is_set():
                observations.append(observer.call("snapshot"))
                stopped.wait(.002)
        except Exception as error:
            errors.append(repr(error))
    thread=threading.Thread(target=observe)
    thread.start()
    try:
        result=run.load(server)
    finally:
        stopped.set()
        thread.join(timeout=3)
        server.close()
        (out/"events.json").write_text(json.dumps(server.events)+"\n")
        (out/"observations.json").write_text(json.dumps(observations)+"\n")
        (out/"teardown.json").write_text(json.dumps(server.teardown)+"\n")
    assert not thread.is_alive() and not errors,errors
    assert not server.teardown["forced"] and server.teardown["exit"]==0
    times=[s["now_us"] for s in observations]
    counts=[len(s["completed"]) for s in observations]
    assert counts==sorted(counts)
    intervals=[(b-a)/1000 for a,b in zip(times,times[1:])]
    progress=[]
    last_time=None
    last_count=0
    for s in observations:
        count=len(s["completed"])
        if count>last_count:
            if last_time is not None:
                progress.append((s["now_us"]-last_time)/1000)
            last_time=s["now_us"]
            last_count=count
    result["continuous_observer"]=dict(snapshots=len(observations),
        max_snapshot_interval_ms=max(intervals),max_observed_progress_interval_ms=max(progress),
        first_completed_count=counts[0],last_completed_count=counts[-1],
        meaning="Additional observer adds contention; sampled progress intervals are not exact per-job gaps or an SLA")
    (out/"results.json").write_text(json.dumps(result,indent=2)+"\n")
    print(json.dumps(result,indent=2))


if __name__=="__main__":
    main()
