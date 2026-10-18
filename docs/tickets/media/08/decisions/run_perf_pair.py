from pathlib import Path
from types import SimpleNamespace
import json
import statistics
import sys

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / 'tools'))
import prove_ads as proof

HERE = Path(__file__).resolve().parent
args = SimpleNamespace(project=ROOT / '.worktrees/silo9-issue-08', baseline=HERE / 'baseline', godot=ROOT / '.tools/Godot_v4.7.2-stable_linux.x86_64', output=HERE / 'performance-final')
step = sys.argv[1]
if step == 'prepare':
    args.output.mkdir(exist_ok=False)
    args.campaign = proof.freeze_campaign([args.baseline, args.project], args.godot, args.project)
    proof.write_json(args.output / 'campaign.json', args.campaign)
    for index, project in enumerate([args.baseline, args.project], 1):
        proof.prepare(args, project, args.output / f'prepare-{index}')
else:
    args.campaign = json.loads((args.output / 'campaign.json').read_text())
    proof.verify_campaign(args)
    rows_path = args.output / 'runs.json'
    rows = json.loads(rows_path.read_text()) if rows_path.exists() else []
    if step == 'summarize':
        assert len(rows) == 10
        variants = ['baseline', 'candidate']
        keys = ['scenario', 'accepted_shots', 'target_damage', 'renderer', 'godot', 'display_driver', 'rendering_method', 'rendering_driver', 'resolution', 'normal_quality']
        assert len({tuple(row[key] for key in keys) for row in rows}) == 1
        metrics = ['frame_p50_ms', 'frame_p95_ms', 'draw_calls_max', 'nodes_max', 'resources_max']
        summary = {label: {key: {'median': statistics.median(values), 'min': min(values), 'max': max(values)} for key in metrics for values in [[r[key] for r in rows if r['label'] == label]]} for label in variants}
        proof.write_json(args.output / 'performance.json', {'campaign': args.campaign, 'runs': rows, 'summary': summary, 'verdict': 'pending independent review', 'limits': 'Same ADS/FOV on both revisions. Source launches under Linux llvmpipe, not production GPU measurements. Five pairs launched in separate foreground commands; original interrupted campaign excluded.'})
        print(json.dumps(summary), flush=True)
    else:
        pair = int(step)
        assert pair in range(1, 6) and len(rows) == (pair - 1) * 2
        variants = [('baseline', args.baseline, False), ('candidate', args.project, True)]
        for label, project, candidate in (variants if pair % 2 else list(reversed(variants))):
            result = proof.invoke(args, project, args.output / f'perf-{pair}-{label}', 'perf', candidate)
            result.update(pair=pair, label=label)
            rows.append(result)
            proof.write_json(rows_path, rows)
            print(label, pair, result['frame_p50_ms'], result['frame_p95_ms'], flush=True)
        proof.verify_campaign(args)
