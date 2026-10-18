#!/usr/bin/env python3
"""Read-only independent audit of the completed ticket 7 measurement artifacts."""
from pathlib import Path
import hashlib, io, itertools, json, math, re, statistics, subprocess, tarfile

HERE = Path(__file__).resolve().parent
ISSUE = HERE.parent
ROOT = ISSUE.parents[3]
PERF = ISSUE / 'performance-final'
PROFILE = ISSUE / 'perf-profile-final'
REPO = ROOT / '.worktrees/silo9-issue-07'
REVISIONS = {'baseline': '2818e15a617760dcb98b93927eb563d7af05ba17', 'candidate': '1f36f01eea2e5d34dafee7f46a665c013370cbb4'}
SOURCE_PATHS = ['scripts', 'data', 'assets', 'scenes', 'main.tscn', 'project.godot', 'tests']
checks = []

def require(condition, message):
    if not condition:
        raise AssertionError(message)
    checks.append(message)

def read(path):
    return json.loads(path.read_text())

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def stats(values):
    return {'median': statistics.median(values), 'min': min(values), 'max': max(values)}

def percentile(values, fraction):
    ordered = sorted(values)
    return ordered[min(math.floor(len(ordered) * fraction), len(ordered) - 1)]

campaign = read(PERF / 'campaign.json')
performance = read(PERF / 'performance.json')  # Must only exist after all ten invocations.
recorded_runs = read(PERF / 'runs.json')
require(len(recorded_runs) == 10, 'ten completed measurements')
require(performance['campaign'] == campaign, 'aggregate uses frozen campaign')
require(performance['runs'] == recorded_runs, 'aggregate and run ledger agree')

for tool, expected in campaign['tools_sha256'].items():
    require(digest(Path(tool)) == expected, 'current tool/binary hash: ' + Path(tool).name)
for project, identity in campaign['projects'].items():
    revision = identity['revision']
    require(revision in REVISIONS.values(), 'expected source revision ' + revision)
    tracked = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', revision, '--', *SOURCE_PATHS], cwd=REPO).decode().splitlines()
    archive = subprocess.check_output(['git', 'archive', revision, '--', *tracked], cwd=REPO)
    with tarfile.open(fileobj=io.BytesIO(archive)) as tar:
        expected = {entry.name: hashlib.sha256(tar.extractfile(entry).read()).hexdigest() for entry in tar.getmembers() if entry.isfile()}
    require(expected == identity['source_sha256'], 'Git archive hashes equal campaign ' + revision)
    actual = {name: digest(Path(project) / name) for name in expected}
    require(actual == expected, 'current source/test bytes equal Git ' + revision)

for name in ['prepare-1', 'prepare-2']:
    preparation = read(PERF / name / 'manifest.json')
    require(preparation['exit_code'] == 0 and preparation['measured'] is False and preparation['before'] == campaign == preparation['after'], name + ': successful import outside timed region')

