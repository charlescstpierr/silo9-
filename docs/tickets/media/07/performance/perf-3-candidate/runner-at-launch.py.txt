#!/usr/bin/env python3
"""Inspect, film, or compare actual ADS shots. Requires a running X11 display, never starts one."""

import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import re
import shutil
import statistics
import subprocess
import sys
import time

PROBE = Path(__file__).resolve().with_name("probe_ads.gd")
SOURCE_PATHS = ["scripts", "data", "assets", "scenes", "main.tscn", "project.godot", "tests"]


def sha(data):
    return hashlib.sha256(data).hexdigest()


def git(repository, *arguments):
    return subprocess.check_output(["git", *arguments], cwd=repository)


def fingerprint(project, revision, repository):
    tracked = git(repository, "ls-tree", "-r", "--name-only", revision, "--", *SOURCE_PATHS).decode().splitlines()
    actual = {name: sha((project / name).read_bytes()) for name in tracked}
    expected = {name: sha(git(repository, "show", f"{revision}:{name}")) for name in tracked}
    extras = []
    for name in SOURCE_PATHS:
        path = project / name
        if path.is_dir():
            extras.extend(str(p.relative_to(project)) for p in path.rglob("*") if p.is_file() and p.suffix not in {".uid", ".import"} and str(p.relative_to(project)) not in expected)
    if actual != expected or extras:
        raise RuntimeError(f"Production differs from Git revision {revision} in {project}; extra files: {extras}")
    return actual


def write_json(path, data):
    path.write_text(json.dumps(data, indent=2, allow_nan=False) + "\n")


def revision_for(project, repository):
    marker = project / ".baseline-revision"
    revision = marker.read_text().strip() if marker.exists() else subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=project).decode().strip()
    return git(repository, "rev-parse", f"{revision}^{{commit}}").decode().strip()


def freeze_campaign(projects, godot, repository):
    return {
        "projects": {str(project): {"revision": revision, "source_sha256": fingerprint(project, revision, repository)}
                     for project in projects for revision in [revision_for(project, repository)]},
        "tools_sha256": {str(path): sha(path.read_bytes()) for path in (PROBE, Path(__file__), godot)},
    }


def verify_campaign(args):
    current = freeze_campaign([Path(path) for path in args.campaign["projects"]], args.godot, args.project)
    if current != args.campaign:
        raise RuntimeError("Campaign revision, source/tests, tools or engine changed; discard this series")
    return current


def prepare(args, project, destination):
    destination.mkdir(parents=True, exist_ok=False)
    manifest = {"measured": False, "before": verify_campaign(args)}
    command = [str(args.godot), "--headless", "--path", str(project), "--editor", "--import", "--quit", "--rendering-method", "gl_compatibility", "--audio-driver", "Dummy"]
    manifest["command"] = command
    try:
        with (destination / "import.log").open("w") as log:
            process = subprocess.run(command, env=dict(os.environ, XDG_DATA_HOME=str(destination / "user-data")), stdout=log, stderr=subprocess.STDOUT, timeout=360)
        manifest["exit_code"] = process.returncode
        if process.returncode or re.search(r"SCRIPT ERROR|ERROR:|Parse Error|Assertion failed", (destination / "import.log").read_text()):
            raise RuntimeError(f"Project import failed: {destination}")
    finally:
        try:
            manifest["after"] = verify_campaign(args)
        except (OSError, RuntimeError, subprocess.SubprocessError) as error:
            manifest["integrity_error"] = str(error)
            raise
        finally:
            write_json(destination / "manifest.json", manifest)


def validate_rendered_result(result, destination):
    version = result["engine_version"]
    if ([version[key] for key in ("major", "minor", "patch")] != [4, 7, 2]
            or result["display_driver"].lower() != "x11"
            or result["rendering_method"] != "gl_compatibility"
            or result["rendering_driver"] not in {"opengl3", "opengl3_es", "opengl3_angle"}
            or not result["renderer"].strip()
            or not result["render_loop_enabled"]
            or result["frames_drawn_end"] <= result["frames_drawn_start"]):
        raise RuntimeError(f"Requires active Godot 4.7.2 X11 Compatibility renderer: {destination}")
    if result["warmup_capture"] != "renderer-warmup.png":
        raise RuntimeError(f"Missing unmeasured renderer warmup capture: {destination}")
    png = (destination / result["warmup_capture"]).read_bytes()
    if png[:8] != b"\x89PNG\r\n\x1a\n" or [int.from_bytes(png[i:i + 4], "big") for i in (16, 20)] != [1280, 720]:
        raise RuntimeError(f"Invalid renderer warmup PNG: {destination}")
    frames = result["frame_intervals_ms"]
    if (not frames or len(frames) != result["frame_samples"] or len(frames) != len(result["frame_stages"])
            or any(type(value) not in (int, float) or not math.isfinite(value) or value <= 0 for value in frames)):
        raise RuntimeError(f"Invalid raw frame samples: {destination}")
    ordered = sorted(frames)
    for key, fraction in (("frame_p50_ms", .5), ("frame_p95_ms", .95)):
        if not math.isclose(result[key], ordered[min(int(len(ordered) * fraction), len(ordered) - 1)], rel_tol=1e-6):
            raise RuntimeError(f"Percentile disagrees with raw frames: {destination}")


