import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time

root = Path(__file__).resolve().parents[1]
workspace = root.parents[3]
out = root / 'geometry-fix/runtime' / sys.argv[1]
out.mkdir(parents=True, exist_ok=False)
engine = workspace / '.worktrees/silo9-issue-10/.tools/Godot_v4.7.2-stable_linux.x86_64'
tools = [root / 'proof-tools' / name for name in ('geometry_check.py', 'test_geometry_check.py', 'extract_world_geometry.gd')]

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def identity(project):
    source_paths = sorted(set(p for folder in ('scripts', 'tests', 'tools') for p in (project / folder).rglob('*.gd')))
    source_paths.append(project / 'project.godot')
    return {'engine': {'path': str(engine), 'sha256': digest(engine)},
            'tools': {p.name: digest(p) for p in tools},
            'sources': {str(p.relative_to(project)): digest(p) for p in source_paths}}

results = []
for label, issue in (('base', '09'), ('candidate', '10')):
    project = workspace / ('.worktrees/silo9-issue-' + issue)
    output = out / (label + '.json')
    command = [str(engine), '--headless', '--path', str(project), '--script', str(tools[2]), '--', str(output)]
    item = {'label': label, 'command': command, 'cwd': str(workspace), 'before': identity(project)}
    (out / (label + '.manifest.json')).write_text(json.dumps(item, indent=2))
    started = time.time()
    with (out / (label + '.log')).open('w') as log:
        result = subprocess.run(command, cwd=workspace, stdout=log, stderr=subprocess.STDOUT, timeout=120)
    item.update(exit_code=result.returncode, elapsed_seconds=time.time()-started, after=identity(project))
    item['unchanged'] = item['before'] == item['after']
    item['output_sha256'] = digest(output) if output.exists() else None
    (out / (label + '.manifest.json')).write_text(json.dumps(item, indent=2))
    results.append(item)
    print(label, 'exit', item['exit_code'], 'unchanged', item['unchanged'], 'output', item['output_sha256'], flush=True)
if all(item['exit_code'] == 0 and item['output_sha256'] for item in results):
    command = [sys.executable, str(tools[0]), str(out / 'base.json'), str(out / 'candidate.json'), str(out / 'comparison.json')]
    result = subprocess.run(command, cwd=workspace, text=True, capture_output=True, timeout=120)
    (out / 'comparison.log').write_text(result.stdout + result.stderr)
    (out / 'comparison-command.json').write_text(json.dumps({'command': command, 'exit_code': result.returncode}, indent=2))
    print('comparison exit', result.returncode, flush=True)
else:
    print('comparison skipped: extraction did not succeed', flush=True)