rows = []
identities = []
order = []
for number in range(1, 6):
    for label in (['baseline', 'candidate'] if number % 2 else ['candidate', 'baseline']):
        folder = PERF / f'perf-{number}-{label}'
        manifest = read(folder / 'manifest.json')
        journey = read(folder / 'journey.json')
        identity = campaign['projects'][manifest['project']]
        require(manifest['revision'] == REVISIONS[label] == identity['revision'], folder.name + ': expected revision')
        require(manifest['source_sha256'] == identity['source_sha256'], folder.name + ': source fingerprint')
        require(manifest['exit_code'] == 0 and manifest['campaign_unchanged'] and not manifest.get('timeout'), folder.name + ': successful unchanged run')
        require(not re.search(r'SCRIPT ERROR|ERROR:|Parse Error|Assertion failed', (folder / 'godot.log').read_text()), folder.name + ': no engine errors')
        require(manifest['probe_sha256'] == digest(folder / 'probe-at-launch.gd') == digest(ISSUE / 'proof-tools/probe_ads.gd'), folder.name + ': actual probe bytes')
        require(manifest['runner_sha256'] == digest(folder / 'runner-at-launch.py.txt') == digest(ISSUE / 'proof-tools/prove_ads.py'), folder.name + ': actual runner bytes')
        require(manifest['mode'] == 'perf' and '--fixed-fps' not in manifest['command'] and '--write-movie' not in manifest['command'] and '--headless' not in manifest['command'], folder.name + ': no film or headless mode')
        require(journey['mode'] == 'perf' and journey['performance_valid'] and journey['failures'] == [], folder.name + ': workload accepted')
        require(journey['display_driver'].lower() == 'x11' and journey['rendering_method'] == 'gl_compatibility' and journey['rendering_driver'] == 'opengl3' and journey['render_loop_enabled'], folder.name + ': real renderer active')
        require(journey['frames_drawn_end'] > journey['frames_drawn_start'], folder.name + ': frames drawn')
        require(journey['resolution'] == '1280x720' and journey['normal_quality'], folder.name + ': same normal quality and resolution')
        require([journey['engine_version'][key] for key in ['major','minor','patch']] == [4,7,2], folder.name + ': Godot version')
        png = (folder / journey['warmup_capture']).read_bytes()
        require(png[:8] == b'\x89PNG\r\n\x1a\n' and [int.from_bytes(png[i:i+4], 'big') for i in [16,20]] == [1280,720], folder.name + ': warmup PNG envelope')
        require(journey['accepted_shots'] == journey['target_hits'] == len(journey['events']) == 8 and journey['target_damage'] == 246, folder.name + ': eight hits and 246 damage')
        require([event['weapon'] for event in journey['events']] == [0,0,0,0,0,1,1,0], folder.name + ': six D9 and two ARC in order')
        for event in journey['events']:
            weapon = event['weapon']
            require(event['damage'] == (28 if weapon == 0 else 39) and event['ammo_before'] - event['ammo_after'] == (1 if weapon == 0 else 0) and event['energy_before'] - event['energy_after'] == (0 if weapon == 0 else 12), folder.name + ': damage/ammo/energy ' + event['label'])
            require(all(math.isfinite(value) for key in ['ray_from','ray_to','impact','target_world'] for value in event[key]), folder.name + ': finite trajectory ' + event['label'])
            require(math.dist(event['impact'], event['target_world']) < .04, folder.name + ': impact on fixture ' + event['label'])
        move, reload = journey['lifecycle']
        distance = math.hypot(move['end'][0]-move['start'][0],move['end'][2]-move['start'][2])
        dx = move['end'][0]-move['start'][0]
        require(move['kind'] == 'walk-right' and move['direction'] == [1,0,0] and .1 <= distance <= 3 and dx/distance >= .9 and math.isclose(distance,move['horizontal_distance'],abs_tol=1e-5), folder.name + ': actual right movement')
        require(reload == {'kind':'reload','ammo_before':8,'ammo_after':12,'reserve_before':48,'reserve_after':44}, folder.name + ': actual R transfer')
        require(journey['events'][-2]['energy_after'] == 76 and journey['events'][-1]['energy_before'] == 100, folder.name + ': energy restored after B')
        values = journey['frame_intervals_ms']
        require(len(values) == journey['frame_samples'] == len(journey['frame_stages']) and values and all(math.isfinite(value) and value > 0 for value in values), folder.name + ': finite raw intervals and stage labels')
        recomputed = {key: percentile(values, fraction) for key, fraction in [('frame_p50_ms', .5),('frame_p95_ms', .95)]}
        require(all(math.isclose(value, journey[key],abs_tol=1e-9) for key,value in recomputed.items()), folder.name + ': raw percentile recomputation')
        row = {'pair':number,'label':label,**recomputed, 'frame_samples':len(values),'measured_interval_sum_seconds':sum(values)/1000, 'wall_seconds':manifest['wall_seconds'], 'walk_distance':distance, **{key:journey[key] for key in ['draw_calls_max','nodes_max','resources_max']}, 'load_before':manifest['load_before'], 'load_after':manifest['load_after']}
        rows.append(row)
        order.append((number,label))
        identities.append(tuple(journey[key] for key in ['scenario','renderer','godot','display_driver','rendering_method','rendering_driver','resolution','normal_quality']))
        ledger = recorded_runs[len(rows)-1]
        require(ledger['pair'] == number and ledger['label'] == label and all(ledger[key] == value for key,value in journey.items()), folder.name + ': ledger order and contents')
require(len(set(identities)) == 1, 'all ten runs share workload/renderer/settings')
metrics = ['frame_p50_ms','frame_p95_ms','draw_calls_max','nodes_max','resources_max']
summary = {label:{metric:stats([row[metric] for row in rows if row['label'] == label]) for metric in metrics} for label in REVISIONS}
require(summary == performance['summary'], 'independent summary equals published aggregate')

