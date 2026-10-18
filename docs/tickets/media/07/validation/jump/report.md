# Jump tap regression — tests only

Confirmed on Godot 4.7.2 stable ed1daf0bf, X11 :100, dummy rendering/audio.

- Baseline: imported scratch `../harness-collision/fix/baseline`, Player byte-identical to 2818e15a617760dcb98b93927eb563d7af05ba17. Same absolute test script: 10 passes, exit 0. Tap yields y velocity 7.0 and rise 0.1174935475m.
- Candidate: frozen builder source manifest `../implementation/pre-jump-source-manifest.json`, HEAD before test commit 0ad803050dee20d29b78899572aeb64c52c3c289. 8 passes, 2 semantic failures, exit 1. Tap yields velocity 0 and rise 0. No parse/runtime errors.
- Both prove capsule grounded before input, real Space press+release retained as just_pressed while released, normal held Space jumps, and airborne taps do not double jump.

The regression is caused by requiring `is_action_pressed("jump")` in addition to `is_action_just_pressed("jump")` in the candidate. No production edit was made here.

## Test timing

The first draft checked too early and failed on both versions; its logs are retained under `draft-timing/` and are not regression evidence. Godot input.cpp at ed1daf0bf records `pressed_physics_frame = current+1` (lines 1035 and 1419). The corrected test waits to that physics-frame signal before checking just_pressed, then observes velocity after the real Player physics step. Engine source snapshot retained in input.cpp.

## Files and verification

- Added `tests/test_jump_tap.gd`; SHA256 `c68b58e242598cd3d03c48f6c86309d8767992fd802d9a4aafbe9d054b63aa06`. Exact executed source copied to final-test.gd.
- Added its X11 route to tools/verify.sh, matching the existing Player input tests.
- bash -n tools/verify.sh and git diff --check pass.
- Deslop: full test/runner diff read, no speculative helpers or production changes; no removals needed. No rerun required after a code cleanup because no cleanup was made.
- Source verification: all manifest paths unchanged except the authorized tools/verify.sh test-routing edit. See production-verification.json.
- Commands and exit codes: commands.json; output: baseline.log, candidate.log.
- Test-only commit: 15cd4289bf5aeda3f1fa764765a7a8a290529a6b.
- Worktree: /home/ubuntu/Documents/Codex/2026-10-17/prompt-ma-tre-pour-astra-pro/.worktrees/silo9-issue-07; branch feat/issue-07-ads. Builder dirty files preserved, not staged.
- Runtime released: both launched Godot subprocesses exited; :100 Xvfb remains parent-owned. No descendants or background processes started.
