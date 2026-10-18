# Held menu button correction

Escape now resumes gameplay when the settings button is held. Its later release leaves gameplay active. The same normal GUI click still opens usable settings.

- Worktree: `/home/ubuntu/Documents/Codex/2026-10-17/prompt-ma-tre-pour-astra-pro/.worktrees/silo9-issue-06`.
- Branch: `feat/issue-06-shot-feedback`.
- Tests-only base: `9e2cf819e8d1fff26a452e95affaa1f92e162401`.
- Fix commit: `5fd906f97c3e6635ad7767d9a29b4c838429e072`.
- Changed production: `scripts/main.gd::_button`, four added lines replacing the direct signal connection.

The pressed callback now invokes its action only while the source button is visible in the scene tree. The existing Button is the source of truth; no extra menu state or module was added. The parent-approved red gate and trace establish the hidden ancestor case that requires this check. The callback stays synchronous for valid clicks.

## Verification

`commands.json` records exact commands, environment, log files, exit codes, and test hashes. All tests use Godot 4.7.2 official ed1daf0bf on DISPLAY=:100 with dummy rendering and audio.

| Run | Result |
|---|---|
| test_menu_held_button.gd | 10 assertions pass, exit 0 |
| test_ui.gd | 0 failures, exit 0 |
| test_shot_settings.gd | 0 failures, exit 0 |
| test_weapon_modal_input.gd | all assertions pass, exit 0 |
| test_arc_cell_ui.gd | 0 failures, exit 0 |
| test_menu_held_button.gd after deslop | 10 assertions pass, exit 0 |

No run reports a busy error, engine error, parse error, script error, or failed assertion. `git diff --check` passed. `tracked-hashes.json` compares every tracked file with the tests-only commit. Only main.gd changed; all tests are byte-identical. The regression SHA256 remains `615d5ab502053e3ec1f14ef369cae64fdfb88f48055ae9b602542e08310c8d7c`.

## Deslop

The sole changed hunk was read completely. The connection wrapper, visibility condition, call, and closing delimiter are all necessary for the measured behavior.

| category | file:line | removed | reason |
|---|---|---|---|
| none | scripts/main.gd:243 | none | Every added line carries the visibility policy. |

No uncertain lines, untested removals, or additional follow-ups remain. The same regression test passed again after this review.

## Handoff

Only main.gd was staged and committed. Parent-owned untracked probes and UID artifacts remain untouched. No descendants, push, PR, source changes beyond _button, or test changes were made. The parent still owns independent review and the exact native XTest replay; this result does not claim that replay or all 33 suites.

Worktree and DISPLAY=:100 are released to the parent. All test processes launched here have completed. Parent Xvfb PID 2472984 remains running.
