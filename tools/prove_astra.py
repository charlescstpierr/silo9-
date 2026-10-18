"""Capture real Godot viewports; run performance separately from offline animation recording."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import signal
import struct
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--project', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--mode', choices=['scenes', 'demo', 'benchmark'], required=True)
    parser.add_argument('--low', action='store_true')
    parser.add_argument('--binary', type=Path, help='Absolute exported executable; benchmark mode only')
    parser.add_argument('--source-label', help='Human provenance for an archived source snapshot')
    parser.add_argument('--renderer', choices=['gl_compatibility', 'forward_plus'], default='gl_compatibility')
    args = parser.parse_args()
    if args.binary:
        if args.mode != 'benchmark':
            parser.error('--binary requires --mode benchmark')
        if not args.binary.is_absolute() or not args.binary.is_file() or not os.access(args.binary, os.X_OK):
            parser.error('--binary must be an absolute executable file')
        if args.renderer != 'gl_compatibility':
            parser.error('--binary uses its shipped renderer; omit --renderer')
    project, output = args.project.resolve(), args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    if any(output.iterdir()):
        parser.error('--output must be empty, so stale evidence cannot pass')
    if not os.environ.get('DISPLAY'):
        parser.error('DISPLAY required: these are rendered probes, not headless tests')
    sources = sorted(p for directory in ['scripts', 'assets', 'data', 'shaders', 'tools']
                     for p in (project / directory).rglob('*') if p.is_file()
                     and '.godot' not in p.parts and '__pycache__' not in p.parts
                     and p.suffix not in {'.pyc', '.uid'})
    sources += sorted(project.glob('*.tscn')) + [project / 'project.godot']
    digest = hashlib.sha256()
    for path in sources:
        digest.update(path.relative_to(project).as_posix().encode() + b'\0')
        digest.update(hashlib.sha256(path.read_bytes()).digest())
    git_root = subprocess.run(['git', 'rev-parse', '--show-toplevel'], cwd=project, capture_output=True, text=True)
    own_checkout = git_root.returncode == 0 and Path(git_root.stdout.strip()).resolve() == project
    provenance = {'source_label': args.source_label, 'source_sha256': digest.hexdigest(),
                  'source_file_count': len(sources), 'source_head': None, 'git_status': None,
                  'renderer_requested': None if args.binary else args.renderer, 'fixed_fps': None if args.mode == 'benchmark' else 30}
    if own_checkout:
        provenance['source_head'] = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=project, text=True).strip()
        provenance['git_status'] = subprocess.check_output(['git', 'status', '--short'], cwd=project, text=True)
    if args.binary:
        provenance['binary_sha256'] = hashlib.sha256(args.binary.read_bytes()).hexdigest()
        pack = args.binary.with_suffix('.pck')
        if pack.is_file():
            provenance['pack_sha256'] = hashlib.sha256(pack.read_bytes()).hexdigest()
    (output / 'provenance.json').write_text(json.dumps(provenance, indent=2))
    environment = {**os.environ, 'XDG_DATA_HOME': str(output / 'user-data')}
    engine = os.environ.get('GODOT_BIN', str(project / 'tools/godot.sh'))
    command = [engine, '--path', str(project), '--audio-driver', 'Dummy', '--rendering-method', args.renderer]
    if args.binary:
        command = [str(args.binary), '--audio-driver', 'Dummy', '--', '--benchmark']
    elif args.mode == 'benchmark':
        command += ['res://benchmark.tscn', '--']
    else:
        command += ['--fixed-fps', '30', '--script', 'res://tools/astra_probe.gd', '--',
                    '--proof-output=' + str(output), '--mode=' + args.mode]
    if args.low:
        command += ['--low']
    if args.mode == 'benchmark' and os.access('/usr/bin/time', os.X_OK):
        command = ['/usr/bin/time', '-f', '{"peak_rss_kib":%M,"elapsed_seconds":%e,"user_seconds":%U,"system_seconds":%S}',
                   '-o', str(output / 'process.json')] + command
        environment['LC_NUMERIC'] = 'C'
    (output / 'command.json').write_text(json.dumps(command, indent=2))
    with (output / 'engine.log').open('w') as log:
        result = subprocess.Popen(command, cwd=project, env=environment, stdout=log,
                                  stderr=subprocess.STDOUT, start_new_session=True)
        try:
            result.wait(timeout=600)
        except (subprocess.TimeoutExpired, KeyboardInterrupt):
            try:
                os.killpg(result.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            result.wait()
            raise
    log_text = (output / 'engine.log').read_text()
    if result.returncode or re.search(r'(?m)^\s*(ERROR:|SCRIPT ERROR:|FAIL:)', log_text):
        raise RuntimeError(f'Godot failed; inspect {output / "engine.log"}')
    if args.mode == 'benchmark':
        quality = 'low' if args.low else 'normal'
        reports = list((output / 'user-data').rglob(f'performance-{quality}.json'))
        if len(reports) != 1:
            raise RuntimeError('Expected one fresh performance report')
        report = json.loads(reports[0].read_text())
        method = re.search(r' - (Compatibility|Forward\+|Mobile) - ', log_text)
        if method is None:
            raise RuntimeError('Actual rendering method missing from Godot startup log')
        actual_method = {'Compatibility': 'gl_compatibility', 'Forward+': 'forward_plus', 'Mobile': 'mobile'}[method[1]]
        if report.get('rendering_method', actual_method) != actual_method:
            raise RuntimeError('Engine API and startup log disagree on rendering method')
        report['rendering_method'] = actual_method
        if report['resolution'] != [1920, 1080] or len(report['samples']) != 4:
            raise RuntimeError('Benchmark resolution/station count invalid')
        if any(s['frames'] < 20 or s['draw_calls'] <= 0 or not s['player_alive'] for s in report['samples']):
            raise RuntimeError('Benchmark did not render enough live gameplay')
        report['process'] = json.loads((output / 'process.json').read_text()) if (output / 'process.json').exists() else None
        if report['process'] is not None:
            report['process']['cpu_seconds'] = report['process']['user_seconds'] + report['process']['system_seconds']
        if args.binary:
            report['binary_sha256'] = provenance['binary_sha256']
            report['pack_sha256'] = provenance.get('pack_sha256')
        (output / 'performance.json').write_text(json.dumps(report, indent=2))
    else:
        report = json.loads((output / 'manifest.json').read_text())
        captures = report['captures']
        if report['mode'] != args.mode or not captures:
            raise RuntimeError('Missing capture manifest')
        if args.mode == 'scenes' and {item['file'] for item in captures} != {
                'refuge.png', 'maintenance.png', 'archives.png', 'reactor.png', 'robot.png'}:
            raise RuntimeError('Five comparison views required')
        for item in captures:
            with (output / item['file']).open('rb') as image:
                header = image.read(24)
            if header[:8] != b'\x89PNG\r\n\x1a\n' or list(struct.unpack('>II', header[16:24])) != report['resolution']:
                raise RuntimeError(f'Invalid capture: {item["file"]}')
        if args.mode == 'demo':
            if len(captures) < 120 or not report.get('complete'):
                raise RuntimeError('Animation sequence incomplete')
            ffmpeg = shutil.which('ffmpeg')
            if ffmpeg:
                subprocess.run([ffmpeg, '-v', 'error', '-framerate', '30', '-i', str(output / 'frame-%04d.png'),
                                '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-crf', '20', '-movflags', '+faststart',
                                str(output / 'demo.mp4')], check=True)
    print(json.dumps({'status': 'verified', 'mode': args.mode, 'output': str(output)}))


if __name__ == '__main__':
    main()
