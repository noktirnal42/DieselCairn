#!/usr/bin/env python3
"""Build and smoke-test DieselCairn's stdio MCP server without vehicle I/O."""

import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
subprocess.run(["swift", "build", "--product", "DieselCairnMCP"], cwd=ROOT, check=True)
server = subprocess.Popen(
    [str(ROOT / ".build/debug/DieselCairnMCP")],
    cwd=ROOT,
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
)


def receive():
    header = bytearray()
    while not header.endswith(b"\r\n\r\n"):
        byte = server.stdout.read(1)
        if not byte:
            raise AssertionError(f"MCP server exited unexpectedly ({server.poll()})")
        header.extend(byte)
    length = int(
        next(
            line.split(b":", 1)[1].strip()
            for line in header.split(b"\r\n")
            if line.lower().startswith(b"content-length:")
        )
    )
    return json.loads(server.stdout.read(length))


def rpc(request_id, method, params=None):
    body = json.dumps(
        {"jsonrpc": "2.0", "id": request_id, "method": method, "params": params or {}},
        separators=(",", ":"),
    ).encode()
    server.stdin.write(b"Content-Length: " + str(len(body)).encode() + b"\r\n\r\n" + body)
    server.stdin.flush()
    return receive()


def call(request_id, name, arguments=None):
    response = rpc(
        request_id,
        "tools/call",
        {"name": name, "arguments": arguments or {}},
    )
    if "error" in response:
        return response["error"]
    text = response["result"]["content"][0]["text"]
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        return text


try:
    initialized = rpc(1, "initialize", {"protocolVersion": "2025-03-26"})
    assert initialized["result"]["serverInfo"]["name"] == "dieselcairn"
    tools = rpc(2, "tools/list")["result"]["tools"]
    assert len(tools) >= 18
    profile = call(3, "vehicle_get_profile")
    assert profile["transmissionModel"] == "3000PTS"

    state = call(4, "simulator_connect", {"scenario": "Road cruise"})
    assert state["connected"] and state["running"]
    frame = call(
        5,
        "simulator_send_frame",
        {"pgn": 61444, "sourceAddress": 0, "priority": 3, "payload": [255, 255, 255, 64, 31, 255, 255, 255]},
    )
    assert frame["accepted"]
    j1587 = call(6, "simulator_send_j1587", {"mid": 128, "data": [16, 42]})
    assert j1587["bytes"] == "80 10 2A 45"

    invalid_calls = [
        ("simulator_send_frame", {"pgn": 61444, "sourceAddress": 0, "priority": 256, "payload": [255] * 8}),
        ("simulator_send_frame", {"pgn": 61444, "sourceAddress": 256, "priority": 3, "payload": [255] * 8}),
        ("simulator_connect", {"scenario": "invented"}),
        ("simulator_load_replay", {"frames": [{"identifier": 4294967295, "payload": [0]}]}),
        ("simulator_set_controls", {"gear": 1e300}),
        ("simulator_set_controls", {"j1708Priority": 1e300}),
        ("simulator_set_controls", {"bitrate": 250000.5}),
        ("simulator_send_frame", {"pgn": 61444.5, "sourceAddress": 0, "priority": 3, "payload": [255] * 8}),
    ]
    for request_id, (name, arguments) in enumerate(invalid_calls, 7):
        assert call(request_id, name, arguments).get("code") == -32000
        assert server.poll() is None

    decimal_pgn = call(15, "simulator_send_frame", {"pgn": "61444", "sourceAddress": 0, "priority": 3, "payload": [255] * 8})
    assert decimal_pgn["accepted"] and decimal_pgn["frame"]["pgn"] == "0F004"

    payload = b"qa-only-calibration-fixture"
    project = call(
        16,
        "flash_build_project",
        {"payloadBase64": __import__("base64").b64encode(payload).decode(), "module": "Engine ECM", "filename": "fixture.bin"},
    )
    valid = call(17, "flash_validate_project", {"projectJSON": json.dumps(project)})
    assert valid["validProject"] and valid["payloadBytes"] == len(payload)
    capability = call(18, "flash_write_capability")
    assert capability["available"] is False and "no live write command" in capability["reason"].lower()
    print("PASS: MCP initialization, tools, profile, virtual J1939/J1587, range/overflow rejection, decimal PGN parsing, flash manifest integrity, and write boundary")
finally:
    server.terminate()
    server.wait(timeout=5)
