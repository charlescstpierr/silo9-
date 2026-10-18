#!/usr/bin/env python3
"""Sequential conversion/decode plus exact consecutive-frame extraction after Godot exits."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import time


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    p = argparse.ArgumentParser()
    p.add_argument('film', type=Path)
    a = p.parse_args()
    folder = a.film.resolve()
    result = json.loads((folder / 'materials.json').read_text())
    manifest = json.loads((folder / 'manifest.json').read_text())
    if result['failures'] or manifest.get('validation') != 'PASS' or not manifest['source_tools_unchanged']:
        raise RuntimeError('Invalid film source')
    source = folder / 'materials.avi'
    destination = folder / 'materials.mp4'
    if destination.exists(): raise RuntimeError('Refuse overwrite')
    report = {'input_sha256': sha(source), 'commands': [], 'performance_valid': False, 'limits': 'Full decode is not continuous viewing or listening. Exact movie-index-to-overlay mapping requires inspecting extracted PNGs.'}

    def execute(command, name):
        log = folder / (name + '.log')
        started = time.monotonic()
        with log.open('w') as stream:
            completed = subprocess.run(command, stdout=stream, stderr=subprocess.STDOUT, timeout=360)
        report['commands'].append({'command': command, 'exit_code': completed.returncode, 'elapsed_seconds': time.monotonic() - started, 'log': log.name, 'log_sha256': sha(log)})
        (folder / 'media-manifest.json').write_text(json.dumps(report, indent=2) + '\n')
        if completed.returncode: raise RuntimeError(name + ' failed')
        return log

    ffmpeg = shutil.which('ffmpeg')
    ffprobe = shutil.which('ffprobe')
    report['tools_sha256'] = {str(path): sha(Path(path)) for path in [ffmpeg, ffprobe, __file__]}
    execute([ffmpeg, '-v', 'error', '-nostdin', '-i', str(source), '-map', '0:v:0', '-map', '0:a?', '-c:v', 'libx264', '-preset', 'medium', '-crf', '18', '-pix_fmt', 'yuv420p', '-c:a', 'aac', '-movflags', '+faststart', str(destination)], 'convert')
    execute([ffmpeg, '-v', 'error', '-nostdin', '-i', str(destination), '-f', 'null', '-'], 'decode-complete')
    metadata = execute([ffprobe, '-v', 'error', '-count_frames', '-show_streams', '-show_format', '-of', 'json', str(destination)], 'ffprobe')
    streams = json.loads(metadata.read_text())
    video = next(x for x in streams['streams'] if x['codec_type'] == 'video')
    if video['width'] != 1280 or video['height'] != 720 or video['avg_frame_rate'] != '30/1' or int(video['nb_read_frames']) < 1080:
        raise RuntimeError('Wrong film frame count/rate/size')
    report['video'] = {k: video.get(k) for k in ['width', 'height', 'avg_frame_rate', 'nb_read_frames', 'duration']}
    # Preserve the declared engine frame and explicit ffmpeg n; overlay review resolves any indexing offset.
    windows = [('d9-reload', 'film-w0-cold', 40), ('arc-cell', 'film-w1-cold', 50), ('arc-camera', 'film-w1-dim', 140)]
    report['sequences'] = []
    for name, segment, tick in windows:
        sample = next(x for x in result['film_frames'] if x['stage'] == segment + '-frame-%03d' % tick)
        start = sample['frame'] - 1
        seq = folder / name
        seq.mkdir(exist_ok=False)
        execute([ffmpeg, '-v', 'error', '-nostdin', '-i', str(destination), '-vf', f'select=between(n\\,{start}\\,{start+11})', '-fps_mode', 'passthrough', '-start_number', str(start), str(seq / 'movie-%06d.png')], name + '-extract')
        images = sorted(seq.glob('*.png'))
        if len(images) != 12: raise RuntimeError('Not twelve consecutive frames')
        report['sequences'].append({'name': name, 'requested_segment': segment, 'requested_tick': tick, 'reported_engine_frame': sample['frame'], 'movie_index_start_zero_based': start, 'movie_index_end_zero_based': start + 11, 'mapping_review': 'pending overlay inspection; no unverified engine/movie index equivalence claimed', 'frames_sha256': {x.name: sha(x) for x in images}})
    report['input_unchanged'] = sha(source) == report['input_sha256']
    report['mp4_sha256'] = sha(destination)
    report['mp4_bytes'] = destination.stat().st_size
    if not report['input_unchanged']: raise RuntimeError('AVI changed')
    (folder / 'media-manifest.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({'full_decode': 'PASS', 'video': report['video'], 'consecutive_sequences': len(report['sequences']), 'mp4_bytes': report['mp4_bytes']}))


if __name__ == '__main__':
    main()
