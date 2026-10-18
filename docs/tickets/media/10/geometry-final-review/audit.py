"""Bounded evidence audit: no engine, benchmark or full intersection rescan."""
import ast
import hashlib
import json
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root / 'proof-tools'))
import geometry_check as geometry

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def read(path):
    return json.loads(path.read_text())

verification = read(root / 'geometry-fix/verification.json')
for folder in ('proof-tools', 'proof-tools-initial'):
    for name, expected in verification[folder].items():
        assert sha(root / folder / name) == expected
trees = [ast.parse((root / folder / 'geometry_check.py').read_text())
         for folder in ('proof-tools-initial', 'proof-tools')]
functions = [{node.name: ast.dump(node, include_attributes=False)
              for node in tree.body if isinstance(node, ast.FunctionDef)} for tree in trees]
assert all(functions[0][name] == functions[1][name] for name in verification['unchanged_math_functions'])

runtime = root / 'geometry-fix/runtime/attempt-01'
captures = {}
summary = {'tool_and_archive_hashes': 'PASS', 'eight_math_functions_ast_identical': True, 'captures': {}}
for label in ('base', 'candidate'):
    manifest = read(runtime / (label + '.manifest.json'))
    assert manifest['exit_code'] == 0 and manifest['before'] == manifest['after']
    assert sha(runtime / (label + '.json')) == manifest['output_sha256']
    snapshot = manifest['before']
    assert snapshot['tools'] == verification['proof-tools']
    project = Path(manifest['command'][manifest['command'].index('--path') + 1])
    assert len(snapshot['sources']) == 84
    assert all(sha(project / name) == digest for name, digest in snapshot['sources'].items())
    capture = captures[label] = read(runtime / (label + '.json'))
    geometry.validate(capture)
    assert Path(capture['project']) == project
    assert all(snapshot['sources'][name] == digest for name, digest in capture['source_sha256'].items())
    assert set(capture['stats']) == {'decor', 'static', 'actor', 'animated'}
    assert len(capture['colliders']) == 76
    summary['captures'][label] = {'exit_code_recorded': 0, 'source_files_currently_matching': 84,
                                'dump_sha256': manifest['output_sha256'],
                                'stats': capture['stats'], 'collider_count': 76}

report = read(runtime / 'comparison.json')
assert read(runtime / 'comparison-command.json')['exit_code'] == 0
assert report['bounded_pass'] is True
assert captures['base']['segments'] == captures['candidate']['segments']
assert captures['base']['volumes'] == captures['candidate']['volumes']
expected_checks = {'segment:' + name for name in geometry.SEGMENT_IDS} | {'volume:' + name for name in geometry.VOLUME_IDS}
assert set(report['checks']) == expected_checks
for label, stats_key, hash_key in [('base', 'stats_before', 'before_sha256'), ('candidate', 'stats_after', 'after_sha256')]:
    assert report[stats_key] == captures[label]['stats']
    assert geometry.collider_fingerprint(captures[label]['colliders'])[0] == report['colliders'][hash_key]
assert report['colliders']['equal'] and not report['colliders']['added'] and not report['colliders']['removed']
assert report['colliders']['before_sha256'] == report['colliders']['after_sha256']
totals = dict.fromkeys(('preexisting', 'remaining', 'removed', 'added'), 0)
for name, check in report['checks'].items():
    for category in totals:
        totals[category] += len(check[category])
    assert [geometry.triangle_key(hit['triangle']) for hit in check['preexisting']] == [geometry.triangle_key(hit['triangle']) for hit in check['remaining']]
    assert not check['added'] and not check['removed']
    assert len(check['preexisting']) == (40 if name.startswith('volume:door_sweep_') else 0)
    if not check['preexisting']:
        continue
    for label in captures:
        capture = captures[label]
        hits = check['preexisting' if label == 'base' else 'remaining']
        reserve = next(v for v in capture['volumes'] if 'volume:' + v['name'] == name)
        paths = {path for hit in hits for path in hit['meshes']}
        triangles = {m['path']: {geometry.triangle_key(t) for t in m['triangles']}
                     for m in capture['meshes'] if m['path'] in paths}
        for hit in hits:
            assert geometry.triangle_box(hit['triangle'], reserve['min'], reserve['max'])
            assert all(geometry.triangle_key(hit['triangle']) in triangles[path] for path in hit['meshes'])
assert totals == {'preexisting': 160, 'remaining': 160, 'removed': 0, 'added': 0}
summary['recorded_comparison'] = {'check_count': len(report['checks']), 'totals': totals,
                                  'collider_sha256': report['colliders']['before_sha256'],
                                  'reported_hits_checked_against_both_dumps': True,
                                  'full_intersection_scan_repeated': False}

guards = []
for item in read(root / 'geometry-fix/runtime/guard-checks/results.json'):
    fixed = item['label'] == 'fixed'
    assert item['exit_code'] == (2 if fixed else 0)
    assert item['output_exists'] == (not fixed)
    assert Path(item['command'][-1]).exists() == (not fixed)
    assert item['before'] == item['after']
    source = root / ('proof-tools' if fixed else 'proof-tools-initial') / 'extract_world_geometry.gd'
    injected = Path(item['command'][item['command'].index('--script') + 1])
    assert injected.read_text() == source.read_text().replace('\tbuild_checks()\n', '\tbuild_checks()\n' + item['injection'])
    assert sha(injected) == item['before'][str(injected)]
    guards.append({'scenario': item['scenario'], 'label': item['label'], 'exit_code_recorded': item['exit_code'],
                   'output_exists': item['output_exists'], 'injected_copy_matches': True})
summary['guard_runs_after_implementation'] = guards
print(json.dumps(summary, indent=2))
