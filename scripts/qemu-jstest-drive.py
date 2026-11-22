#!/usr/bin/env python3
"""Drive a booted OnyxOS guest: log in, run jstest, inject USB HID input via QMP.

Used by qemu-jstest-smoke.sh. Boots the S-mode kernel directly (OpenSBI
-kernel) with the OnyxFS disk, one qemu-xhci and N usb-tablet devices, logs in
as root, runs `jstest /dev/jsK` in the foreground and, through the QMP
`input-send-event` command, moves the first tablet and presses its left button.

Checks (serial log): init burst lines, live (non-init) axis 0/1 and button 0
down/up lines, and that no kernel trap/panic happened. Exit 0 = pass.
"""
import argparse
import json
import os
import re
import socket
import subprocess
import sys
import tempfile
import time


RUN_SECS = 12  # jstest -t bound per node


def wait_for(log, pattern, timeout, start=0):
    """Poll the serial log until `pattern` matches after offset `start`."""
    end = time.time() + timeout
    rx = re.compile(pattern)
    while time.time() < end:
        with open(log, "rb") as f:
            f.seek(start)
            m = rx.search(f.read().decode("utf-8", "replace"))
        if m:
            return True
        time.sleep(0.3)
    return False


def size(log):
    return os.path.getsize(log)


