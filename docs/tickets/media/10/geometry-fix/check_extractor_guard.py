import hashlib
import json
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parents[1]
workspace = root.parents[3]
project = workspace / '.worktrees/silo9-issue-09'
engine = workspace / '.worktrees/silo9-issue-10/.tools/Godot_v4.7.2-stable_linux.x86_64'
out = root / 'geometry-fix/runtime/guard-checks'
out.mkdir(parents=True, exist_ok=False)
results = []
for scenario, injection in (
    ('missing-segment', '\tdata["segments"].pop_back()\n'),
    ('renamed-volume', '\tdata["volumes"][0]["name"] = "unexpected"\n'),
):
    for label, folder in (('initial', 'proof-tools-initial'), ('fixed', 'proof-tools')):
        source = root / folder / 'extract_world_geometry.gd'
        original = source.read_text()
        assert original.count('\tbuild_checks()\n') == 1
        script = out / (scenario + '-' + label + '.gd')
        script.write_text(original.replace('\tbuild_checks()\n', '\tbuild_checks()\n' + injection))
        output = script.with_suffix('.json')
        command = [str(engine), '--headless', '--path', str(project), '--script', str(script), '--', str(output)]
        paths = [engine, source, script] + sorted((project / 'scripts').rglob('*.gd'))
        def hashes():
            return {str(p): hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}
        before = hashes()
        with script.with_suffix('.log').open('w') as log:
            result = subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, timeout=60)
        after = hashes()
        item = {'scenario': scenario, 'label': label, 'command': command, 'exit_code': result.returncode,
                'output_exists': output.exists(), 'injection': injection, 'before': before, 'after': after}
        results.append(item)
        (out / 'results.json').write_text(json.dumps(results, indent=2))
        assert before == after
        assert result.returncode == (0 if label == 'initial' else 2)
        assert output.exists() == (label == 'initial')
        print(scenario, label, 'exit', result.returncode, 'output_exists', output.exists(), flush=True)
