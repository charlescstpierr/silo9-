"""Guardrail checks only. Fake executable/data here NEVER constitute Godot evidence."""
import copy
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
from types import SimpleNamespace
import unittest

spec = importlib.util.spec_from_file_location("ads_runner", Path(__file__).with_name("prove_ads.py"))
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)

class Guardrails(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.repo = self.root / "repo"
        self.repo.mkdir()
        self.git("init", "-q")
        self.git("config", "user.email", "proof@example.invalid")
        self.git("config", "user.name", "Synthetic proof guardrails")
        (self.repo / "scripts").mkdir()
        (self.repo / "scripts/main.gd").write_text("synthetic fixture, not executable GDScript\n")
        (self.repo / "tests").mkdir()
        (self.repo / "tests/check.gd").write_text("test fixture\n")
        self.git("add", ".")
        self.git("commit", "-qm", "synthetic initial fixture")
        self.binary = self.root / "synthetic-not-godot"
        self.binary.write_text("#!/bin/sh\nexit 7\n")
        self.binary.chmod(0o755)
        self.args = SimpleNamespace(project=self.repo, godot=self.binary)
        self.args.campaign = runner.freeze_campaign([self.repo], self.binary, self.repo)

    def tearDown(self):
        self.temp.cleanup()

    def git(self, *args):
        return subprocess.check_output(["git", *args], cwd=self.repo)

    def result(self):
        png = b"\x89PNG\r\n\x1a\n" + b"\0" * 8 + (1280).to_bytes(4, "big") + (720).to_bytes(4, "big")
        (self.root / "renderer-warmup.png").write_bytes(png)
        return dict(engine_version=dict(major=4, minor=7, patch=2), display_driver="X11", rendering_method="gl_compatibility", rendering_driver="opengl3", renderer="synthetic-validator-fixture", render_loop_enabled=True, frames_drawn_start=2, frames_drawn_end=3, warmup_capture="renderer-warmup.png", frame_intervals_ms=[1., 2., 3., 4.], frame_samples=4, frame_stages=["fixture"]*4, frame_p50_ms=3., frame_p95_ms=4.)

    def workload(self):
        data = self.result()
        data.update(failures=[], target_hits=8, accepted_shots=8, target_damage=246,
                    aim_api=True, lifecycle=[
                        dict(kind="walk-right", start=[0., 0., 7.], end=[.6, 0., 7.],
                             direction=[1., 0., 0.], horizontal_distance=.6, forward_distance=.6),
                        dict(kind="reload", ammo_before=8, ammo_after=12, reserve_before=48, reserve_after=44)],
                    events=[dict(weapon=0, damage=27)]*6 + [dict(weapon=1, damage=42)]*2)
        return data

    def invoke_workload(self, data, mode):
        data = copy.deepcopy(data)
        data["performance_valid"] = mode == "perf"
        payload = self.root / "synthetic-result.json"
        payload.write_text(json.dumps(data))
        self.binary.write_text("#!/usr/bin/env python3\n"
            "import pathlib, shutil, sys\n"
            "root = pathlib.Path(__file__).parent\n"
            "output = pathlib.Path(next(a.split('=', 1)[1] for a in sys.argv if a.startswith('--proof-output=')))\n"
            "shutil.copyfile(root / 'synthetic-result.json', output / 'journey.json')\n"
            "shutil.copyfile(root / 'renderer-warmup.png', output / 'renderer-warmup.png')\n")
        self.args.campaign = runner.freeze_campaign([self.repo], self.binary, self.repo)
        if "DISPLAY" not in os.environ: os.environ["DISPLAY"] = ":synthetic-no-server"
        output = self.root / f"run-{len(list(self.root.glob('run-*')))}"
        return runner.invoke(self.args, self.repo, output, mode)

    def test_complete_lifecycle_accepted(self):
        for mode in ("perf", "film"):
            with self.subTest(mode=mode): self.invoke_workload(self.workload(), mode)

    def test_stale_lifecycle_refused(self):
        for mode in ("perf", "film"):
            for value in (None, [], [dict(kind="reload")]):
                with self.subTest(mode=mode, value=value):
                    data = self.workload()
                    if value is None: del data["lifecycle"]
                    else: data["lifecycle"] = value
                    with self.assertRaises(RuntimeError): self.invoke_workload(data, mode)

    def test_reload_without_transfer_refused(self):
        for mode in ("perf", "film"):
            for field, value in (("ammo_after", 8), ("reserve_after", 48), ("ammo_before", 9), ("reserve_before", 49), ("ammo_after", True)):
                with self.subTest(mode=mode, field=field):
                    data = self.workload()
                    data["lifecycle"][1][field] = value
                    with self.assertRaises(RuntimeError): self.invoke_workload(data, mode)

    def test_invalid_movement_refused(self):
        cases = [
            dict(end=[0., 0., 7.], horizontal_distance=0., forward_distance=0.),
            dict(end=[0., -2., 7.], horizontal_distance=2., forward_distance=2.),
            dict(end=[-.6, 0., 7.], horizontal_distance=.6, forward_distance=-.6),
            dict(end=[.01, 0., 7.], horizontal_distance=.01, forward_distance=.01),
            dict(end=[.6, 0., 7.], horizontal_distance=4.),
            dict(direction=[-1., 0., 0.]),
            dict(direction=[1., 1., 0.]),
            dict(end=[float("nan"), 0., 7.]),
            dict(start=[0., float("inf"), 7.]),
            dict(direction=[True, 0., 0.]),
            dict(end=[.6, 0.]),
        ]
        for mode in ("perf", "film"):
            for case in cases:
                with self.subTest(mode=mode, case=case):
                    data = self.workload()
                    data["lifecycle"][0].update(case)
                    with self.assertRaises(RuntimeError): self.invoke_workload(data, mode)

    def test_clean_git_identity(self):
        self.assertEqual(runner.verify_campaign(self.args), self.args.campaign)

    def test_modified_source_refused(self):
        (self.repo / "scripts/main.gd").write_text("changed")
        with self.assertRaises(RuntimeError): runner.verify_campaign(self.args)

    def test_modified_tests_refused(self):
        (self.repo / "tests/check.gd").write_text("changed")
        with self.assertRaises(RuntimeError): runner.verify_campaign(self.args)

    def test_untracked_source_refused(self):
        (self.repo / "scripts/extra.gd").write_text("changed")
        with self.assertRaises(RuntimeError): runner.verify_campaign(self.args)

    def test_revision_change_refused(self):
        self.git("commit", "--allow-empty", "-qm", "new revision")
        with self.assertRaises(RuntimeError): runner.verify_campaign(self.args)

    def test_binary_change_refused(self):
        self.binary.write_text("#!/bin/sh\nexit 0\n")
        with self.assertRaises(RuntimeError): runner.verify_campaign(self.args)

    def test_import_failure_records_evidence(self):
        folder = self.root / "prepare"
        with self.assertRaises(RuntimeError): runner.prepare(self.args, self.repo, folder)
        manifest = json.loads((folder / "manifest.json").read_text())
        self.assertEqual(manifest["exit_code"], 7)
        self.assertFalse(manifest["measured"])
        self.assertEqual(manifest["before"], manifest["after"])

    def test_nonzero_invocation_refused(self):
        if "DISPLAY" not in os.environ: os.environ["DISPLAY"] = ":synthetic-no-server"
        folder = self.root / "invocation"
        with self.assertRaises(RuntimeError): runner.invoke(self.args, self.repo, folder, "perf")
        manifest = json.loads((folder / "manifest.json").read_text())
        self.assertEqual(manifest["exit_code"], 7)
        self.assertTrue(manifest["campaign_unchanged"])

    def test_renderer_and_draw_progress_required(self):
        for field, value in [("display_driver", "headless"), ("rendering_driver", "dummy"), ("render_loop_enabled", False), ("frames_drawn_end", 2), ("renderer", "")]:
            with self.subTest(field=field):
                data = self.result()
                data[field] = value
                with self.assertRaises(RuntimeError): runner.validate_rendered_result(data, self.root)

    def test_bad_intervals_and_percentiles_refused(self):
        for value in [float("nan"), float("inf"), 0, -1, True]:
            with self.subTest(value=value):
                data = self.result()
                data["frame_intervals_ms"][0] = value
                with self.assertRaises(RuntimeError): runner.validate_rendered_result(data, self.root)
        data = self.result()
        data["frame_p95_ms"] = 3.9
        with self.assertRaises(RuntimeError): runner.validate_rendered_result(data, self.root)

    def test_missing_capture_refused(self):
        data = self.result()
        (self.root / "renderer-warmup.png").unlink()
        with self.assertRaises(OSError): runner.validate_rendered_result(data, self.root)

    def test_changed_capture_size_refused(self):
        data = self.result()
        (self.root / "renderer-warmup.png").write_bytes(b"not PNG")
        with self.assertRaises(RuntimeError): runner.validate_rendered_result(data, self.root)

if __name__ == "__main__":
    print("SYNTHETIC guardrails: temporary Git trees and fake executable; NO Godot runtime or pixel/performance proof", flush=True)
    unittest.main(verbosity=2)
