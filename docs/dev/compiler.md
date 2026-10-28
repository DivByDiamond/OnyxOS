# Compiler included in system images

Both QEMU and OC2R images install the compiler at `/bin/onyxcc`. Packaging
rebuilds this RISC-V executable with the host OnyxCC compiler and validates
its ONX header and root execution flag before adding it to the image.

The C library is linked from source at compile time. Its headers and sources
are installed under `/usr/onyxc/lib/include` and `/usr/onyxc/lib/src`.
The compiler's default library directory is `/usr/onyxc/lib`.
Compiler documentation and the GPL-3.0 license are in `/usr/share/doc/onyxcc`.
Lua's separate MIT license is installed with Lua in `/usr/share/doc/lua`.

Whole-library compilation inside the guest remains experimental. This command
was attempted in QEMU with 256 MiB RAM:

```sh
onyxcc -o /tmp/hello.onx /usr/share/onyxcc/hello.c
/tmp/hello.onx
```

The compilation did not complete during an observation of more than six
minutes; the last progress message was preprocessing `locale.c`. The test
was then stopped, so this recipe has not been accepted as a working guest
compilation check. It includes the C library automatically. Use `-N` for
freestanding sources that provide their own entry point and system calls.
Host emulator checks validate that freestanding path. Lua and luac passed
their QEMU runtime checks at 64 MiB, and the full boot and interactive shell
smoke checks passed; these results do not establish whole-library compiler
support inside the guest.

OnyxCC implements a growing C subset. The payload includes no complete C++
frontend or C++ standard library; source extensions do not establish language
support. Consult the packaged `STATUS.md` for current limitations.

Host verification executes the compiler built by OnyxCC under `onx-run`,
compiles a small freestanding program, then executes that program. It also
checks input errors, include/output options, heap reuse and file modes:

```sh
cd OnyxCompiller
python3 tests/selfhost/run.py
```

This verifies a running compiler, rather than a full second-generation
self-compilation. Compilation memory depends on the source and included
headers; compiling applications with the whole C library on a 64 MiB OC2R
machine is not established by these checks. Installing the compiler in an
image does not establish that every program can be built within that limit.
