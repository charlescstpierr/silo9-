"""Independent read-only analysis of the 20 ticket18 perf runs. Never runs Godot."""
from collections import Counter
from copy import deepcopy
import hashlib
import json
import math
from pathlib import Path
import re
import statistics
import sys

TASK = Path(__file__).resolve().parents[1]
OUT = Path(__file__).resolve().parent
ROOT = TASK.parents[3]
HEADS = {'reference': '28e402821469655598c6a84bc415d8ea04da97c2', 'candidate': 'c105da61b2b490546f01c9d67703bfb405a2a44f'}
PROJECTS = {'reference': ROOT/'.worktrees/silo9-issue-10', 'candidate': ROOT/'.worktrees/silo9-issue-18'}
Z = [-10, -16, -22, -32, -36, -42, -32, -12, 7]
ROUTE = [[0, 0, z] for z in Z]
SPAWNS = {'sentinel_1':[3,0,-20], 'crawler_1':[-5,0,-28], 'sentinel_2':[-3,0,-45], 'crawler_2':[3,0,-51], 'sentinel_3':[0,0,-66], 'crawler_3':[-3,0,-70]}
LIGHTS = {'ceiling_refuge','ceiling_decontamination','ceiling_maintenance','ceiling_archives','ceiling_core_entry','ceiling_core_end','reactor','alarm_maintenance','alarm_archives'}


def require(value, message):
    if not value:
        raise ValueError(message)


def number(value):
    return type(value) in (int, float) and math.isfinite(value)


def vector(value):
    return type(value) is list and len(value) == 3 and all(number(x) for x in value)


def near_vector(a, b, tolerance=.03):
    return vector(a) and vector(b) and math.dist(a,b) <= tolerance


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read(path):
    return json.loads(path.read_text())


def quantile(values, fraction):
    require(values and all(number(x) and x > 0 for x in values), 'positive finite raw intervals required')
    return sorted(values)[min(math.floor(len(values)*fraction),len(values)-1)]


def distribution(values):
    return {'median':statistics.median(values),'min':min(values),'max':max(values),'values':values}


def lamp(actual, low):
    require(type(actual) is dict and actual['visible'] is True and actual['intent'] is True, 'lamp actual visibility/intent')
    require(all(number(actual[k]) and actual[k] > 0 for k in ['energy','range']) and type(actual['mask']) is int and actual['mask'] & 1, 'lamp emission/mask')
    require(actual['shadow'] is (not low) and vector(actual['position']), 'lamp quality or position')


def fixture(report):
    terminal = report['terminal']
    return {'robots':[{k:r[k] for k in ['id','position_before','yaw_before','health_before','collision_before','damage']} for r in sorted(terminal['robots'],key=lambda r:r['id'])], 'crate':{k:terminal['crate_shot'][k] for k in ['accepted','weapon','ammo_before','ammo_after','energy_before','energy_after','energy_cost','impact','ray_from','ray_to','target_position','target_half_size']}, 'preparation_start':terminal['preparation_start']}


