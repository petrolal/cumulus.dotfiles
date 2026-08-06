#!/usr/bin/env python3
"""
autotiling.py — Fibonacci spiral autotiling for Sway.

Listens to Sway IPC window events and automatically sets split direction
(splith / splitv) on the focused window based on its aspect ratio (width vs height).
This creates a continuous Fibonacci spiral tiling layout for new windows.
"""

import json
import os
import socket
import struct
import subprocess
import sys

MAGIC = b"i3-ipc"
RUN_COMMAND = 0
GET_TREE = 4
SUBSCRIBE = 2


def get_socket_path():
    sock = os.environ.get("SWAYSOCK")
    if not sock:
        try:
            res = subprocess.check_output(["swaymsg", "-t", "get_version"], text=True)
            sock = os.environ.get("SWAYSOCK")
        except Exception:
            pass
    return sock


def pack_message(msg_type, payload=""):
    payload_bytes = payload.encode("utf-8")
    header = struct.pack("=6sII", MAGIC, len(payload_bytes), msg_type)
    return header + payload_bytes


def unpack_header(sock):
    header = sock.recv(14)
    if len(header) < 14:
        return None, None
    magic, length, msg_type = struct.unpack("=6sII", header)
    if magic != MAGIC:
        return None, None
    body = b""
    while len(body) < length:
        chunk = sock.recv(length - len(body))
        if not chunk:
            break
        body += chunk
    return msg_type, body.decode("utf-8")


def find_focused(node):
    if node.get("focused"):
        return node
    for child in node.get("nodes", []) + node.get("floating_nodes", []):
        res = find_focused(child)
        if res:
            return res
    return None


def get_tree(sock):
    sock.sendall(pack_message(GET_TREE))
    msg_type, payload = unpack_header(sock)
    if payload:
        return json.loads(payload)
    return None


def send_command(sock, cmd):
    sock.sendall(pack_message(RUN_COMMAND, cmd))
    unpack_header(sock)


def main():
    sock_path = get_socket_path()
    if not sock_path or not os.path.exists(sock_path):
        sys.exit("SWAYSOCK not available")

    cmd_sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    cmd_sock.connect(sock_path)

    event_sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    event_sock.connect(sock_path)

    event_sock.sendall(pack_message(SUBSCRIBE, json.dumps(["window"])))
    unpack_header(event_sock)

    while True:
        msg_type, payload = unpack_header(event_sock)
        if payload is None:
            break
        try:
            event = json.loads(payload)
        except Exception:
            continue

        change = event.get("change")
        if change in ("focus", "new"):
            tree = get_tree(cmd_sock)
            if not tree:
                continue
            focused = find_focused(tree)
            if not focused:
                continue

            rect = focused.get("rect", {})
            width = rect.get("width", 0)
            height = rect.get("height", 0)

            if width > 0 and height > 0:
                if width >= height:
                    send_command(cmd_sock, "splith")
                else:
                    send_command(cmd_sock, "splitv")


if __name__ == "__main__":
    main()
