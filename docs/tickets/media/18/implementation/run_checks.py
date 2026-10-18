from pathlib import Path
import subprocess, json, time, hashlib, re, os
ROOT = Path(__file__).resolve().parents[5]
WT = ROOT / '.worktrees/silo9-issue-18'
OUT = Path(__file__).resolve().parent
GODOT = ROOT / '.tools/Godot_v4.7.2-stable_linux.x86_64'
rows = []
for name in ['persistence_state', 'world_persistence', 'state', 'world', 'sector_power_state', 'sector_power_commands', 'sector_power_effects', 'sector_power_dialogue', 'journey', 'd9_modal_save', 'shot_casings']:
    native = name == 'shot_casings'
    command = [str(GODOT)] + (['--audio-driver', 'Dummy'] if native else ['--headless']) + ['--path', str(WT), '--script', f'tests/test_{name}.gd']
    environment = os.environ.copy()
    if native: environment.update(DISPLAY=':100', LIBGL_ALWAYS_SOFTWARE='1')
    start = time.monotonic()
    try:
        result = subprocess.run(command, env=environment, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=180)
        output, code = result.stdout.decode(), result.returncode
    except subprocess.TimeoutExpired as error:
        output, code = (error.stdout or b'').decode(), 124
    (OUT / f'{name}.log').write_text(output)
    row = dict(test=name, command=command, exit=code, seconds=time.monotonic()-start,
        test_sha256=hashlib.sha256((WT/f'tests/test_{name}.gd').read_bytes()).hexdigest(),
        errors=re.findall(r'^(?:SCRIPT ERROR|ERROR|FAIL):.*', output, re.M),
        warnings=re.findall(r'^WARNING:.*', output, re.M),
        tail=output.splitlines()[-8:])
    rows.append(row)
    (OUT/'checks.json').write_text(json.dumps(rows, indent=2)+'\n')
    print(json.dumps(row), flush=True)
    if code != 0 or row['errors']: break