def validate_report(report, side, quality):
    low = quality == 'low'
    require(report['schema'] == 3 and report['mode'] == 'perf' and report['performance_valid'] is True and report['failures'] == [], 'successful perf schema')
    require(report['low_quality'] is low and report['require_lighting'] is True and report['lighting_available'] is True and report['circuits_available'] is True and report['flashlight_requested'] is True, 'observed requested capabilities')
    require(report['display_driver'].lower() == 'x11' and report['rendering_method'] == 'gl_compatibility' and 'llvmpipe' in report['renderer'].lower() and report['resolution'] == [1280,720], 'render environment')
    require(report['engine']['major'] == 4 and report['engine']['minor'] == 7 and report['engine']['patch'] == 2, 'engine version')
    require(report['waypoint_positions'] == ROUTE and report['waypoints_completed'] == 9 and number(report['travelled_m']) and abs(report['travelled_m']-92.4334392547607) < .001, 'complete physical route')
    intervals = report['frame_intervals_ms']
    q = {f'p{int(p*100)}':quantile(intervals,p) for p in [.5,.95,.99]}
    require(type(report['frames_drawn']) is int and report['frames_drawn'] == len(intervals)+1, 'drawn frames vs intervals')
    stages = report['frame_stages']
    observations = report['perf_flashlight_samples']
    require(len(stages) == len(intervals) and len(observations) == len(intervals)+1, 'raw stage/sample count')
    ticks = [r['usec'] for r in observations]
    require(all(type(t) is int and t > 0 for t in ticks), 'integer timestamps')
    require(all(abs((b-a)/1000-ms) < 1e-7 for a,b,ms in zip(ticks,ticks[1:],intervals)), 'each raw interval reconstructed from ticks')
    require([r['stage'] for r in observations[1:]] == stages, 'raw stage linkage')
    walk_order = []
    last = None
    for stage in stages:
        require(type(stage) is str and stage.startswith(('walk_','settle_')), 'unknown measured stage')
        if stage.startswith('walk_') and stage != last:
            values = re.findall(r'-?\d+(?:\.\d+)?',stage)
            require(len(values) in (1,3), 'walk stage coordinate format')
            walk_order.append(float(values[-1])); last = stage
    require(walk_order == Z, 'ordered nine measured walking stages')
    terminal = report['terminal']
    require(terminal['schema'] == 1 and terminal['variant'] == side and terminal['fixture'] is True, 'terminal fixture identity')
    require(near_vector(terminal['preparation_start'],[0,0,7]), 'normal spawn restored before measurement')
    robots = terminal['robots']
    require(len(robots) == 6 and {r['id'] for r in robots} == set(SPAWNS) and len({r['instance'] for r in robots}) == 6, 'six unique real robots')
    for r in robots:
        require(type(r['instance']) is int and r['instance'] > 0 and near_vector(r['position_before'],SPAWNS[r['id']]), 'robot instance/actual spawn')
        require(all(number(r[k]) for k in ['health_before','health_after','damage']) and r['health_before'] == (35 if r['id'].startswith('crawler') else 65) and r['health_after'] == 0 and r['damage'] == 1000, 'actual death health/damage')
        require(type(r['collision_before']) is int and type(r['collision_after']) is int and r['collision_before'] == 1 and r['collision_after'] == 0 and r['physics_after'] is False and r['defeated'] is True, 'death collision/state')
        require(near_vector(r['position_after'],r['position_before']) and number(r['yaw_before']) and number(r['yaw_after']) and abs(math.remainder(r['yaw_before']-r['yaw_after'],2*math.pi)) < .01, 'actual death pose stable')
    shot = terminal['crate_shot']
    require(shot['accepted'] is True and shot['weapon'] == 0 and shot['impact_visible'] is True and type(shot['target_before']) is int and shot['target_before'] > 0, 'real crate shot')
    require(all(type(shot[k]) is int for k in ['weapon','ammo_before','ammo_after']) and all(number(shot[k]) for k in ['energy_before','energy_after','energy_cost']) and shot['ammo_before'] == 12 and shot['ammo_after'] == 11 and shot['energy_before'] == shot['energy_after'] == 100 and shot['energy_cost'] == 0, 'crate shot inventory')
    require(all(vector(shot[k]) for k in ['ray_from','ray_to','impact','target_position','target_half_size']), 'shot finite vectors')
    require(near_vector(shot['target_position'],[4,.4125,-12]) and near_vector(shot['target_half_size'],[.825,.4125,.75]), 'authored crate collider')
    start_ray,end_ray,impact = shot['ray_from'],shot['ray_to'],shot['impact']
    require(abs(math.dist(start_ray,impact)+math.dist(impact,end_ray)-math.dist(start_ray,end_ray)) < .03, 'impact on actual ray')
    require(all(abs(v-c) <= h+.03 for v,c,h in zip(impact,shot['target_position'],shot['target_half_size'])), 'impact inside actual crate collider')
    for state in [terminal['before_warmup'],terminal['before_measure']]:
        require(len(state['defeated']) == 6 and set(state['defeated']) == set(SPAWNS) and state['live_ids'] == [], 'no living/missing robots before measure')
        require(type(state['trace_count']) is int and state['trace_count'] == (6 if side == 'candidate' else 0), 'terminal trace count')
        crate = state['crate']; broken = side == 'candidate'
        require(type(crate['collision']) is int and type(crate['panels']) is int and crate['broken'] is broken and crate['intact'] is (not broken) and crate['collision'] == (0 if broken else 1) and crate['panels'] == (3 if broken else 0), 'crate outcome appropriate to version')
        require(near_vector(state['position'],terminal['preparation_start']) and near_vector(state['velocity'],[0,0,0]) and type(state['casings']) is int and state['casings'] == 0, 'stationary effect-free start')
        require(all(state['effects'][k] is False for k in ['impact','muzzle','beam','light']) and number(state['effects']['remaining']) and state['effects']['remaining'] == 0, 'no effects at measurement boundaries')
        lamp(state['flashlight'],low)
    begin,end = terminal['measurement_start_usec'],terminal['measurement_end_usec']
    require(all(type(x) is int and x > 0 for x in [shot['usec'],terminal['before_warmup']['usec'],terminal['before_measure']['usec'],begin,end]), 'integer boundary timestamps')
    require(shot['usec'] < terminal['before_warmup']['usec'] and terminal['before_measure']['usec']-terminal['before_warmup']['usec'] >= 2000000, 'preparation then >=2s warmup')
    require(terminal['before_measure']['usec'] <= begin <= ticks[0] < ticks[-1] <= end, 'timing boundaries enclose callbacks')
    require(abs((end-begin)/1000-math.fsum(intervals)) <= max(intervals)*2, 'clock agrees with interval sum')
    final = report['final_observation']
    require(report['perf_flashlight_before_warmup']['usec'] < ticks[0] < ticks[-1] <= final['usec'], 'lamp before/during/after chronology')
    for observation in [report['perf_flashlight_before_warmup'],*observations,final]: lamp(observation['flashlight'],low)
    require(len({tuple(r['flashlight']['position']) for r in observations}) > 9, 'lamp moves through physical route')
    require(abs(final['scale_3d']-(.67 if low else 1)) < 1e-5 and final['fov'] == 76 and final['circuits'] == {'maintenance':True,'archives':True} and final['live_enemies'] == [], 'final projection/settings')
    require({r['id'] for r in final['lights']} == LIGHTS and not any(r['shadow'] for r in final['lights']), 'authored world lights')
    traces = [r for r in final['mesh_materials'] if r['path'].startswith('Remains_')]
    if side == 'candidate':
        require(len(traces) == 18, 'eighteen actual trace meshes in final scene')
        require(Counter(r['path'].split('/')[0].removeprefix('Remains_') for r in traces) == {key:3 for key in SPAWNS}, 'three actual meshes per robot')
        require(len({m for r in traces for m in r['material_ids']}) == 3 and all(r['visible'] and len(r['material_ids']) == 1 for r in traces), 'three shared materials, visible single-surface trace meshes')
        require(all(near_vector(r['position'],SPAWNS[r['path'].split('/')[0].removeprefix('Remains_')]) for r in traces), 'final trace actual death locations')
    else:
        require(traces == [], 'reference has no invented traces')
    for key,value in q.items(): require(number(report[f'frame_{key}_ms']) and abs(value-report[f'frame_{key}_ms']) < 1e-7, 'independent '+key)
    for field in ['draw_calls_max','nodes_max','resources_max']:
        require(type(report[field]) is int and report[field] > 0, 'observed positive '+field)
    require(number(report['health']) and type(report['ammo']) is int and type(report['phase']) is int and report['health'] == 100 and report['ammo'] == 11 and report['phase'] == 0 and report['ending'] == '' and report['commands'] == [], 'no gameplay/interaction work in measured fixture')
    return {**q,'samples':len(intervals),'frames_drawn':report['frames_drawn'],'interval_sum_ms':math.fsum(intervals),'measured_elapsed_ms':(end-begin)/1000,'warmup_ms':(terminal['before_measure']['usec']-terminal['before_warmup']['usec'])/1000,'distance_m':report['travelled_m'],'draw_calls_max':report['draw_calls_max'],'nodes_max':report['nodes_max'],'resources_max':report['resources_max'],'stage_counts':dict(Counter(stages)),'actual_trace_meshes':len(traces)}


