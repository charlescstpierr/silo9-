"""Alternate baseline/current release benchmarks; retain every raw run and median/range."""
import argparse
import json
import os
from pathlib import Path
import statistics
import subprocess
import sys


def summarize(values):
    return {'median': statistics.median(values), 'range': [min(values), max(values)]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project', type=Path, required=True)
    parser.add_argument('--baseline-project', type=Path, required=True)
    parser.add_argument('--binary', type=Path, required=True)
    parser.add_argument('--baseline-binary', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--runs', type=int, default=5)
    args = parser.parse_args()
    if not 1 <= args.runs <= 20:
        parser.error('--runs must be between 1 and 20')
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    if any(output.iterdir()):
        parser.error('--output must be empty')
    environment = {'cpu_count': os.cpu_count(), 'load_average_start': os.getloadavg()}
    records = []
    for run in range(1, args.runs + 1):
        for quality in ['normal', 'low']:
            for side in ['baseline', 'current']:
                project = args.baseline_project if side == 'baseline' else args.project
                binary = args.baseline_binary if side == 'baseline' else args.binary
                directory = output / f'{run:02d}-{quality}-{side}'
                command = [sys.executable, str(Path(__file__).with_name('prove_astra.py')),
                           '--project', str(project.resolve()), '--binary', str(binary.resolve()),
                           '--output', str(directory), '--mode', 'benchmark']
                if quality == 'low':
                    command.append('--low')
                subprocess.run(command, check=True)
                report = json.loads((directory / 'performance.json').read_text())
                report['source_sha256'] = json.loads((directory / 'provenance.json').read_text())['source_sha256']
                if report['quality'] != quality:
                    raise RuntimeError('Requested quality was not exercised')
                report.update({'run': run, 'side': side, 'directory': directory.name})
                records.append(report)
                (output / 'runs.json').write_text(json.dumps(records, indent=2))
    for side in ['baseline', 'current']:
        hashes = {(r['binary_sha256'], r.get('pack_sha256'), r['source_sha256']) for r in records if r['side'] == side}
        if len(hashes) != 1:
            raise RuntimeError(f'{side} source or executable changed during measurement')
    if len({(r['renderer'], r['rendering_method']) for r in records}) != 1:
        raise RuntimeError('Renderer changed during comparison')
    stations = []
    for quality in ['normal', 'low']:
        for index in range(4):
            item = {'quality': quality, 'sector': records[0]['samples'][index]['sector']}
            for side in ['baseline', 'current']:
                group = [r for r in records if r['quality'] == quality and r['side'] == side]
                if any(r['samples'][index]['sector'] != item['sector'] for r in group):
                    raise RuntimeError('Station identities changed during comparison')
                item[side] = {metric: summarize([r['samples'][index][metric] for r in group])
                              for metric in ['p50_ms', 'p95_ms', 'draw_calls', 'triangles']}
            stations.append(item)
    processes = {}
    for side in ['baseline', 'current']:
        for quality in ['normal', 'low']:
            group = [r['process'] for r in records if r['side'] == side and r['quality'] == quality]
            processes[f'{side}-{quality}'] = ({key: summarize([r[key] for r in group])
                for key in ['peak_rss_kib', 'elapsed_seconds', 'cpu_seconds']} if all(group) else None)
    environment['load_average_end'] = os.getloadavg()
    summary = {'runs_per_configuration': args.runs, 'failed_runs': 0, 'environment': environment,
               'renderer': records[0]['renderer'], 'rendering_method': records[0]['rendering_method'], 'resolution': [1920, 1080],
               'stations': stations, 'processes': processes, 'runs': records,
               'limits': ['Stationary scripted live scenes, not a human playthrough.',
                          'Peak RSS/CPU cover the complete process including startup.',
                          'Software rendering is not a Windows gaming GPU result.',
                          'No bottleneck diagnosis or significance verdict is inferred by this script.']}
    (output / 'summary.json').write_text(json.dumps(summary, indent=2))
    print(f'Verified {len(records)} runs: {output / "summary.json"}')


if __name__ == '__main__':
    main()
