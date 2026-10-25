#!/usr/bin/env bash
# Cap the memory a build may use so a runaway rustc/LLVM (or a `make -j`
# storm) cannot take the whole machine down: the kernel OOM killer would
# otherwise pick whatever it likes, including the desktop session.
#
# Usage:  source scripts/mem-limit.sh
#         onyx_limit_build_memory "$0" "$@"
#
# Env:    ONYX_BUILD_MEM_LIMIT   limit, default 6G; 0/off disables the cap.
#
# Strategy: prefer a cgroup v2 memory cap via `systemd-run --user --scope`
# (real RSS accounting per build tree, exactly the value requested). The
# scope re-executes the calling script once, guarded by ONYX_MEM_LIMIT_APPLIED.
# Where user systemd is unavailable (containers, CI), fall back to `ulimit -v`,
# which caps per-process address space in KiB.

onyx_limit_build_memory() {
    local limit="${ONYX_BUILD_MEM_LIMIT:-6G}"
    case "$limit" in
        0 | off | no | disabled) return 0 ;;
    esac
    if [ "${ONYX_MEM_LIMIT_APPLIED:-}" = "1" ]; then
        return 0
    fi
    if [ "$#" -eq 0 ]; then
        return 0
    fi

    if command -v systemd-run >/dev/null 2>&1; then
        if systemd-run --user --scope -q -p "MemoryMax=$limit" true >/dev/null 2>&1; then
            export ONYX_MEM_LIMIT_APPLIED=1
            echo "[mem] cgroup cap ${limit} (systemd --user scope)"
            exec systemd-run --user --scope -q -p "MemoryMax=$limit" -- "$@"
        fi
    fi

    local kib
    case "$limit" in
        *[Gg]) kib=$((${limit%[Gg]} * 1024 * 1024)) ;;
        *[Mm]) kib=$((${limit%[Mm]} * 1024)) ;;
        *[Kk]) kib=${limit%[Kk]} ;;
        *) kib=$limit ;;
    esac
    if [ "$kib" -gt 0 ] && ulimit -v "$kib" 2>/dev/null; then
        export ONYX_MEM_LIMIT_APPLIED=1
        echo "[mem] address-space cap ${limit} per process (ulimit -v)"
    else
        echo "[mem] WARNING: could not apply the ${limit} memory cap" >&2
    fi
}
