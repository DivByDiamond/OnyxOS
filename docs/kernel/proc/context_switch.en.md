# Context Switching

Save/restore callee-saved registers:
ra, sp, s0-s11.

## save_context

Writes registers to the Context structure.

## restore_context

Loads registers from Context and jumps via ra.

**Status**: `save_context()` / `restore_context()` are written, but not yet
called from `sched_yield()`. Real context switching will appear
in v0.3 (see roadmap and known_issues).