profile_raw = read(PROFILE / 'cpu-threads.json')
profile_result = read(PROFILE / 'profile-result.json')
profile_summary = read(PROFILE / 'summary.json')
profile_manifest = read(PROFILE / 'run/manifest.json')
require(profile_raw['excluded_from_comparison'] and profile_result['excluded_from_comparison'], 'profile excluded from measured run list')
require(profile_manifest['revision'] == REVISIONS['candidate'] and profile_manifest['exit_code'] == 0, 'profile uses successful candidate')
require(profile_manifest['source_sha256'] == campaign['projects'][profile_manifest['project']]['source_sha256'], 'profile source fingerprint')
require(profile_manifest['probe_sha256'] == digest(ISSUE / 'proof-tools/probe_ads.gd'), 'profile uses same final probe')
require(profile_result['journey']['target_hits'] == 8 and profile_result['journey']['target_damage'] == 246 and profile_result['journey']['failures'] == [], 'profile valid workload')
samples = profile_raw['samples']
profile = []
for name, window in [('all',samples),('middle60percent',samples[int(len(samples)*.2):int(len(samples)*.8)])]:
    totals = [sum(thread['cpu_percent'] for thread in sample['threads']) for sample in window]
    llvmpipe = sum(thread['cpu_percent'] for sample in window for thread in sample['threads'] if thread['name'].startswith('llvmpipe-'))
    profile.append({'window':name,'samples':len(window),'mean_sum_cpu_percent':statistics.mean(totals),'llvmpipe_share':llvmpipe/sum(totals)})
    expected = next(row for row in profile_summary['summaries'] if row['window'] == name)
    require(all(math.isclose(value,expected[key],rel_tol=1e-10) if isinstance(value,float) else value == expected[key] for key,value in profile[-1].items()), 'recomputed profile window ' + name)

paired_deltas = {metric:[next(row[metric] for row in rows if row['pair']==pair and row['label']=='candidate')-next(row[metric] for row in rows if row['pair']==pair and row['label']=='baseline') for pair in range(1,6)] for metric in ['frame_p50_ms','frame_p95_ms']}
overlap = {metric:max(summary['baseline'][metric]['min'],summary['candidate'][metric]['min']) <= min(summary['baseline'][metric]['max'],summary['candidate'][metric]['max']) for metric in ['frame_p50_ms','frame_p95_ms']}
rank_tests = {}
for metric in ['frame_p50_ms','frame_p95_ms']:
    values = [row[metric] for label in ['baseline','candidate'] for row in rows if row['label'] == label]
    def rank_u(indices):
        complement = set(range(10)) - set(indices)
        return sum((values[i] > values[j]) + .5 * (values[i] == values[j]) for i in indices for j in complement)
    observed = rank_u(range(5))
    null = [rank_u(indices) for indices in itertools.combinations(range(10),5)]
    rank_tests[metric] = {'u_baseline_greater':observed,'exact_two_sided_p':sum(abs(value-12.5) >= abs(observed-12.5) for value in null)/len(null),'permutations':len(null)}

report = {'exact_rank_sum':rank_tests,'source_revisions':REVISIONS,'run_count':10,'pairs':5,'order':order,'checks_passed':len(checks),'runs':rows,'summary':summary,'paired_candidate_minus_baseline_ms':paired_deltas,'ranges_overlap':overlap,'profile':profile,'profile_excluded':True,'renderer':identities[0][1], 'tool_sha256':campaign['tools_sha256'],'limits':['Full frame CPU wall intervals include VSync and scheduling.','Source launch through editor binary; not production export performance.','Software llvmpipe renderer; dominant observed CPU work is rendering, not proof of sole saturation.','Enemy callbacks frozen; small fixture added. Functional ADS zoom changes view volume.','Fixed second waits quantize to physics/render ticks; actual horizontal movement and frame counts vary.','No target GPU, Windows, physical-controller or 60 FPS claim.','Warmup captures have PNG integrity checks only in this audit; pixel review remains separate.']}
(HERE/'audit.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({'checks_passed':len(checks),'summary':summary,'ranges_overlap':overlap,'profile':profile},indent=2))
