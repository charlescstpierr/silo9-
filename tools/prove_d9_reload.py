#!/usr/bin/env python3
"""Capture the rendered D9 sequence or compare active reload cost on two revisions."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import statistics
import struct
import subprocess
import wave

ROOT = Path(__file__).resolve().parents[1]
PARSER = argparse.ArgumentParser(description=__doc__)
PARSER.add_argument("--film", action="store_true")
PARSER.add_argument("--inspect", action="store_true")
PARSER.add_argument("--measure", action="store_true")
PARSER.add_argument("--baseline", type=Path)
PARSER.add_argument("--runs", type=int, default=5)
ARGS = PARSER.parse_args()
OUT = ROOT / ".cstack/issue-03/proof-final"
OUT.mkdir(parents=True, exist_ok=True)
GODOT = (ROOT / ".tools/Godot_v4.7.2-stable_linux.x86_64").resolve()
ENV = dict(os.environ, DISPLAY=os.environ.get("DISPLAY", ":97"), XDG_DATA_HOME=str(OUT / "user-data"))


def fingerprint(project):
    paths = list((project / "scripts").glob("*.gd")) + list((project / "data/weapons").glob("*.tres"))
    return {str(p.relative_to(project)): hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(paths)}


def invoke(project, destination, script, flags=(), mode=()):
    destination.mkdir(parents=True, exist_ok=True)
    command = [str(GODOT), "--path", str(project), "--position", "0,0", "--audio-driver", "Dummy", *flags, "--script", str(ROOT / "tools" / script), "--", "--proof-output=" + str(destination), *mode]
    metadata = {"command": command, "head": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=project, text=True).strip(), "source_sha256": fingerprint(project), "probe_sha256": hashlib.sha256((ROOT / "tools" / script).read_bytes()).hexdigest(), "load_before": os.getloadavg()}
    (destination / "source-manifest.json").write_text(json.dumps(metadata, indent=2) + "\n")
    with (destination / "godot.log").open("w") as log:
        result = subprocess.run(command, env=ENV, stdout=log, stderr=subprocess.STDOUT, timeout=240)
    contents = (destination / "godot.log").read_text()
    if result.returncode or "SCRIPT ERROR" in contents or "ERROR:" in contents:
        raise RuntimeError(f"Proof failed: {destination / 'godot.log'}")
    return metadata


def analyze_audio(folder):
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(folder / "d9.avi"), "-vn", "-c:a", "pcm_s16le", str(folder / "movie-audio.wav")], check=True)
    with wave.open(str(folder / "movie-audio.wav")) as stream:
        rate, channels, frames = stream.getframerate(), stream.getnchannels(), stream.getnframes()
        raw = stream.readframes(frames)
    samples = struct.unpack("<" + "h" * (len(raw) // 2), raw)
    window = rate // 1000
    peaks = [max(abs(x) for x in samples[i * channels:(i + window) * channels]) for i in range(0, frames, window)]
    events = json.loads((folder / "events.json").read_text())
    rows = []
    for event in events["events"]:
        if event["event"] not in [1, 2, 4, 8]:
            continue
        expected = event["frame"] / 30
        start, end = max(0, int((expected - .05) * 1000)), min(len(peaks), int((expected + .2) * 1000))
        above = [i for i in range(start, end) if peaks[i] > 150]
        if not above:
            raise RuntimeError(f"No actual mixer cue near frame {event['frame']}")
        rows.append({"event": event["event"], "frame": event["frame"], "onset_s": above[0] / 1000, "onset_minus_event_ms": above[0] - expected * 1000, "max_pcm": max(peaks[start:end])})
    result = {"source": "Godot MovieMaker PCM; no reconstructed sound", "rate": rate, "channels": channels, "duration_s": frames / rate, "nonzero_samples": sum(x != 0 for x in samples), "threshold_pcm": 150, "events": rows}
    (folder / "audio-analysis.json").write_text(json.dumps(result, indent=2) + "\n")


if ARGS.film:
    folder = OUT / "film"
    folder.mkdir(exist_ok=True)
    invoke(ROOT, folder, "probe_d9_reload.gd", flags=["--write-movie", str(folder / "d9.avi"), "--fixed-fps", "30"])
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(folder / "d9.avi"), "-c:v", "libx264", "-preset", "medium", "-crf", "20", "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "128k", str(folder / "d9-reload.mp4")], check=True)
    analyze_audio(folder)
if ARGS.inspect:
    invoke(ROOT, OUT / "inspection", "probe_d9_reload.gd", mode=["--probe-mode=inspection"])
if ARGS.measure:
    if ARGS.baseline is None:
        PARSER.error("--measure requires an imported --baseline project")
    records = []
    for run in range(ARGS.runs):
        projects = [("before", ARGS.baseline.resolve()), ("after", ROOT)]
        if run % 2:
            projects.reverse()
        for side, project in projects:
            destination = OUT / f"{side}-{run}"
            metadata = invoke(project, destination, "probe_d9_cost.gd")
            measurement = json.loads((destination / "cost.json").read_text())
            if side == "after":
                gestures = set(measurement["records"][1]["gestures"])
                if not set(map(str, range(1, 10))).issubset(gestures):
                    raise RuntimeError("Active measurement did not render every reload gesture")
            records.append(dict(side=side, run=run, **measurement, **metadata))
    summary = {}
    for side in ["before", "after"]:
        for active in [False, True]:
            rows = [row for run in records if run["side"] == side for row in run["records"] if row["active_reload"] == active]
            summary[f"{side}-{'reload' if active else 'ready'}"] = {metric: {"median": statistics.median(row[metric] for row in rows), "min": min(row[metric] for row in rows), "max": max(row[metric] for row in rows)} for metric in ["frame_p50_ms", "frame_p95_ms", "rig_call_p50_ms", "rig_call_p95_ms", "draw_calls_min", "draw_calls_max", "triangles_min", "triangles_max"]}
    result = {"platform": os.uname().sysname + " " + os.uname().release, "cpu_count": os.cpu_count(), "display": ENV["DISPLAY"], "capture_running": False, "records": records, "summary": summary}
    (OUT / "performance.json").write_text(json.dumps(result, indent=2) + "\n")
print(OUT)
