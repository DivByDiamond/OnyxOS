#!/usr/bin/env python3
"""Check installed Lua, luac and OnyxCC in a disposable QEMU disk overlay.

Requires pexpect. Build with ONYX_DEPS_MODE=workspace scripts/build-all.sh.
The base disk is never written by this test. Use --skip-compiler for 64M Lua QA.
"""
import argparse
from pathlib import Path
import pexpect


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--memory", default="256M")
    parser.add_argument("--skip-compiler", action="store_true")
    parser.add_argument("--compile-timeout", type=int, default=600)
    parser.add_argument("--log", type=Path)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    logfile = args.log or root / ".build/reports" / f"lua-qemu-{args.memory}.log"
    logfile.parent.mkdir(parents=True, exist_ok=True)
    command = ["-machine", "virt", "-m", args.memory, "-nographic", "-bios",
               str(root / ".build/onyx-boot.bin"), "-drive",
               f"file={root}/.build/onyx-boot-disk.img,format=raw,if=none,id=drive0,snapshot=on",
               "-device", "virtio-blk-device,drive=drive0"]
    with logfile.open("w") as stream:
        child = pexpect.spawn("qemu-system-riscv64", command, encoding="utf-8",
                              codec_errors="replace", timeout=90)
        child.logfile = stream
        try:
            child.expect("login:")
            child.sendline("root")
            prompt = child.expect(["password:", "Password:", r"osh\$"])
            if prompt < 2:
                child.sendline("")
                child.expect(r"osh\$")

            def run(line, expected, timeout=90):
                child.sendline(line)
                child.expect(r"osh\$", timeout=timeout)
                output = child.before
                if "page fault" in output or "illegal instruction" in output:
                    raise AssertionError(output[-3000:])
                for marker in expected:
                    if marker not in output:
                        raise AssertionError(f"{line}: missing {marker}\n{output[-4000:]}")
                return output

            run("lua -v", ["Lua 5.5.1", "exited code=0"])
            run("lua -e 'print(\"LUA_QEMU_EXPRESSION_OK\", 6*7)'",
                ["LUA_QEMU_EXPRESSION_OK\t42", "exited code=0"])
            output = run("lua /usr/share/lua/5.5/selftest.lua", ["SMOKE-END", "exited code=0"])
            assert output.count("PASS ") == 10, output
            run("luac -o /tmp/selftest.luac /usr/share/lua/5.5/selftest.lua", ["exited code=0"])
            output = run("lua /tmp/selftest.luac", ["SMOKE-END", "exited code=0"])
            assert output.count("PASS ") == 10, output
            run("lua -e 'assert(os.execute(\"echo LUA_SYSTEM_QEMU_OK\"))'",
                ["LUA_SYSTEM_QEMU_OK", "exited code=0"])
            child.sendline("lua")
            child.expect("Lua 5.5.1")
            child.expect(r"> ")
            child.sendline('print("LUA_REPL_OK", 42)')
            child.expect(r"LUA_REPL_OK[ \t]+42")
            child.expect(r"> ")
            child.sendline("os.exit()")
            child.expect(r"osh\$")
            if not args.skip_compiler:
                run("onyxcc --help", ["Usage: onyxcc", "exited code=0"])
                run("onyxcc -v -o /tmp/hello.onx /usr/share/onyxcc/hello.c", ["exited code=0"], args.compile_timeout)
                run("/tmp/hello.onx", ["Hello from OnyxCC!", "exited code=0"])
            print(f"PASS QEMU {args.memory}: Lua CLI, 10 runtime groups, luac, system, REPL"
                  + (" and on-system C compilation" if not args.skip_compiler else ""))
            print(f"Log: {logfile}")
        finally:
            child.sendcontrol("a")
            child.send("x")
            child.close(force=True)


if __name__ == "__main__":
    main()
