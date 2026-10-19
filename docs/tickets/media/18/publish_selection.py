from pathlib import Path
import hashlib
import json
import shutil

ROOT = Path(__file__).resolve().parents[4]
TASK = Path(__file__).resolve().parent
DEST = ROOT / '.worktrees/silo9-issue-18/docs/tickets/media/18'
TOP = ['delivery-review.md', 'gameplay-identity.json', 'raw-evidence-whitespace.json', 'publish_selection.py', 'verify_packages.py', 'publication-tool-change.json', 'published-selfchecks.log', 'published-selfchecks-green.log', 'published-compile.log', 'performance-decision.md', 'proof-contract.md', 'perf-plan.md', 'red-report.md', 'code-review.md', 'proof-tool-report.md', 'proof-tool-review.md', 'package-visual-review.md', 'perf-review.md', 'art-review.md', 'native-summary.json', 'perf-summary.json', 'perf-freeze.json', 'native-campaign.json', 'run_native_campaign.py', 'run_perf_pair.py', 'native_package_smoke_verified.py', 'profile-route-link.json', 'profile-route-cpu.log', 'profile-route-launch.py', 'parent-tool-selfchecks.log', 'export.log']
DIRS = ['delivery-review', 'visual-supplement', 'perf-interrupted-01', 'design', 'implementation', 'red-tests', 'code-review', 'proof-tools', 'proof-tool-tests', 'proof-tool-review', 'reload-budget', 'perf', 'perf-audit', 'native-mother', 'native-n7-low', 'native-film', 'packaged-native-verified', 'profile-route-candidate', 'profile-tools']
SKIP_PARTS = {'userdata', 'config', 'cache', '__pycache__', '.godot'}


def selected():
    for name in TOP:
        path = TASK / name
        if not path.is_file():
            raise FileNotFoundError(path)
        yield path
    for name in DIRS:
        folder = TASK / name
        if not folder.is_dir():
            raise FileNotFoundError(folder)
        for path in sorted(folder.rglob('*')):
            relative = path.relative_to(folder)
            if not path.is_file() or any(part in SKIP_PARTS for part in relative.parts):
                continue
            if path.suffix in ('.uid', '.pyc', '.part'):
                continue
            if name == 'design' and path.name not in ('accepted.md', 'accepted-review.md'):
                continue
            if name in ('proof-tool-tests', 'red-tests') and path.suffix in ('.png', '.mp4'):
                continue
            if name == 'implementation' and any(part in ('old', 'preview-cache') for part in relative.parts):
                continue
            yield path


def main():
    paths = list(selected())
    DEST.mkdir(parents=True, exist_ok=True)
    manifest = {}
    for path in paths:
        relative = path.relative_to(TASK)
        target = DEST / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(path, target)
        manifest[str(relative)] = {'sha256': hashlib.sha256(target.read_bytes()).hexdigest(), 'bytes': target.stat().st_size}
    (DEST / 'SHA256.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(json.dumps({'files': len(manifest), 'bytes': sum(row['bytes'] for row in manifest.values()), 'destination': str(DEST)}))


if __name__ == '__main__':
    main()
