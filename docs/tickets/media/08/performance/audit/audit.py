#!/usr/bin/env python3
"""Read-only independent audit of the completed ticket 8 measurement artifacts."""
from pathlib import Path
import hashlib, io, itertools, json, math, re, statistics, subprocess, tarfile

HERE = Path(__file__).resolve().parent
ISSUE = HERE.parent
ROOT = ISSUE.parents[3]
PERF = ISSUE / 'performance-final'
PROFILE = ISSUE / 'perf-profile'
REPO = ROOT / '.worktrees/silo9-issue-08'
REVISIONS = {'baseline': '98f2d4a735d7c2fe1ad6f3d8431ab86772db1e8a', 'candidate': 'efc2a581fd329321a852507d775af6fcda0a9cb1'}
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

# No engine, profiler, renderer or transcoder is invoked by this audit.
require((PERF / 'performance.json').is_file(), 'completed aggregate exists; partial series cannot PASS')
require(subprocess.check_output(['git','rev-parse','HEAD'],cwd=REPO).decode().strip() == REVISIONS['candidate'], 'candidate checkout HEAD')
source_invariants = {}
for source in ['scripts/player.gd','scripts/fps_rig.gd','scripts/weapon_handling.gd','project.godot']:
    versions = [subprocess.check_output(['git','show',rev+':'+source],cwd=REPO) for rev in REVISIONS.values()]
    require(versions[0] == versions[1], 'unchanged ADS/FOV/settings source: '+source)
    source_invariants[source] = hashlib.sha256(versions[0]).hexdigest()
pair_runner_sha = (ISSUE / 'pair-runner-sha256.txt').read_text().split()[0]
require(digest(ISSUE / 'run_perf_pair.py') == pair_runner_sha, 'pair orchestrator SHA matches recorded identity')
interruption = read(ISSUE / 'performance/interruption.json')
require(interruption['used_for_final_comparison'] is False, 'interrupted campaign explicitly excluded')
campaign = read(PERF / 'campaign.json')
require(set(p['revision'] for p in campaign['projects'].values()) == set(REVISIONS.values()) and len(campaign['projects']) == 2, 'exact two campaign revisions')
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
    require(not re.search(r'SCRIPT ERROR|ERROR:|Parse Error|Assertion failed', (PERF / name / 'import.log').read_text()), name + ': no import errors')
    require(preparation['exit_code'] == 0 and preparation['measured'] is False and preparation['before'] == campaign == preparation['after'], name + ': successful import outside timed region')

rows = []
fov_observations = {}
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
        require(manifest['probe_sha256'] == digest(folder / 'probe-at-launch.gd') == digest(ROOT / 'tools/probe_ads.gd'), folder.name + ': actual probe bytes')
        require(manifest['runner_sha256'] == digest(folder / 'runner-at-launch.py.txt') == digest(ROOT / 'tools/prove_ads.py'), folder.name + ': actual runner bytes')
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
        require(journey['aim_api'] and journey['base_fov'] == 76, folder.name + ': ADS API and same configured base FOV')
        require(journey['captures'][0]['fov'] == 76, folder.name + ': observed warmup FOV 76')
        fov_observations[folder.name] = {event['label']:event['fov'] for event in journey['events']}
        require(all(math.isfinite(event['fov']) for event in journey['events']), folder.name + ': finite observed event FOV')
        require(all(stage in journey['frame_stages'] for stage in ['walk-right-hip','R-while-aim-held','B-while-aim-held','settled-hip']), folder.name + ': movement, R, B and settle inside timed intervals')
        values = journey['frame_intervals_ms']
        require(len(values) == journey['frame_samples'] == len(journey['frame_stages']) and values and all(math.isfinite(value) and value > 0 for value in values), folder.name + ': finite raw intervals and stage labels')
        recomputed = {key: percentile(values, fraction) for key, fraction in [('frame_p50_ms', .5),('frame_p95_ms', .95)]}
        require(all(math.isclose(value, journey[key],abs_tol=1e-9) for key,value in recomputed.items()), folder.name + ': raw percentile recomputation')
        row = {'pair':number,'label':label,**recomputed, 'frame_samples':len(values),'measured_interval_sum_seconds':sum(values)/1000, 'wall_seconds':manifest['wall_seconds'], 'walk_distance':distance, **{key:journey[key] for key in ['draw_calls_max','nodes_max','resources_max']}, 'load_before':manifest['load_before'], 'load_after':manifest['load_after'], 'stage_counts':{stage:journey['frame_stages'].count(stage) for stage in sorted(set(journey['frame_stages']))}}
        rows.append(row)
        order.append((number,label))
        identities.append(tuple(journey[key] for key in ['scenario','renderer','godot','display_driver','rendering_method','rendering_driver','resolution','normal_quality']))
        ledger = recorded_runs[len(rows)-1]
        require(ledger['pair'] == number and ledger['label'] == label and all(ledger[key] == value for key,value in journey.items()), folder.name + ': ledger order and contents')
