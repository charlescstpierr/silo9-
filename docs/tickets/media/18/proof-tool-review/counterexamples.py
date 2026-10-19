"""Synthetic mutations; never execution evidence for the game."""
import copy
import importlib.util
import json
from pathlib import Path
import sys

snapshot = Path(sys.argv[1]).resolve()
sys.path.insert(0, str(snapshot))
from selfcheck_sector_power import persistence_fixture, terminal_fixture
from prove_sector_power import validate_result

results = []
for make in (persistence_fixture, terminal_fixture):
    errors = validate_result(make(), 0, '')
    if errors: raise RuntimeError('Synthetic baseline invalid: '+repr(errors))
def case(name, make, mutate):
    report = make()
    mutate(report)
    errors = validate_result(report, 0, '')
    results.append({'case': name, 'accepted': not errors, 'errors': errors})

case('ARC repetition before reconstruction', persistence_fixture,
     lambda r: r['persistence']['arc_repeat']['shot'].__setitem__('usec', 300))

def move_shot(r):
    shot = r['persistence']['actions'][0]['shot']
    for k in ('impact', 'ray_from', 'ray_to', 'target_position'):
        shot[k][0] += 100
case('crate action hits unrelated distant collider', persistence_fixture, move_shot)
case('restored image from unrelated camera pose', persistence_fixture,
     lambda r: r['persistence']['images'][-1].__setitem__('camera_position', [9000, 9000, 9000]))
case('ARC action and repeat share same target instance across new World', persistence_fixture,
     lambda r: r['persistence']['arc_repeat']['shot'].__setitem__('target_before', r['persistence']['actions'][2]['shot']['target_before']))
case('frame timestamps disagree with intervals', terminal_fixture,
     lambda r: [s.__setitem__('usec', 1) for s in r['perf_flashlight_samples']])
case('injected unknown proof top-level field', persistence_fixture,
     lambda r: r.__setitem__('invented', True))
case('health bool instead of number', persistence_fixture, lambda r: r.__setitem__('health', True))
def wrong_snapshot_types(r):
    for key in ('saved', 'restored'): r['persistence']['save_load'][key]['health'] = True
case('snapshot health bool instead of number', persistence_fixture, wrong_snapshot_types)
print(json.dumps(results, indent=2))