def artifact_checks(manifest, folder, side, quality, frozen):
    expected = frozen['projects'][side]
    require(manifest['head'] == expected['head'] == HEADS[side], 'frozen HEAD')
    require(manifest['project'] == str(PROJECTS[side]), 'actual project path')
    require(manifest['source_before'] == manifest['source_after'] == expected['source'] and manifest['source_unchanged'] is True, 'full source frozen before/after')
    artifacts = {'engine':frozen['engine'],'wrapper':frozen['artifacts']['prove_sector_power.py'],'probe':frozen['artifacts']['probe_sector_power.gd'],'selfcheck':frozen['artifacts']['selfcheck_sector_power.py'],'input_helper':expected['source']['tools/x11_input.py']}
    require(manifest['artifacts_before'] == manifest['artifacts_after'] == artifacts and manifest['probe_sha256'] == artifacts['probe'], 'independent proof copies frozen')
    require(manifest['exit_code'] == 0 and manifest['validation_errors'] == [], 'successful engine manifest')
    command = manifest['command']
    require(command[0] == str(ROOT/'.tools/Godot_v4.7.2-stable_linux.x86_64') and command[command.index('--path')+1] == str(PROJECTS[side]), 'actual engine/project invocation')
    require(command[command.index('--script')+1] == str(TASK/'proof-tools/probe_sector_power.gd'), 'actual independent probe copy invocation')
    require(all(flag in command for flag in ['--probe-mode=perf','--require-circuits','--require-lighting','--flashlight-on','--terminal-variant='+side,'--proof-output='+str(folder)]), 'independent command scenario request')
    require(('--low' in command) is (quality == 'low') and manifest['flashlight_requested'] is True, 'independent quality/lamp request')
    require(command[command.index('--display-driver')+1] == 'x11' and command[command.index('--rendering-method')+1] == 'gl_compatibility' and command[command.index('--audio-driver')+1] == 'Dummy' and command[command.index('--resolution')+1] == '1280x720', 'actual renderer/resolution/audio invocation')
    log = (folder/'engine.log').read_text()
    require(not re.search(r'(?:SCRIPT ERROR:|ERROR:|Parse Error|Segmentation fault)',log), 'no engine error')
    require('SECTOR_PROOF mode=perf' in log and 'failures=0' in log, 'engine completed actual proof')
    return re.findall(r'^WARNING:.*',log,re.M)


