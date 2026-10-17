"""Measure the exported game in alternating graphics modes, preserving raw results."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import resource
import statistics
import shutil
import subprocess
import time

parser = argparse.ArgumentParser()
parser.add_argument("--runs", type=int, default=5)
args = parser.parse_args()
if not 1 <= args.runs <= 20:
    parser.error("--runs must be between 1 and 20")
root = Path(__file__).resolve().parent.parent
binary = root / "builds/linux/SILO9.x86_64"
output = root / ".cstack/silo9/evidence/performance"
output.mkdir(parents=True, exist_ok=True)
environment = os.environ.copy()
environment["XDG_DATA_HOME"] = str(root / ".cstack/silo9/performance-user-data")
user_data = Path(environment["XDG_DATA_HOME"]) / "godot/app_userdata/SILO 9 — LA DESCENTE"
records = []
for run in range(args.runs):
    for mode in ("normal", "low"):
        command = [str(binary), "--audio-driver", "Dummy", "--", "--benchmark"]
        if mode == "low":
            command.append("--low")
        if run == 0:
            command.append("--capture")
        path = user_data / f"performance-{mode}.json"
        path.unlink(missing_ok=True)
        log_path = output / f"{run + 1}-{mode}.log"
        before = resource.getrusage(resource.RUSAGE_CHILDREN)
        start = time.monotonic()
        with log_path.open("w") as log:
            result = subprocess.run(command, cwd=root, env=environment, stdout=log,
                                    stderr=subprocess.STDOUT, timeout=90)
        wall_seconds = time.monotonic() - start
        after = resource.getrusage(resource.RUSAGE_CHILDREN)
        if result.returncode or re.search(r"(?m)^(ERROR:|SCRIPT ERROR:|FAIL:)", log_path.read_text()):
            raise SystemExit(f"Failed run: {log_path}")
        report = json.loads(path.read_text())
        if len(report["samples"]) != 4 or any(s["frames"] < 10 or s["draw_calls"] <= 0 or not s["player_alive"] for s in report["samples"]):
            raise SystemExit(f"Incomplete rendered work: {path}")
        report["run"] = run + 1
        report["wall_seconds"] = wall_seconds
        report["cpu_seconds"] = after.ru_utime + after.ru_stime - before.ru_utime - before.ru_stime
        records.append(report)
        if run == 0:
            for sector in range(4):
                shutil.copy2(user_data / f"sector-{sector}.png", output / f"{mode}-sector-{sector}.png")
        (output / f"{run + 1}-{mode}.json").write_text(json.dumps(report, indent=2))
        print(f"run={run + 1} mode={mode} wall={wall_seconds:.1f}s", flush=True)
summary = {"binary_sha256": hashlib.sha256(binary.read_bytes()).hexdigest(), "runs_per_mode": args.runs,
           "renderer": records[0]["renderer"], "resolution": records[0]["resolution"],
           "limits": ["Software rendering, not a gaming GPU", "VSync disable requested; driver reports mode changes unsupported",
                      "Stationary camera samples, not human playtime", "Release memory monitor unavailable"], "sectors": []}
for index in range(4):
    item = {"sector": records[0]["samples"][index]["sector"]}
    for mode in ("normal", "low"):
        values = [r["samples"][index]["p50_ms"] for r in records if r["quality"] == mode]
        tails = [r["samples"][index]["p95_ms"] for r in records if r["quality"] == mode]
        item[mode] = {"p50_median_ms": statistics.median(values), "p50_range_ms": [min(values), max(values)], "p95_median_ms": statistics.median(tails)}
    summary["sectors"].append(item)
(output / "summary.json").write_text(json.dumps(summary, indent=2))
print(json.dumps(summary, indent=2))
