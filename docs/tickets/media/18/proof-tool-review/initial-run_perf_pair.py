from pathlib import Path
import json
import subprocess
import sys
import time

root = Path(__file__).resolve().parents[4]
task = Path(__file__).resolve().parent
quality, index = sys.argv[1], int(sys.argv[2])
if quality not in ('normal', 'low') or not 1 <= index <= 5:
    raise SystemExit('Expected normal|low and pair index 1..5')
order = ['reference', 'candidate'] if index % 2 else ['candidate', 'reference']
rows = []
for side in order:
    project = root / '.worktrees' / ('silo9-issue-10' if side == 'reference' else 'silo9-issue-18')
    destination = task / 'perf' / f'{quality}-{index}-{side}'
    command = [
        'python3', str(task / 'proof-tools/prove_sector_power.py'),
        '--godot', str(root / '.tools/Godot_v4.7.2-stable_linux.x86_64'),
        '--project', str(project), '--mode', 'perf', '--output', str(destination),
        '--timeout', '120', '--require-circuits', '--require-lighting',
        '--flashlight-on', '--terminal-variant', side,
    ]
    if quality == 'low':
        command.append('--low')
    started = time.time()
    result = subprocess.run(command)
    rows.append(dict(side=side, start=started, end=time.time(), exit_code=result.returncode, command=command))
    if result.returncode:
        destination.parent.mkdir(parents=True, exist_ok=True)
        (destination.parent / f'{quality}-{index}-FAILED.json').write_text(json.dumps(rows, indent=2) + '\n')
        raise SystemExit(result.returncode)
(task / 'perf' / f'{quality}-{index}-pair.json').write_text(json.dumps(rows, indent=2) + '\n')
