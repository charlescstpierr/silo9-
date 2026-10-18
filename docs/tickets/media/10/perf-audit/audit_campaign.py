"""Read-only campaign audit. Runs no engine; writes only its audit JSON."""
import hashlib
import importlib.util
import json
import math
from pathlib import Path
import statistics
import sys

sys.dont_write_bytecode = True
TASK = Path(__file__).resolve().parents[1]
TOOLS = TASK / 'perf-proof-tools'
HEADS = {'baseline': '0297cf78827e180a10b16648cf7e411499f531d4', 'candidate': '64a948545d63764cb500f6ac1a02380c5d1513f3'}
FROZEN = {'probe': '0e0f03fd1eb922719bb4862f461b3a04355c83d22be28b5dffe24f7f803dda26', 'wrapper': '1493110c32ec4ff8907b1a203071832969c010f575dbfcfefb0b733ec3c90a2b', 'engine': '8d106cbe6144c2dc7e881d61d2429c1a8a76e6b22ef48bd5e48dcf934953f71e'}
WORLD_ART = 'c3a973b5774ba521a29deff13dd9234db260c5e0329a0ecfc20da3d53b866cf0'
spec = importlib.util.spec_from_file_location('proof', TOOLS / 'prove_sector_power.py')
proof = importlib.util.module_from_spec(spec)
spec.loader.exec_module(proof)


def quantile(values, fraction):
    return sorted(values)[min(int(len(values) * fraction), len(values) - 1)]


def distribution(values):
    return {'median': statistics.median(values), 'min': min(values), 'max': max(values), 'values': values}