require(len(set(identities)) == 1, 'all ten runs share workload/renderer/settings')
metrics = ['frame_p50_ms','frame_p95_ms','draw_calls_max','nodes_max','resources_max']
summary = {label:{metric:stats([row[metric] for row in rows if row['label'] == label]) for metric in metrics} for label in REVISIONS}
require(summary == performance['summary'], 'independent summary equals published aggregate')

profile_campaign = read(PROFILE / 'campaign.json')
for tool, expected in profile_campaign['tools_sha256'].items():
    require(digest(Path(tool)) == expected, 'profile tool/binary current hash: '+Path(tool).name)
require(set(profile_campaign['tools_sha256'].values()) == set(campaign['tools_sha256'].values()), 'profile and final campaign use same binary/runner/probe bytes')
profile_preparation = read(PROFILE / 'prepare/manifest.json')
require(profile_preparation['exit_code'] == 0 and profile_preparation['before'] == profile_campaign == profile_preparation['after'], 'profile preparation unchanged and successful')
require(not re.search(r'SCRIPT ERROR|ERROR:|Parse Error|Assertion failed', (PROFILE / 'prepare/import.log').read_text()), 'profile import log has no errors')
profile_raw = read(PROFILE / 'cpu-threads.json')
profile_result = read(PROFILE / 'profile-result.json')
profile_manifest = read(PROFILE / 'run/manifest.json')
require(profile_raw['excluded_from_comparison'] and profile_result['excluded_from_comparison'], 'profile excluded from measured run list')
require(profile_manifest['revision'] == REVISIONS['candidate'] and profile_manifest['exit_code'] == 0, 'profile uses successful candidate')
require(profile_manifest['source_sha256'] == campaign['projects'][profile_manifest['project']]['source_sha256'], 'profile source fingerprint')
require(profile_manifest['probe_sha256'] == digest(ROOT / 'tools/probe_ads.gd'), 'profile uses same final probe')
require(profile_result['journey']['target_hits'] == 8 and profile_result['journey']['target_damage'] == 246 and profile_result['journey']['failures'] == [], 'profile valid workload')
samples = profile_raw['samples']
profile = []
for name, window in [('all',samples),('middle60percent',samples[int(len(samples)*.2):int(len(samples)*.8)])]:
    totals = [sum(thread['cpu_percent'] for thread in sample['threads']) for sample in window]
    llvmpipe = sum(thread['cpu_percent'] for sample in window for thread in sample['threads'] if thread['name'].startswith('llvmpipe-'))
    profile.append({'window':name,'samples':len(window),'mean_sum_cpu_percent':statistics.mean(totals),'llvmpipe_share':llvmpipe/sum(totals)})
    require(totals and all(math.isfinite(x) and x >= 0 for x in totals) and sum(totals) > 0, 'valid sampled CPU percentages '+name)
    profile[-1]['cpu_capacity_percent'] = profile_raw['cpu_count'] * 100
    profile[-1]['mean_host_capacity_fraction'] = statistics.mean(totals) / (profile_raw['cpu_count'] * 100)
    profile[-1]['sample_time_span_seconds'] = window[-1]['monotonic'] - window[0]['monotonic']
    by_name = {}
    for sample in window:
        for thread in sample['threads']:
            by_name[thread['name']] = by_name.get(thread['name'],0) + thread['cpu_percent']
    profile[-1]['top_threads_cpu_share'] = sorted([{'name':key,'share':value/sum(totals)} for key,value in by_name.items()], key=lambda row:row['share'],reverse=True)[:12]

