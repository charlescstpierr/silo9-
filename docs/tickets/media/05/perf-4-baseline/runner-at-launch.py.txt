#!/usr/bin/env python3
"""Capture weapon handling and compare matched journeys in five serial pairs."""
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
PARSER.add_argument("--film", action="store_true")
PARSER.add_argument("--measure", action="store_true")
PARSER.add_argument("--baseline", type=Path)
PARSER.add_argument("--output", type=Path, default=ROOT / ".cstack/issue-05/proof")
ARGS = PARSER.parse_args()
OUT = ARGS.output.resolve()
OUT.mkdir(parents=True, exist_ok=True)
GODOT = (ROOT / ".tools/Godot_v4.7.2-stable_linux.x86_64").resolve()
PROBE = ROOT / "tools/probe_weapon_handling.gd"
ENV = dict(os.environ, DISPLAY=os.environ.get("DISPLAY", ":100"), XDG_DATA_HOME=str(OUT / "user-data"))


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def source_fingerprint(project, revision):
    paths = subprocess.check_output(["git", "ls-tree", "-r", "--name-only", revision, "scripts", "data/weapons", "project.godot"], cwd=ROOT, text=True).splitlines()
    actual = {path: digest(project / path) for path in paths}
    expected = {path: hashlib.sha256(subprocess.check_output(["git", "show", f"{revision}:{path}"], cwd=ROOT)).hexdigest() for path in paths}
    if actual != expected:
        raise RuntimeError("Production source does not match committed revision: " + str(project))
    return actual


def invoke(project, destination, mode):
    destination.mkdir(parents=True, exist_ok=True)
    revision_file = project / ".baseline-revision"
    revision = revision_file.read_text().strip() if revision_file.exists() else subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=project, text=True).strip()
    command = [str(GODOT), "--path", str(project), "--position", "0,0", "--audio-driver", "Dummy"]
    if mode == "film":
        command += ["--write-movie", str(destination / "handling.avi"), "--fixed-fps", "30"]
    command += ["--script", str(PROBE), "--", "--proof-output=" + str(destination), "--probe-mode=" + mode]
    manifest = {"revision": revision, "source_sha256": source_fingerprint(project, revision), "source_verified_against_git": True, "probe_sha256": digest(PROBE), "runner_sha256": digest(Path(__file__)), "command": command, "display": ENV["DISPLAY"], "project": str(project)}
    (destination / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    (destination / "probe-at-launch.gd.txt").write_bytes(PROBE.read_bytes())
    (destination / "runner-at-launch.py.txt").write_bytes(Path(__file__).read_bytes())
    with (destination / "godot.log").open("w") as log:
        result = subprocess.run(command, env=ENV, stdout=log, stderr=subprocess.STDOUT, timeout=360)
    manifest.update(exit_code=result.returncode, source_unchanged=manifest["source_sha256"] == source_fingerprint(project, revision), probe_unchanged=manifest["probe_sha256"] == digest(PROBE), runner_unchanged=manifest["runner_sha256"] == digest(Path(__file__)))
    (destination / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    log = (destination / "godot.log").read_text()
    if result.returncode or "ERROR:" in log or "SCRIPT ERROR" in log or not all(manifest[k] for k in ["source_unchanged", "probe_unchanged", "runner_unchanged"]):
        raise RuntimeError("Probe failed or source changed: " + str(destination))
    return json.loads((destination / "journey.json").read_text())


def analyze_audio(folder):
    with wave.open(str(folder / "movie-audio.wav")) as stream:
        rate, channels, frames = stream.getframerate(), stream.getnchannels(), stream.getnframes()
        raw = stream.readframes(frames)
    samples = struct.unpack("<" + "h" * (len(raw) // 2), raw)
    window = rate // 1000
    peaks = [max(abs(v) for v in samples[i * channels:(i + window) * channels]) for i in range(0, frames, window)]
    journey = json.loads((folder / "journey.json").read_text())
    cues = []
    for event in journey["events"]:
        if event["event"] not in [1, 2, 4, 8, 64, 128, 256, 512]:
            continue
        expected_ms = event["frame"] / 30 * 1000
        start, end = max(0, int(expected_ms - 50)), min(len(peaks), int(expected_ms + 200))
        audible = [i for i in range(start, end) if peaks[i] > 150]
        if not audible:
            raise RuntimeError("No mixer signal near manipulation event: " + str(event))
        cues.append(dict(event, onset_minus_event_ms=audible[0] - expected_ms, peak_pcm=max(peaks[start:end])))
    (folder / "audio-analysis.json").write_text(json.dumps({"source": "Godot MovieMaker PCM", "rate": rate, "channels": channels, "duration_s": frames / rate, "nonzero_samples": sum(v != 0 for v in samples), "cue_windows": cues}, indent=2) + "\n")


if ARGS.inspect:
    invoke(ROOT, OUT / "inspection", "inspection")
if ARGS.film:
    folder = OUT / "film"
    invoke(ROOT, folder, "film")
    subprocess.run(["ffmpeg", "-y", "-i", str(folder / "handling.avi"), "-vn", "-acodec", "pcm_s16le", str(folder / "movie-audio.wav")], check=True, capture_output=True)
    subprocess.run(["ffmpeg", "-y", "-i", str(folder / "handling.avi"), "-c:v", "libx264", "-crf", "22", "-pix_fmt", "yuv420p", "-c:a", "aac", str(folder / "weapon-handling.mp4")], check=True, capture_output=True)
    analyze_audio(folder)
if ARGS.measure:
    if ARGS.baseline is None:
        PARSER.error("--measure requires --baseline")
    rows = []
    for run in range(1, 6):
        for label, project in [("baseline", ARGS.baseline.resolve()), ("candidate", ROOT)]:
            result = invoke(project, OUT / f"perf-{run}-{label}", "perf")
            result.update(run=run, revision_label=label)
            rows.append(result)
            print(run, label, result["frame_p50_ms"], result["frame_p95_ms"], flush=True)
    keys = ["frame_p50_ms", "frame_p95_ms", "warm_rig_zero_p50_ms", "warm_rig_zero_p95_ms"]
    summary = {label: {key: {"median": statistics.median(r[key] for r in rows if r["revision_label"] == label), "min": min(r[key] for r in rows if r["revision_label"] == label), "max": max(r[key] for r in rows if r["revision_label"] == label)} for key in keys} for label in ["baseline", "candidate"]}
    (OUT / "performance.json").write_text(json.dumps({"runs": rows, "summary": summary}, indent=2) + "\n")