def audit_host(member):
    samples = member['host_samples']
    require(member['unexpected_processes'] == [] and type(member['wrapper_pid']) is int and member['wrapper_pid'] > 0, 'host process ownership')
    require(len(samples) >= 3 and samples[0]['processes'] == samples[-1]['processes'] == [], 'empty host before/after')
    times = [s['unix'] for s in samples]
    require(all(number(t) for t in times) and member['start'] <= times[0] < times[-1] <= member['end'], 'host sample window')
    gaps = [b-a for a,b in zip(times,times[1:])]
    require(all(0 < gap <= 3 for gap in gaps), 'host sampling missing or interval exceeds 3 seconds')
    seen = 0
    for sample in samples:
        require(type(sample['logical_cpus']) is int and sample['logical_cpus'] > 0 and len(sample['load_average']) == 3 and all(number(x) and x >= 0 for x in sample['load_average']), 'host CPU/load observations')
        require(len(sample['processes']) <= 1, 'at most one sampled runtime')
        for process in sample['processes']:
            require('godot' in process['name'].lower() and process['parent'] == member['wrapper_pid'], 'only wrapper child runtime sampled')
            seen += 1
    require(seen > 0, 'actual runtime observed by host sampler')
    return {'samples':len(samples),'engine_samples':seen,'max_gap_seconds':max(gaps),'load_1m':distribution([s['load_average'][0] for s in samples]),'logical_cpus':samples[0]['logical_cpus']}