def validate_lifecycle(result):
    lifecycle = result.get("lifecycle")
    if (not isinstance(lifecycle, list) or len(lifecycle) != 2
            or any(not isinstance(event, dict) for event in lifecycle)):
        raise RuntimeError("Missing movement/reload lifecycle observations")
    movement, reload = lifecycle
    if movement.get("kind") != "walk-right" or reload.get("kind") != "reload":
        raise RuntimeError("Wrong movement/reload lifecycle sequence")
    expected_reload = dict(ammo_before=8, ammo_after=12, reserve_before=48, reserve_after=44)
    if any(type(reload.get(key)) is not int or reload[key] != value for key, value in expected_reload.items()):
        raise RuntimeError("Reload did not transfer four rounds from reserve into magazine")
    for key in ("start", "end", "direction"):
        vector = movement.get(key)
        if (not isinstance(vector, list) or len(vector) != 3
                or any(type(value) not in (int, float) or not math.isfinite(value) for value in vector)):
            raise RuntimeError(f"Invalid movement {key}")
    if any(not math.isclose(value, expected, abs_tol=1e-5) for value, expected in zip(movement["direction"], [1., 0., 0.])):
        raise RuntimeError("Right movement must follow the scenario's initial +X heading")
    dx = movement["end"][0] - movement["start"][0]
    dz = movement["end"][2] - movement["start"][2]
    distance = math.hypot(dx, dz)
    if not .1 <= distance <= 3. or dx < .1 or dx / distance < .9:
        raise RuntimeError("Insufficient or incorrect horizontal right movement")
    for key, measured in (("horizontal_distance", distance), ("forward_distance", dx)):
        value = movement.get(key)
        if (type(value) not in (int, float) or not math.isfinite(value)
                or not math.isclose(value, measured, rel_tol=1e-5, abs_tol=1e-5)):
            raise RuntimeError(f"Movement {key} disagrees with observed positions")


