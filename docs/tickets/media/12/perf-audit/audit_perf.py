"""Read existing issue12 evidence; never launch the engine or alter a worktree."""
import hashlib
import itertools
import json
import math
from pathlib import Path
import re
import statistics
import subprocess

TASK = Path(__file__).resolve().parents[1]
EXPECTED = {
    "baseline": "6126e4cdc0c5c89122627789ce394d8a1f1b521e",
    "candidate": "2c205f59520d935e09c921574a20e42379999348",
}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def percentile(values, fraction):
    values = sorted(values)
    return values[min(int(len(values) * fraction), len(values) - 1)]


def summary(values):
    return {"median": statistics.median(values), "min": min(values), "max": max(values)}


def rank_permutation(a, b):
    """Exact two-sided permutation test of the Mann-Whitney U statistic."""
    values = a + b
    n = len(a)
    def u(indices):
        chosen = set(indices)
        return sum((values[i] > values[j]) + .5 * (values[i] == values[j])
                   for i in chosen for j in range(len(values)) if j not in chosen)
    observed = u(range(n))
    center = n * len(b) / 2
    distribution = [u(c) for c in itertools.combinations(range(len(values)), n)]
    p = sum(abs(v - center) >= abs(observed - center) for v in distribution) / len(distribution)
    return {"baseline_U": observed, "two_sided_p": p, "labelings": len(distribution)}