def audit():
    frozen = read(TASK/'perf-freeze.json')
    errors,rows,pairs,fixtures = [],[],[],{}
    def check(value,label):
        if not value: errors.append(label)
    check(digest(TASK/'run_perf_pair.py') == frozen['runner'],'live pair runner matches freeze')
    check(digest(ROOT/'.tools/Godot_v4.7.2-stable_linux.x86_64') == frozen['engine'],'live engine matches freeze')
    for name,sha in frozen['artifacts'].items(): check(digest(TASK/'proof-tools'/name)==sha,'live independent tool copy '+name)
    for side in HEADS:
        check(frozen['projects'][side]['head'] == HEADS[side],side+' freeze HEAD')
        for name,sha in frozen['projects'][side]['source'].items():
            path = PROJECTS[side]/name
            check(path.is_file() and digest(path)==sha,side+' live source '+name)
    perf = TASK/'perf'
    expected = {f'{quality}-{index}-{side}' for quality in ['normal','low'] for index in range(1,6) for side in HEADS}
    check({p.parent.name for p in perf.glob('*/journey.json')} == expected,'exact 20-run inventory')
    for quality in ['normal','low']:
        for index in range(1,6):
            label = f'{quality}-{index}'
            try:
                pair = read(perf/(label+'-pair.json'))
                order = ['reference','candidate'] if index%2 else ['candidate','reference']
                require([r['side'] for r in pair] == order,'alternating members')
                require(pair[0]['end'] <= pair[1]['start'],'pair members serialized')
                pairs.append({'label':label,'start':pair[0]['start'],'end':pair[-1]['end']})
                observed = {}
                for member in pair:
                    side = member['side'];name = label+'-'+side;folder = perf/name
                    manifest = read(folder/'manifest.json');report = read(folder/'journey.json')
                    require(member['exit_code'] == 0,'wrapper successful')
                    require(member['start'] <= manifest['started_unix'] < manifest['ended_unix'] <= member['end'],'engine run bounded by wrapper')
                    command = member['command']
                    require(command[:2] == ['python3',str(TASK/'proof-tools/prove_sector_power.py')] and command[command.index('--terminal-variant')+1] == side and command[command.index('--output')+1] == str(folder),'pair invokes real wrapper copy')
                    warnings = artifact_checks(manifest,folder,side,quality,frozen)
                    host = audit_host(member)
                    values = validate_report(report,side,quality)
                    rows.append({'name':name,'quality':quality,'pair':index,'side':side,**values,'warnings':warnings,'host':host,'started_unix':manifest['started_unix'],'ended_unix':manifest['ended_unix']})
                    observed[side] = fixture(report)
                    if side in fixtures: require(fixtures[side] == observed[side],'same fixture across all runs')
                    else: fixtures[side] = observed[side]
                require(observed['reference'] == observed['candidate'],'equal observed interversion fixture')
            except (OSError,ValueError,KeyError,TypeError,IndexError) as error: errors.append(label+': '+str(error))
    check(len(rows)==20,'twenty runs audited')
    check(all(a['end'] <= b['start'] for a,b in zip(pairs,pairs[1:])),'normal then low, all pairs globally serialized')
    groups = {}
    for quality in ['normal','low']:
        members = [r for r in rows if r['quality']==quality]
        if len(members)!=10: continue
        group = {side:{metric:distribution([r[metric] for r in members if r['side']==side]) for metric in ['p50','p95','p99','samples','frames_drawn','interval_sum_ms','draw_calls_max','nodes_max','resources_max']} for side in HEADS}
        group['paired_candidate_minus_reference'] = {}
        for metric in ['p50','p95','p99']:
            delta=[];percent=[]
            for index in range(1,6):
                values = {r['side']:r[metric] for r in members if r['pair']==index}
                value = values['candidate']-values['reference'];delta.append(value);percent.append(100*value/values['reference'])
            group['paired_candidate_minus_reference'][metric] = {'ms':distribution(delta),'percent':distribution(percent)}
        groups[quality] = group
    result = {'passed':not errors,'errors':errors,'runs':rows,'groups':groups,'pair_windows':pairs,'quantiles':'Per run sorted[floor(n*p)] capped at n-1; median/range of five run quantiles; differences within each pair','limits':['No engine run by auditor','No gain/regression verdict before separate profile and host-evidence audit','Linux llvmpipe source projects, 1280x720, flashlight ON only','Callback intervals are not GPU times','Draw/node/resource maxima observed by probe; no per-frame draw series to recompute maxima independently','Terminal death and crate preparation excluded; physical route excludes live combat','External concurrency requires host evidence beyond pair timestamps']}
    (OUT/'campaign-audit.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps({'passed':not errors,'errors':errors,'runs':len(rows),'groups':groups},indent=2))
    return bool(errors)


if __name__ == '__main__':
    raise SystemExit(audit())
