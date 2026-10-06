"""Execute fixed acceptance against a builder binary and raw TLC DOT graph."""
import argparse
import json
import re
import select
import socket
import statistics
import subprocess
import time
from pathlib import Path

from oracle import (ACTIONS, COMMANDS, CONTROL_TRACES, EXAMPLES, check_oracle,
                    explore, initial, key, step)


def expect(actual, expected, context):
    if actual != expected:
        raise AssertionError(json.dumps(dict(context=context, expected=expected,
                                            actual=actual), sort_keys=True))


def tla_value(value):
    if value in ("TRUE", "FALSE"):
        return value == "TRUE"
    if value.startswith('"'):
        return json.loads(value)
    if value.startswith("<<") or value.startswith("{"):
        body = value[2:-2] if value.startswith("<<") else value[1:-1]
        values = [int(v.strip()) for v in body.split(",") if v.strip()]
        return sorted(values) if value.startswith("{") else values
    return int(value)


def check_graph(path, states, edges):
    nodes, observed_edges, initial_ids = {}, [], []
    for line in Path(path).read_text().splitlines():
        edge = re.match(r'^(-?\d+) -> (-?\d+) \[label="([^"]+)"', line)
        if edge:
            observed_edges.append(edge.groups())
            continue
        node = re.match(r'^(-?\d+) \[label="((?:\\.|[^"\\])*)"', line)
        if node:
            fingerprint, raw = node.groups()
            label = json.loads('"' + raw + '"')
            state = {}
            for field in label.splitlines():
                field = field.removeprefix("/\\ ")
                name, value = field.split(" = ", 1)
                state[name] = tla_value(value)
            nodes[fingerprint] = key(state)
            if "style = filled" in line:
                initial_ids.append(fingerprint)
    expect(len(initial_ids), 1, "TLC initial node count")
    expect(nodes[initial_ids[0]], key(initial()), "TLC initial state")
    observed_states = set(nodes.values())
    expected_states = set(states)
    if observed_states != expected_states:
        raise AssertionError({"model_missing_states": len(expected_states - observed_states),
                              "model_extra_states": len(observed_states - expected_states)})
    observed = set()
    for source, target, action in observed_edges:
        if nodes[source] != nodes[target]:
            observed.add((nodes[source], ACTIONS[action], nodes[target]))
    if observed != edges:
        raise AssertionError({"model_missing_edges": len(edges - observed),
                              "model_extra_edges": len(observed - edges),
                              "example_missing": next(iter(edges - observed), None),
                              "example_extra": next(iter(observed - edges), None)})
    return dict(states=len(observed_states), edges=len(observed))


def stop(proc):
    # Cleanup on success and failure, bounded even if the child ignores EOF.
    if proc.poll() is None:
        proc.terminate()
        try:
            proc.wait(timeout=2)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait(timeout=2)


class Stdio:
    def __init__(self, binary):
        self.proc = subprocess.Popen([binary, "--stdio"], stdin=subprocess.PIPE,
                                     stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                     text=True, bufsize=1)
        self.responses = 0

    def call(self, command):
        self.proc.stdin.write(command + "\n")
        self.proc.stdin.flush()
        if not select.select([self.proc.stdout], [], [], 3)[0]:
            raise TimeoutError("stdio command timed out: " + command)
        line = self.proc.stdout.readline()
        if not line:
            raise AssertionError("premature EOF: " + command)
        self.responses += 1
        return json.loads(line)

    def close(self):
        stop(self.proc)
        for stream in (self.proc.stdin, self.proc.stdout, self.proc.stderr):
            stream.close()


def run_trace(client, commands, context):
    state = initial()
    expect(client.call("reset"), {"status": "ok", "state": state}, context + ": reset")
    for command in commands:
        expected = step(state, command)
        expect(client.call(command), expected, context + ": " + command)
        state = expected["state"]
    return state


