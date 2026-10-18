#!/usr/bin/env python3
"""Record the real controller and compare the same scene on two source revisions."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import signal
import statistics
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
PARSER = argparse.ArgumentParser(description=__doc__)
PARSER.add_argument("--video", action="store_true")
PARSER.add_argument("--inspect", action="store_true")
PARSER.add_argument("--measure", action="store_true")
PARSER.add_argument("--baseline", type=Path)
PARSER.add_argument("--runs", type=int, default=5)
ARGS = PARSER.parse_args()
OUT = ROOT / ".cstack/issue-02/proof"
OUT.mkdir(parents=True, exist_ok=True)
ENV = dict(os.environ, DISPLAY=os.environ.get("DISPLAY", ":97"), XDG_DATA_HOME=str(OUT / "user-data"))
GODOT = (ROOT / ".tools/Godot_v4.7.2-stable_linux.x86_64").resolve()


def invoke(project, destination, measure=False, inspection=False):
    destination.mkdir(parents=True, exist_ok=True)
    command = [str(GODOT), "--path", str(project), "--position", "0,0", "--audio-driver", "Dummy", "--script", "tools/probe_fps_rig.gd", "--", "--proof-output=" + str(destination)]
    if measure:
        command.append("--rig-cost")
    if inspection:
        command.append("--rig-inspection")
    with (destination / "godot.log").open("w") as log:
        result = subprocess.run(command, env=ENV, stdout=log, stderr=subprocess.STDOUT, timeout=120)
    contents = (destination / "godot.log").read_text()
    if result.returncode or "SCRIPT ERROR" in contents or "ERROR:" in contents:
        raise RuntimeError(f"Proof failed. See {destination / 'godot.log'}")


metadata = {
    "head": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
    "source_sha256": {str(path.relative_to(ROOT)): hashlib.sha256(path.read_bytes()).hexdigest() for path in sorted((ROOT / "scripts").glob("*.gd"))},
    "status": subprocess.check_output(["git", "status", "--short"], cwd=ROOT, text=True),
    "cpu_count": os.cpu_count(),
    "load_before": os.getloadavg(),
    "platform": os.uname().sysname + " " + os.uname().release,
    "display": ENV["DISPLAY"],
    "video_fps": 15,
}
if ARGS.video:
    with (OUT / "ffmpeg.log").open("w") as log:
        recorder = subprocess.Popen(["ffmpeg", "-y", "-f", "x11grab", "-draw_mouse", "0", "-video_size", "1280x720", "-framerate", "15", "-i", ENV["DISPLAY"] + ".0+0,0", "-c:v", "libx264", "-preset", "ultrafast", "-crf", "20", "-pix_fmt", "yuv420p", str(OUT / "fps-rig.mp4")], stdout=log, stderr=subprocess.STDOUT)
        try:
            time.sleep(.4)
            invoke(ROOT, OUT / "demo")
        finally:
            recorder.send_signal(signal.SIGINT)
            recorder.wait(timeout=10)
    subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration:stream=width,height,nb_frames", "-of", "json", str(OUT / "fps-rig.mp4")], stdout=(OUT / "video.json").open("w"), check=True)
if ARGS.inspect:
    invoke(ROOT, OUT / "inspection", inspection=True)
if ARGS.measure:
    rows = []
    for run in range(ARGS.runs):
        for label, project in [("before", ARGS.baseline), ("after", ROOT)]:
            if project is None:
                continue
            destination = OUT / f"{label}-{run}"
            invoke(project.resolve(), destination, measure=True)
            data = json.loads((destination / "cost.json").read_text())
            rows.append(dict(side=label, run=run, source_sha256={str(path.relative_to(project)): hashlib.sha256(path.read_bytes()).hexdigest() for path in sorted((project / "scripts").glob("*.gd"))}, **data))
    (OUT / "measurements.json").write_text(json.dumps(rows, indent=2))
    summary = {}
    for label in {row["side"] for row in rows}:
        for visible in [True, False]:
            records = [record for row in rows if row["side"] == label for record in row["records"] if record["hands_visible"] == visible]
            if not records:
                continue
            summary[f"{label}-hands-{visible}"] = {metric: {"median": statistics.median(record[metric] for record in records), "min": min(record[metric] for record in records), "max": max(record[metric] for record in records)} for metric in ["frame_p50_ms", "rig_update_call_p50_ms", "draw_calls", "triangles"]}
    (OUT / "summary.json").write_text(json.dumps(summary, indent=2))
metadata["load_after"] = os.getloadavg()
(OUT / ("metadata-measure.json" if ARGS.measure else "metadata-video.json")).write_text(json.dumps(metadata, indent=2))
print(OUT)