def invoke(args, project, destination, mode, candidate=True):
    verify_campaign(args)
    destination.mkdir(parents=True, exist_ok=False)
    identity = args.campaign["projects"][str(project)]
    revision, source = identity["revision"], identity["source_sha256"]
    probe = destination / "probe-at-launch.gd"
    probe.write_bytes(PROBE.read_bytes())
    (destination / "runner-at-launch.py.txt").write_bytes(Path(__file__).read_bytes())
    env = dict(os.environ, XDG_DATA_HOME=str(destination / "user-data"))
    command = [str(args.godot), "--path", str(project), "--display-driver", "x11", "--rendering-method", "gl_compatibility", "--position", "0,0", "--resolution", "1280x720", "--audio-driver", "Dummy"]
    if mode == "film":
        command += ["--write-movie", str(destination / "ads.avi"), "--fixed-fps", "30"]
    command += ["--script", str(probe), "--", f"--proof-output={destination}", f"--probe-mode={mode}"]
    if candidate:
        command.append("--require-ads")
    manifest = {"revision":revision, "project":str(project), "command":command, "display":env["DISPLAY"], "source_sha256":source, "source_verified_against_git":True, "probe_sha256":sha(probe.read_bytes()), "runner_sha256":sha(Path(__file__).read_bytes()), "cpu_count":os.cpu_count(), "load_before":os.getloadavg(), "mode":mode}
    write_json(destination / "manifest.json", manifest)
    started = time.monotonic()
    try:
        with (destination / "godot.log").open("w") as log:
            process = subprocess.run(command, env=env, stdout=log, stderr=subprocess.STDOUT, timeout=360)
        manifest["exit_code"] = process.returncode
    except subprocess.TimeoutExpired:
        manifest["timeout"] = True
        raise
    finally:
        manifest.update(wall_seconds=time.monotonic() - started, load_after=os.getloadavg())
        try:
            verify_campaign(args)
            manifest["campaign_unchanged"] = True
        except (OSError, RuntimeError, subprocess.SubprocessError) as error:
            manifest.update(campaign_unchanged=False, integrity_error=str(error))
            raise
        finally:
            write_json(destination / "manifest.json", manifest)
    log = (destination / "godot.log").read_text()
    if process.returncode or re.search(r"SCRIPT ERROR|ERROR:|Parse Error|Assertion failed", log):
        raise RuntimeError(f"Failed run: {destination}; read godot.log and manifest.json")
    result = json.loads((destination / "journey.json").read_text())
    validate_rendered_result(result, destination)
    if result["failures"] or not result["frame_samples"] or result["target_hits"] != result["accepted_shots"]:
        raise RuntimeError(f"Invalid observed workload: {destination}")
    quota, damage = (18, 603) if mode == "inspection" else (8, 246)
    if result["accepted_shots"] != quota or result["target_damage"] != damage:
        raise RuntimeError(f"Wrong {mode} quota: expected {quota} hits and {damage} damage: {destination}")
    if result["performance_valid"] is not (mode == "perf"):
        raise RuntimeError("Only perf may declare performance_valid")
    if candidate and not result["aim_api"]:
        raise RuntimeError("Candidate lacks required ADS API")
    if (len(result["events"]) != quota or sum(event["damage"] for event in result["events"]) != damage
            or sum(event["weapon"] == 0 for event in result["events"]) != (9 if mode == "inspection" else 6)
            or sum(event["weapon"] == 1 for event in result["events"]) != (9 if mode == "inspection" else 2)):
        raise RuntimeError("Shot events disagree with observed workload")
    if mode in ("perf", "film"):
        validate_lifecycle(result)
    result["project_identity"] = identity
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=["inspection", "film", "perf"])
    parser.add_argument("--project", type=Path, default=Path.cwd(), help="Committed candidate checkout")
    parser.add_argument("--baseline", type=Path, help="Git worktree or git archive with .baseline-revision")
    parser.add_argument("--output", type=Path, required=True, help="New empty destination; existing run directories are refused")
    parser.add_argument("--godot", type=Path, default=Path(os.environ.get("GODOT_BIN", Path.cwd() / ".tools/Godot_v4.7.2-stable_linux.x86_64")))
    args = parser.parse_args()
    args.project = args.project.resolve()
    args.output = args.output.resolve()
    args.godot = args.godot.resolve()
    if not os.environ.get("DISPLAY"):
        parser.error("Set DISPLAY to an existing real X11 renderer; headless/dummy cannot prove pixels")
    if not args.godot.is_file():
        parser.error("Godot binary missing; supply --godot")
    if args.mode != "perf" and args.baseline is not None:
        parser.error("baseline comparison is performance-only; inspection/film require candidate ADS")
    if args.mode == "perf" and args.baseline is None:
        parser.error("perf requires --baseline")
    if args.output.exists() and any(args.output.iterdir()):
        parser.error("--output must be new or empty")
    args.output.mkdir(parents=True, exist_ok=True)
    projects = list(dict.fromkeys(([args.baseline.resolve()] if args.baseline else []) + [args.project]))
    args.campaign = freeze_campaign(projects, args.godot, args.project)
    write_json(args.output / "campaign.json", args.campaign)
    for index, project in enumerate(projects):
        prepare(args, project, args.output / f"prepare-{index + 1}")
    if args.mode != "perf":
        invoke(args, args.project, args.output / args.mode, args.mode)
        if args.mode == "film":
            ffmpeg = shutil.which("ffmpeg")
            if ffmpeg:
                folder = args.output / "film"
                with (folder / "ffmpeg.log").open("w") as log:
                    subprocess.run([ffmpeg, "-n", "-i", str(folder / "ads.avi"), "-c:v", "libx264", "-crf", "22", "-pix_fmt", "yuv420p", "-c:a", "aac", str(folder / "ads.mp4")], check=True, stdout=log, stderr=subprocess.STDOUT, timeout=180)
        verify_campaign(args)
        return
    rows = []
    variants = [("baseline", args.baseline.resolve(), False), ("candidate", args.project, True)]
    for pair in range(5):
        order = variants if pair % 2 == 0 else list(reversed(variants))
        for label, project, candidate in order:
            result = invoke(args, project, args.output / f"perf-{pair + 1}-{label}", "perf", candidate)
            result.update(pair=pair + 1, label=label)
            rows.append(result)
            write_json(args.output / "runs.json", rows)
            print(label, pair + 1, result["frame_p50_ms"], result["frame_p95_ms"], flush=True)
    verify_campaign(args)
    identity = {(r["scenario"], r["accepted_shots"], r["target_damage"], r["renderer"], r["godot"], r["display_driver"], r["rendering_method"], r["rendering_driver"], r["resolution"], r["normal_quality"]) for r in rows}
    if len(identity) != 1:
        raise RuntimeError("Runs differ in workload, renderer, resolution or engine")
    metrics = ["frame_p50_ms", "frame_p95_ms", "draw_calls_max", "nodes_max", "resources_max"]
    summary = {label: {key: {"median":statistics.median(values), "min":min(values), "max":max(values)} for key in metrics for values in [[r[key] for r in rows if r["label"] == label]]} for label, *_ in variants}
    write_json(args.output / "performance.json", {"campaign":args.campaign, "runs":rows, "summary":summary, "verdict":"inconclusive until renderer/process limiter and run variation are reviewed", "pixel_review":"pending manual review of warmup and hip/ADS PNGs; projected markers are not a visual PASS", "limits":"Full-frame interval includes scheduling and VSync. Candidate ADS zoom changes the viewing volume versus baseline; this is a functional difference, not isolated scalar interpolation cost. Warmup PNG is saved before recording; no profiling or video in measured region; no target GPU or Windows claim."})


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, KeyError, TypeError, RuntimeError, subprocess.SubprocessError) as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