def main():
    errors, pending, rows, pairs = [], [], [], []
    current_sources = {}
    probe_hash = sha(TASK / "proof-tools/probe_sector_power.gd")
    for quality in ("normal", "low"):
        for index in range(1, 6):
            pair_file = TASK / "perf" / f"{quality}-{index}-pair.json"
            if not pair_file.exists():
                pending.append(str(pair_file.relative_to(TASK)))
                continue
            pair = json.loads(pair_file.read_text())
            order = ["baseline", "candidate"] if index % 2 else ["candidate", "baseline"]
            if [r["side"] for r in pair] != order or any(r["exit_code"] != 0 for r in pair):
                errors.append(f"{pair_file.name}: order or exit code")
            if pair[0]["end"] > pair[1]["start"]:
                errors.append(f"{pair_file.name}: overlap")
            pairs.append({"quality": quality, "index": index, "order": order,
                          "start": pair[0]["start"], "end": pair[-1]["end"]})
            for entry in pair:
                side = entry["side"]
                name = f"{quality}-{index}-{side}"
                folder = TASK / "perf" / name
                manifest = json.loads((folder / "manifest.json").read_text())
                journey = json.loads((folder / "journey.json").read_text())
                log = (folder / "engine.log").read_text()
                project = Path(manifest["project"])
                checks = {
                    "sha": manifest["head"] == EXPECTED[side],
                    "probe": manifest["probe_sha256"] == probe_hash,
                    "sources_stable": manifest["source_before"] == manifest["source_after"] and manifest["source_unchanged"],
                    "exit": manifest["exit_code"] == 0 and not manifest["validation_errors"],
                    "errors": not journey["failures"] and not re.search(r"SCRIPT ERROR:|ERROR:|Parse Error|Segmentation fault", log),
                    "quality": journey["low_quality"] == (quality == "low") and ("--low" in manifest["command"]) == (quality == "low"),
                    "mode": journey["mode"] == "perf" and journey["performance_valid"] and not journey["commands"] and journey["shots"] == 0,
                    "circuit_api": journey["circuits_available"] == (side == "candidate"),
                    "route": journey["waypoints_completed"] == 9 and journey["travelled_m"] > 90 and journey["health"] == 100,
                    "render": journey["display_driver"].lower() == "x11" and journey["rendering_method"] == "gl_compatibility" and journey["resolution"] == [1280, 720] and "llvmpipe" in journey["renderer"],
                    "engine": journey["engine"]["hash"] == "ed1daf0bf001b61586d9930840f2f1394092c079" and journey["engine"]["string"] == "4.7.2-stable (official)",
                    "display": manifest["display"] == ":100",
                    "time": entry["start"] <= manifest["started_unix"] < manifest["ended_unix"] <= entry["end"],
                }
                if side not in current_sources:
                    tracked = subprocess.check_output(["git", "-C", str(project), "ls-files", "-z"]).decode().split("\0")
                    checks["tracked_matches_commit"] = subprocess.run(["git", "-C", str(project), "diff", "--quiet", EXPECTED[side]], check=False).returncode == 0
                    current_sources[side] = {p: sha(project / p) for p in manifest["source_before"] if (project / p).is_file()}
                    checks["tracked_covered"] = all(p in manifest["source_before"] for p in tracked if p)
                checks["sources_match_current"] = manifest["source_before"] == current_sources[side]
                values = journey["frame_intervals_ms"]
                checks["samples"] = bool(values) and all(isinstance(v, (int, float)) and math.isfinite(v) and v > 0 for v in values)
                checks["frame_counts"] = len(values) == len(journey["frame_stages"]) == journey["frames_drawn"] - 1
                checks["route_stages"] = set(journey["frame_stages"]) == {
                    s for z in ("-10.0", "-16.0", "-22.0", "-32.0", "-36.0", "-42.0", "-12.0", "7.0")
                    for s in (f"walk_(0.0, 0.0, {z})", f"settle_{z}")
                }
                quantiles = {f"p{int(f*100)}": percentile(values, f) for f in (.5, .95, .99)}
                checks["percentiles"] = all(abs(v - journey[f"frame_{k}_ms"]) < 1e-8 for k, v in quantiles.items())
                errors.extend(f"{name}: {key}" for key, ok in checks.items() if not ok)
                rows.append({"name": name, "quality": quality, "index": index, "side": side,
                             **quantiles, "samples": len(values), "drawn": journey["frames_drawn"],
                             "duration_ms": sum(values), "travelled_m": journey["travelled_m"],
                             "waypoints": journey["waypoints_completed"],
                             "draw_max": journey["draw_calls_max"], "nodes_max": journey["nodes_max"],
                             "resources_max": journey["resources_max"], "source_files": len(manifest["source_before"]),
                             "engine": journey["engine"], "stage_counts": {s: journey["frame_stages"].count(s) for s in set(journey["frame_stages"])},
                             "warnings": len(re.findall(r"^WARNING:", log, re.M))})
    chronological = sorted(pairs, key=lambda p: p["start"])
    if any(a["end"] > b["start"] for a, b in zip(chronological, chronological[1:])):
        errors.append("pairs overlap")
    summaries = {}
    for quality in ("normal", "low"):
        a = sorted((r for r in rows if r["quality"] == quality and r["side"] == "baseline"), key=lambda r: r["index"])
        b = sorted((r for r in rows if r["quality"] == quality and r["side"] == "candidate"), key=lambda r: r["index"])
        if not a or not b:
            continue
        summaries[quality] = {}
        for metric in ("p50", "p95", "p99", "duration_ms", "draw_max", "nodes_max", "resources_max"):
            av, bv = [r[metric] for r in a], [r[metric] for r in b]
            summaries[quality][metric] = {"baseline": summary(av), "candidate": summary(bv),
                "median_change_percent": (statistics.median(bv) / statistics.median(av) - 1) * 100,
                "paired_delta": [y-x for x,y in zip(av,bv)], "rank_test": rank_permutation(av,bv)}
    print(json.dumps({"proof_verdict": "ISSUES" if errors else "BLOCKED" if pending else "PASS",
                      "errors": errors, "pending": pending, "runs": len(rows), "expected_heads": EXPECTED,
                      "probe_sha256": probe_hash, "summaries": summaries, "rows": rows, "pairs": chronological}, indent=2))


if __name__ == "__main__":
    main()