# Shot observations include their weapon-specific recoil impulse. Transient entry
# samples may differ with render/physics scheduling; settled event FOV must match.
settled_labels = ['d9-hip','d9-full-ADS','d9-after-R','arc-ADS-1','arc-ADS-2','d9-final']
fov_summary = {label:stats([run[label] for run in fov_observations.values()]) for label in settled_labels}
for label, observed in fov_summary.items():
    require(observed['max'] - observed['min'] <= .01, 'same observed settled/recoil FOV across both versions: '+label)
profile_journey = read(PROFILE / 'run/journey.json')
require(profile_journey == {key:value for key,value in profile_result['journey'].items() if key != 'project_identity'}, 'profile raw journey agrees with result excluding runner-added identity')
require(profile_result['journey']['project_identity'] == campaign['projects'][profile_manifest['project']], 'profile runner-added identity exactly matches final frozen candidate source hashes')
require(not re.search(r'SCRIPT ERROR|ERROR:|Parse Error|Assertion failed', (PROFILE / 'run/godot.log').read_text()), 'profile engine log has no errors')
require(profile_manifest['runner_sha256'] == digest(ROOT / 'tools/prove_ads.py'), 'profile uses same final runner')
require('llvmpipe' in profile_journey['renderer'].lower() and profile_journey['renderer'] == identities[0][1], 'profile and measured renderer match llvmpipe')
require(len(samples) >= 5 and all(b['monotonic'] > a['monotonic'] for a,b in zip(samples,samples[1:])), 'profile has ordered independent samples')

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

report = {'exact_rank_sum':rank_tests,'source_revisions':REVISIONS,'run_count':10,'pairs':5,'order':order,'checks_passed':len(checks),'runs':rows,'summary':summary,'paired_candidate_minus_baseline_ms':paired_deltas,'ranges_overlap':overlap,'profile':profile,'profile_excluded':True,'renderer':identities[0][1], 'tool_sha256':campaign['tools_sha256'],'limits':['Full frame CPU wall intervals include VSync and scheduling.','Source launch through editor binary; not production export performance.','Software llvmpipe renderer; dominant observed CPU work is rendering, not proof of sole saturation.','Enemy callbacks frozen; small visible fixture added. ADS/FOV source and settled event observations match; the legacy zoom-change warning does not apply.','Fixed second waits quantize to physics/render ticks; actual horizontal movement and frame counts vary.','No target GPU, Windows, physical-controller or 60 FPS claim.','Warmup captures have PNG integrity checks only in this audit; pixel review remains separate.']}
report.update(fov_observations=fov_observations, fov_summary=fov_summary, unchanged_fov_source_sha256=source_invariants, assertions=checks,
    evidence_sha256={str(path.relative_to(ISSUE)):digest(path) for path in list(PERF.rglob('*.json')) + list(PERF.rglob('*.log')) + [PROFILE/'cpu-threads.json',PROFILE/'profile-result.json',PROFILE/'run/manifest.json',PROFILE/'run/journey.json',PROFILE/'run/godot.log',PROFILE/'run.py']},
    pair_runner_sha256=pair_runner_sha, interrupted_campaign=interruption, audit_source_sha256=digest(Path(__file__)), status='artifact_checks_passed', comparative_verdict=('no_measurable_difference_in_this_campaign' if all(overlap.values()) and all(test['exact_two_sided_p'] > .05 for test in rank_tests.values()) else 'requires_interpretation'), statistical_limit='Absence of detected difference is not an equivalence or noninferiority test.', visual_verdict='outside this audit', production_gpu_verdict='not measured')
(HERE/'audit.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({'checks_passed':len(checks),'summary':summary,'ranges_overlap':overlap,'profile':profile},indent=2))