class Qmp:
    def __init__(self, path):
        for _ in range(50):
            try:
                self.s = socket.socket(socket.AF_UNIX)
                self.s.connect(path)
                break
            except OSError:
                time.sleep(0.2)
        else:
            raise RuntimeError("QMP socket never appeared")
        self.f = self.s.makefile("rw")
        self.f.readline()  # greeting
        self.cmd("qmp_capabilities")

    def cmd(self, name, **args):
        self.f.write(json.dumps({"execute": name, "arguments": args}) + "\n")
        self.f.flush()
        while True:  # skip async events
            reply = json.loads(self.f.readline())
            if "return" in reply or "error" in reply:
                return reply

    def send(self, events):
        r = self.cmd("input-send-event", events=events)
        if "error" in r:
            raise RuntimeError(f"input-send-event: {r['error']}")

    def move(self, x, y):
        self.send([{"type": "abs", "data": {"axis": "x", "value": x}},
                   {"type": "abs", "data": {"axis": "y", "value": y}}])

    def button(self, down):
        self.send([{"type": "btn", "data": {"down": down, "button": "left"}}])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--kernel", required=True)
    ap.add_argument("--disk", required=True)
    ap.add_argument("--log", required=True)
    ap.add_argument("--tablets", type=int, default=1)
    ap.add_argument("--timeout", type=int, default=150)
    a = ap.parse_args()

    sock = os.path.join(tempfile.mkdtemp(prefix="jsq."), "qmp.sock")
    cmd = ["qemu-system-riscv64", "-machine", "virt", "-m", "256M", "-nographic",
           "-bios", "default", "-kernel", a.kernel,
           "-drive", f"file={a.disk},format=raw,if=none,id=drive0",
           "-device", "virtio-blk-device,drive=drive0",
           "-qmp", f"unix:{sock},server=on,wait=off",
           "-device", "qemu-xhci"]
    for i in range(a.tablets):
        cmd += ["-device", f"usb-tablet,id=t{i}"]
    # Never write to the shared image: run on a throwaway snapshot.
    cmd += ["-snapshot"]
    out = open(a.log, "wb")
    q = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=out, stderr=subprocess.STDOUT)

    def say(text):
        q.stdin.write(text.encode())
        q.stdin.flush()

    def fail(msg):
        print(f"[-] FAIL: {msg}")
        sys.stdout.flush()
        q.kill()
        sys.exit(1)

    try:
        if not wait_for(a.log, r"login:", 120):
            fail("no login prompt")
        say("root\n")
        # First boot has an empty password: a prompt may or may not appear.
        if not wait_for(a.log, r"Login OK|[Pp]assword:", 20):
            fail("login did not progress")
        if wait_for(a.log, r"[Pp]assword:", 1):
            say("\n")
        if not wait_for(a.log, r"osh\$", 30):
            fail("no shell prompt")
        print("[+] logged in, shell prompt reached")
        qmp = Qmp(sock)

        # Node namespace: one jsN per tablet, no stale tail bytes ("js00").
        mark = size(a.log)
        say("ls /dev\n")
        if not wait_for(a.log, r"osh\$", 15, mark):
            fail("ls /dev did not return")
        listing = open(a.log, "rb").read()[mark:].decode("utf-8", "replace")
        for k in range(a.tablets):
            if not re.search(rf"\njs{k}\r?\n", listing):
                fail(f"/dev listing has no clean js{k} entry")
        if re.search(r"js\d\d", listing):
            fail("/dev listing has a corrupted js name (stale name tail)")
        print(f"[+] /dev lists js0..js{a.tablets - 1} cleanly")

        # Pointer #<first> of `info mice` is the tablet behind /dev/js0
        # (select it explicitly: with two tablets the default is the other
        # one). KNOWN GAP: the second tablet's reports never complete in
        # QEMU - the trace shows its wakeups kicking xHCI slot 1 - so live
        # input exists for js0 only; further nodes are checked for the
        # init burst, a clean -t exit and isolation (no event of tablet 0
        # leaks in). See OnyxKernel/todo.md.
        info = qmp.cmd("human-monitor-command", **{"command-line": "info mice"})
        ptrs = re.findall(r"Mouse #(\d+): QEMU HID Tablet", info.get("return", ""))
        if len(ptrs) != a.tablets:
            fail(f"expected {a.tablets} tablet pointers in `info mice`: {ptrs}")
        qmp.cmd("human-monitor-command", **{"command-line": f"mouse_set {ptrs[0]}"})
        for k in range(a.tablets):
            mark = size(a.log)
            say(f"jstest -t {RUN_SECS} /dev/js{k}\n")
            # Init burst: 2 axes + 5 buttons from the tablet baseline.
            if not wait_for(a.log, r"button 4 up \(init\)", 30, mark):
                fail(f"/dev/js{k}: init burst never completed")
            print(f"[+] js{k}: init burst received")
            burst_end = size(a.log)
            qmp.move(16384, 24576)
            qmp.button(True)
            time.sleep(1)
            qmp.button(False)
            qmp.move(4096, 8192)
            if k == 0:
                for pat, what in ((r"\naxis 0 = -?[1-9]\d*\r", "live axis 0"),
                                  (r"\naxis 1 = -?[1-9]\d*\r", "live axis 1"),
                                  (r"\nbutton 0 down\r", "button 0 down"),
                                  (r"\nbutton 0 up\r", "button 0 up")):
                    if not wait_for(a.log, pat, 15, burst_end):
                        fail(f"/dev/js{k}: no {what} event after QMP input")
                print(f"[+] js{k}: live axes + button down/up received")
            else:
                time.sleep(3)
                leaked = open(a.log, "rb").read()[burst_end:].decode("utf-8", "replace")
                if re.search(r"\n(axis|button) \d", leaked):
                    fail(f"/dev/js{k}: events of tablet 0 leaked into this node")
                print(f"[+] js{k}: no foreign events (per-node rings isolated)")
            # `-t` bounds the run: jstest must exit 0 back to the prompt.
            mark = size(a.log)
            if not wait_for(a.log, r"osh\$", RUN_SECS + 15, mark):
                fail(f"/dev/js{k}: jstest did not exit at its -t deadline")
            if wait_for(a.log, r"jstest: exited with code", 1, mark):
                fail(f"/dev/js{k}: jstest exited with a non-zero code")
            print(f"[+] js{k}: jstest exited cleanly at the -t deadline")
    finally:
        q.kill()
        q.wait()

    with open(a.log, "rb") as f:
        text = f.read().decode("utf-8", "replace")
    if re.search(r"kpanic|kernel panic|unhandled trap|illegal instruction|\[ERR\] trap", text):
        print("[-] FAIL: kernel reported a trap/panic during the run")
        sys.exit(1)
    print("[+] no traps or panics")


main()
