from pathlib import Path
import hashlib, json, os, re, subprocess, time

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[4]
WT = ROOT / '.worktrees/silo9-issue-18'
MANIFEST = OUT.parent / 'implementation/frozen-sources.json'
BINARY = ROOT / '.tools/Godot_v4.7.2-stable_linux.x86_64'

def hashes():
    expected = json.loads(MANIFEST.read_text())
    return {name: hashlib.sha256((WT / name).read_bytes()).hexdigest() for name in expected}

expected = json.loads(MANIFEST.read_text())
before = hashes()
assert before == expected, 'Frozen sources changed before review execution'
head = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=WT, text=True).strip()
assert head == '28e402821469655598c6a84bc415d8ea04da97c2'
env = os.environ.copy()
env.update(XDG_DATA_HOME=str(OUT/'userdata'), XDG_CONFIG_HOME=str(OUT/'config'), XDG_CACHE_HOME=str(OUT/'cache'))
rows = []
for name in ['persistence_state', 'world_persistence', 'remains_geometry']:
    command = [str(BINARY), '--headless', '--path', str(WT), '--script', f'tests/test_{name}.gd']
    started = time.monotonic()
    result = subprocess.run(command, cwd=WT, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=60, text=True)
    output = result.stdout
    (OUT/f'{name}.log').write_text(output)
    rows.append(dict(suite=name, command=command, exit=result.returncode, seconds=time.monotonic()-started,
                     passed=len(re.findall(r'^PASS:', output, re.M)), failed=len(re.findall(r'^FAIL:', output, re.M)),
                     errors=re.findall(r'^(?:ERROR|SCRIPT ERROR|FAIL):.*', output, re.M),
                     warnings=re.findall(r'^WARNING:.*', output, re.M),
                     summary=[line for line in output.splitlines() if re.match(r'^(PERSISTENCE STATE|WORLD PERSISTENCE|REMAINS GEOMETRY):',line)]))
    print(json.dumps(rows[-1]), flush=True)
    (OUT/'results.json').write_text(json.dumps(dict(head=head, environment={key:env[key] for key in ['XDG_DATA_HOME','XDG_CONFIG_HOME','XDG_CACHE_HOME']}, before=before, rows=rows, after=hashes()), indent=2)+'\n')
    assert result.returncode == 0 and not rows[-1]['errors'], name+' failed'
assert hashes() == before, 'Frozen sources changed during review execution'