def audit():
    failures, rows, sources, pair_windows = [], [], {}, []
    def check(ok, label):
        if not ok:
            failures.append(label)
    root = TASK / 'perf'
    expected = {f'{quality}-{lamp}-{index}-{side}' for quality in ['normal', 'low'] for lamp in ['off', 'on'] for index in range(1, 6) for side in HEADS}
    actual = {p.parent.name for p in root.glob('*/journey.json')}
    check(actual == expected, 'exact 40-run delivery inventory')
    for quality in ['normal', 'low']:
        for lamp in ['off', 'on']:
            group = f'{quality}-{lamp}'
            for index in range(1, 6):
                pair = json.loads((root / f'{group}-{index}-pair.json').read_text())
                expected_order = ['baseline', 'candidate'] if index % 2 else ['candidate', 'baseline']
                check([x['side'] for x in pair] == expected_order, f'{group}-{index}: alternating pair order')
                check(pair[0]['end'] <= pair[1]['start'], f'{group}-{index}: serialized members')
                pair_windows.append({'pair': f'{group}-{index}', 'start': pair[0]['start'], 'end': pair[-1]['end']})
                for side in HEADS:
                    name = f'{group}-{index}-{side}'
                    folder = root / name
                    manifest = json.loads((folder / 'manifest.json').read_text())
                    report = json.loads((folder / 'journey.json').read_text())
                    log = (folder / 'engine.log').read_text()
                    pair_row = next(x for x in pair if x['side'] == side)
                    errors = proof.validate_result(report, manifest['exit_code'], log, flashlight_requested=lamp == 'on')
                    check(not errors, f'{name}: validator {errors}')
                    check(pair_row['exit_code'] == 0 and manifest['exit_code'] == 0 and not manifest['validation_errors'], f'{name}: successful engine and wrapper')
                    check(pair_row['start'] <= manifest['started_unix'] < manifest['ended_unix'] <= pair_row['end'], f'{name}: execution window enclosure')
                    check(manifest['head'] == HEADS[side], f'{name}: expected HEAD')
                    check(manifest['artifacts_before'] == manifest['artifacts_after'] == FROZEN, f'{name}: frozen artifacts')
                    check(manifest['source_before'] == manifest['source_after'] and manifest['source_unchanged'], f'{name}: unchanged full source')
                    if side in sources:
                        check(sources[side] == manifest['source_before'], f'{name}: same full source between runs')
                    else:
                        sources[side] = manifest['source_before']
                    if side == 'candidate':
                        check(manifest['source_before']['scripts/world_art.gd'] == WORLD_ART, f'{name}: world_art c3')
                    check(manifest['flashlight_requested'] is (lamp == 'on') and ('--flashlight-on' in manifest['command']) == (lamp == 'on'), f'{name}: independent command request')
                    check(report['low_quality'] is (quality == 'low') and ('--low' in manifest['command']) == (quality == 'low'), f'{name}: quality request')
                    check(all(flag in manifest['command'] for flag in ['--require-lighting', '--require-circuits', '--probe-mode=perf']), f'{name}: scenario flags')
                    check('llvmpipe' in report['renderer'].lower(), f'{name}: software renderer declared')
                    check(abs(report['travelled_m'] - 92.4334392547607) < 0.001, f'{name}: same physical distance')
                    final = report['final_observation']
                    check(abs(final['scale_3d'] - (0.67 if quality == 'low' else 1.0)) < 1e-5, f'{name}: actual quality scale')
                    check(final['fov'] == 76 and final['circuits'] == {'maintenance': True, 'archives': True}, f'{name}: fov and circuits')
                    check(len(final['lights']) == 9 and not any(x['shadow'] for x in final['lights']), f'{name}: fixed lights shadow budget')
                    samples = report['perf_flashlight_samples']
                    ticks = [x['usec'] for x in samples]
                    intervals = report['frame_intervals_ms']
                    check(all(type(x) is int and x > 0 for x in ticks), f'{name}: integer monotonic ticks')
                    check(all(abs((b - a) / 1000 - d) < 1e-8 for a, b, d in zip(ticks, ticks[1:], intervals)), f'{name}: raw ticks reconstruct every interval')
                    check([x['stage'] for x in samples[1:]] == report['frame_stages'], f'{name}: raw stages match')
                    check(report['perf_flashlight_before_warmup']['usec'] < ticks[0] < ticks[-1] <= final['usec'], f'{name}: before/during/after order')
                    check(len({tuple(x['flashlight']['position']) for x in samples if x['flashlight']}) > 9, f'{name}: physical flashlight moves')
                    q = {f'p{int(f * 100)}': quantile(intervals, f) for f in [.5, .95, .99]}
                    for key, value in q.items():
                        check(abs(value - report[f'frame_{key}_ms']) < 1e-8, f'{name}: independent {key}')
                    rows.append({'name': name, 'group': group, 'pair': index, 'side': side, **q, 'intervals': len(intervals), 'frames_drawn': report['frames_drawn'], 'interval_sum_ms': math.fsum(intervals), 'warmup_to_first_callback_ms': (ticks[0] - report['perf_flashlight_before_warmup']['usec']) / 1000, 'distance_m': report['travelled_m'], 'draw_calls_max': report['draw_calls_max'], 'nodes_max': report['nodes_max'], 'resources_max': report['resources_max'], 'started_unix': manifest['started_unix'], 'ended_unix': manifest['ended_unix']})
    pair_windows.sort(key=lambda x: x['start'])
    check(all(a['end'] <= b['start'] for a, b in zip(pair_windows, pair_windows[1:])), 'all pairs globally serialized')
    groups = {}
    for group in sorted({r['group'] for r in rows}):
        member = [r for r in rows if r['group'] == group]
        output = {side: {metric: distribution([r[metric] for r in member if r['side'] == side]) for metric in ['p50', 'p95', 'p99', 'draw_calls_max', 'nodes_max', 'resources_max']} for side in HEADS}
        output['paired_candidate_minus_baseline'] = {}
        for metric in ['p50', 'p95', 'p99']:
            differences, percentages = [], []
            for index in range(1, 6):
                pair = {r['side']: r for r in member if r['pair'] == index}
                difference = pair['candidate'][metric] - pair['baseline'][metric]
                differences.append(difference)
                percentages.append(100 * difference / pair['baseline'][metric])
            output['paired_candidate_minus_baseline'][metric] = {'ms': distribution(differences), 'percent': distribution(percentages)}
        groups[group] = output
    result = {'passed': not failures, 'failures': failures, 'runs': rows, 'groups': groups, 'pair_windows': pair_windows, 'source_file_counts': {k: len(v) for k, v in sources.items()}, 'excluded': ['perf-tool-diagnostic', 'selfchecks', 'ticket09 performance numbers', 'capture and mission timings'], 'quantile_rule': 'sorted[floor(n*p)], capped at n-1, per run; then median and range across five runs', 'limits': ['No engine or benchmark run by this audit', 'Serialization inferred from pair and manifest timestamps; external concurrency requires separate host evidence', 'Linux llvmpipe callback wall-clock, not GPU time', 'No target GPU, Windows, 1080p or 60 FPS validation', 'No paired ON/OFF claim across separate groups', 'Ticket09 CPU profile does not attribute a ticket10 change']}
    (TASK / 'perf-audit' / 'campaign-audit.json').write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps({'passed': result['passed'], 'failures': failures, 'runs': len(rows), 'groups': groups}, indent=2))
    return not result['passed']


if __name__ == '__main__':
    raise SystemExit(audit())