def check_runtime(binary, states, paths):
    client = Stdio(binary)
    transitions = 0
    try:
        for name, (commands, expected) in EXAMPLES.items():
            expect(run_trace(client, commands, name), expected, name)
        for name, commands in CONTROL_TRACES.items():
            run_trace(client, commands, name)
        checks = COMMANDS + ["snapshot", "enqueue 0", "enqueue 4", "enqueue 01", "unknown", ""]
        for index, (state_key, before) in enumerate(states.items()):
            path = paths[state_key]
            for command in checks:
                run_trace(client, path, f"state {index} replay")
                expect(client.call(command), step(before, command), f"state {index}: {command}")
                transitions += 1
        return dict(reachable_states=len(states), commands_per_state=len(checks),
                    checked_transitions=transitions, responses=client.responses)
    finally:
        client.close()


def check_socket(binary):
    proc = subprocess.Popen([binary, "--listen", "127.0.0.1:0"], stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE, text=True)
    try:
        if not select.select([proc.stdout], [], [], 5)[0]:
            raise TimeoutError("TCP listener startup")
        line = proc.stdout.readline().strip()
        match = re.fullmatch(r"LISTEN 127\.0\.0\.1:(\d+)", line)
        if not match:
            raise AssertionError("bad TCP announcement: " + line)
        latencies, windows = [], []
        with socket.create_connection(("127.0.0.1", int(match.group(1))), timeout=3) as conn:
            conn.settimeout(3)
            with conn.makefile("rwb", buffering=0) as stream:
                class Client:
                    def call(self, command):
                        start = time.perf_counter_ns()
                        stream.write((command + "\n").encode())
                        line = stream.readline()
                        if not line:
                            raise AssertionError("connection closed across update")
                        latencies.append((time.perf_counter_ns() - start) / 1e6)
                        return json.loads(line)
                client = Client()
                for repeat in range(25):
                    for name, (commands, expected) in EXAMPLES.items():
                        expect(run_trace(client, commands, name), expected, name)
                    for name, commands in CONTROL_TRACES.items():
                        run_trace(client, commands, name)
                    state = initial()
                    expect(client.call("reset"), {"status": "ok", "state": state}, "TCP reset")
                    start = None
                    for command in ["enqueue 3", "enqueue 1", "begin", "prepare", "copy", "copy",
                                    "validate", "activate", "start", "finish", "start", "finish"]:
                        if command == "begin":
                            start = time.perf_counter_ns()
                        reply = step(state, command)
                        expect(client.call(command), reply, "TCP timing: " + command)
                        state = reply["state"]
                        if command == "activate":
                            windows.append((time.perf_counter_ns() - start) / 1e6)
        proc.wait(timeout=3)
        expect(proc.returncode, 0, "TCP clean EOF exit")
        ordered = sorted(latencies)
        return dict(connections=1, repetitions=25, commands=len(latencies),
                    command_ms=dict(median=statistics.median(latencies),
                                    p95=ordered[int(.95 * (len(ordered) - 1))], max=max(latencies)),
                    observed_begin_to_activate_ms=dict(median=statistics.median(windows), max=max(windows)),
                    meaning="Local single-client harness timings, including Python and socket overhead; no SLA")
    finally:
        stop(proc)
        proc.stdout.close()
        proc.stderr.close()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--binary", required=True)
    parser.add_argument("--dot")
    parser.add_argument("--control", choices=CONTROL_TRACES)
    args = parser.parse_args()
    examples, controls = check_oracle()
    if args.control:
        client = Stdio(args.binary)
        try:
            run_trace(client, CONTROL_TRACES[args.control], args.control)
        finally:
            client.close()
        print(json.dumps({"control_trace": args.control, "result": "matches contract"}))
        return
    states, paths, edges = explore()
    result = dict(examples=examples, rejected_public_response_mutants=controls)
    if not args.dot:
        raise AssertionError("Full acceptance requires a completed TLC graph")
    result["model_correspondence"] = check_graph(args.dot, states, edges)
    result["runtime"] = check_runtime(args.binary, states, paths)
    result["tcp"] = check_socket(args.binary)
    result["result"] = "PASS"
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
