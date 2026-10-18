#!/usr/bin/env python3
"""Render ARC manipulation and compare the delivered animation with baseline ARC ready."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import statistics
import subprocess
import struct
import wave

ROOT = Path(__file__).resolve().parents[1]
PARSER = argparse.ArgumentParser(description=__doc__)
PARSER.add_argument("--inspect", action="store_true")
PARSER.add_argument("--fps", action="store_true")
PARSER.add_argument("--film", action="store_true")
PARSER.add_argument("--measure", action="store_true")
PARSER.add_argument("--baseline", type=Path)
PARSER.add_argument("--runs", type=int, default=5)
PARSER.add_argument("--output", type=Path, default=ROOT / ".cstack/issue-04/proof-final")
ARGS = PARSER.parse_args()
OUT = ARGS.output.resolve()
OUT.mkdir(parents=True, exist_ok=True)
GODOT = (ROOT / ".tools/Godot_v4.7.2-stable_linux.x86_64").resolve()
ENV = dict(os.environ, DISPLAY=os.environ.get("DISPLAY", ":99"), XDG_DATA_HOME=str(OUT / "user-data"))


def fingerprint(project):
    paths = list((project / "scripts").glob("*.gd")) + list((project / "data/weapons").glob("*.tres")) + [project / "project.godot"]
    return {str(p.relative_to(project)): hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(paths)}


def invoke(project, destination, script, flags=(), mode=()):
    destination.mkdir(parents=True, exist_ok=True)
    probe = ROOT / "tools" / script
    command = [str(GODOT), "--path", str(project), "--position", "0,0", "--audio-driver", "Dummy", *flags, "--script", str(probe), "--", "--proof-output=" + str(destination), *mode]
    revision_file = project / ".baseline-revision"
    revision = revision_file.read_text().strip() if revision_file.exists() else subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=project, text=True).strip()
    metadata = {"revision": revision, "runner_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(), "command": command, "project": str(project), "source_sha256": fingerprint(project), "probe_sha256": hashlib.sha256(probe.read_bytes()).hexdigest(), "display": ENV["DISPLAY"]}
    (destination / "manifest.json").write_text(json.dumps(metadata, indent=2) + "\n")
    with (destination / "godot.log").open("w") as log:
        result = subprocess.run(command, env=ENV, stdout=log, stderr=subprocess.STDOUT, timeout=360)
    metadata["exit_code"] = result.returncode
    metadata["source_unchanged"] = metadata["source_sha256"] == fingerprint(project)
    (destination / "manifest.json").write_text(json.dumps(metadata, indent=2) + "\n")
    log = (destination / "godot.log").read_text()
    if result.returncode or "SCRIPT ERROR" in log or "ERROR:" in log or not metadata["source_unchanged"]:
        raise RuntimeError(f"Probe failed or source changed: {destination}")


def audio_analysis(folder):
    with wave.open(str(folder / "movie-audio.wav")) as stream:
        rate, channels, frames = stream.getframerate(), stream.getnchannels(), stream.getnframes()
        raw = stream.readframes(frames)
    samples = struct.unpack("<" + "h" * (len(raw) // 2), raw)
    window = rate // 1000
    peaks = [max(abs(x) for x in samples[i * channels:(i + window) * channels]) for i in range(0, frames, window)]
    events = json.loads((folder / "events.json").read_text())
    rows = []
    for event in events["events"]:
        if event["event"] not in [64, 128, 256, 512]:
            continue
        expected = event["frame"] / 30
        start, end = max(0, int((expected - .05) * 1000)), min(len(peaks), int((expected + .2) * 1000))
        above = [i for i in range(start, end) if peaks[i] > 150]
        if not above:
            raise RuntimeError(f"No actual mixer cue near frame {event['frame']}")
        rows.append({"event": event["event"], "frame": event["frame"], "onset_s": above[0] / 1000, "onset_minus_event_ms": above[0] - expected * 1000, "max_pcm": max(peaks[start:end])})
    result = {"source": "Godot MovieMaker PCM, no reconstructed sound", "rate": rate, "channels": channels, "duration_s": frames / rate, "nonzero_samples": sum(x != 0 for x in samples), "threshold_pcm": 150, "events": rows}
    (folder / "audio-analysis.json").write_text(json.dumps(result, indent=2) + "\n")


if ARGS.fps:
    invoke(ROOT, OUT / "inspection", "probe_arc_cell.gd", mode=["--probe-mode=fps"])
if ARGS.inspect:
    invoke(ROOT, OUT / "inspection", "probe_arc_cell.gd", mode=["--probe-mode=inspection"])
if ARGS.film:
    folder = OUT / "film"
    invoke(ROOT, folder, "probe_arc_cell.gd", flags=["--write-movie", str(folder / "arc.avi"), "--fixed-fps", "30"])
    subprocess.run(["ffmpeg", "-y", "-i", str(folder / "arc.avi"), "-vn", "-acodec", "pcm_s16le", str(folder / "movie-audio.wav")], check=True, capture_output=True)
    subprocess.run(["ffmpeg", "-y", "-i", str(folder / "arc.avi"), "-c:v", "libx264", "-crf", "22", "-pix_fmt", "yuv420p", "-c:a", "aac", str(folder / "arc-cell.mp4")], check=True, capture_output=True)
    audio_analysis(folder)
if ARGS.measure:
    if ARGS.baseline is None:
        PARSER.error("--measure requires --baseline")
    results = []
    for run in range(ARGS.runs):
        for label, project in [("baseline", ARGS.baseline.resolve()), ("candidate", ROOT)]:
            destination = OUT / f"perf-{run + 1}-{label}"
            invoke(project, destination, "probe_arc_cost.gd", mode=["--candidate"] if label == "candidate" else [])
            result = json.loads((destination / "cost.json").read_text())
            result.update(run=run + 1, revision=label)
            results.append(result)
            print(run + 1, label, result["records"], flush=True)
    summary = {}
    for label in ["baseline", "candidate"]:
        for active in [False, True]:
            rows = [r for result in results if result["revision"] == label for r in result["records"] if r["active_cell"] == active]
            if not rows:
                continue
            summary[f"{label}-{'cell' if active else 'ready'}"] = {key: {"median": statistics.median(r[key] for r in rows), "min": min(r[key] for r in rows), "max": max(r[key] for r in rows)} for key in ["frame_p50_ms", "frame_p95_ms", "rig_call_p50_ms", "rig_call_p95_ms"]}
    (OUT / "performance.json").write_text(json.dumps({"runs": results, "summary": summary}, indent=2) + "\n")
