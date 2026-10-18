from copy import deepcopy
import json
from pathlib import Path
import statistics
import sys

IDS = {'sentinel_1', 'crawler_1', 'sentinel_2', 'crawler_2', 'sentinel_3', 'crawler_3'}

def require(value, label):
    if not value:
        raise ValueError(label)

def validate(data):
    require(data.get('failures') == 0, 'probe assertions failed or run incomplete')
    require(data['warmup_reloads'] == 2 and data['measured_reloads'] == 20, 'repeat count')
    require(len(data['samples']) == 23, 'all prepared, warmup and measured samples present')
    require(set(data['expected_poses']) == IDS, 'expected poses cover six authored robots')
    require(len(data['actions']) == 7, 'one crate shot and six enemy actions')
    shot = data['actions'][0]
    require(shot['kind'] == 'crate_player_fire' and shot['accepted'] and shot['ammo_before'] - shot['ammo_after'] == 1, 'accepted real shot')
    require({a['id'] for a in data['actions'][1:] if a['kind'] == 'enemy_receive_hit'} == IDS, 'six real enemy hits')
    mesh_ids = set(data['samples'][0]['meshes'])
    material_ids = set(data['samples'][0]['materials'])
    player_ids, world_ids = set(), set()
    for index, sample in enumerate(data['samples']):
        require(sample['stage'] == ('prepared' if index == 0 else 'warmup' if index <= 2 else 'measured'), 'stage ordering')
        require(sample['cycle'] == index - 1 if index else sample['cycle'] == -1, 'cycle ordering')
        require(sample['player_id'] not in player_ids and sample['world_id'] not in world_ids, 'fresh actors per reconstruction')
        player_ids.add(sample['player_id'])
        world_ids.add(sample['world_id'])
        require(sample['old_player_freed'] and sample['old_world_freed'], 'old actors released after settle')
        require(sample['enemies'] == 0 and len(sample['traces']) == 6 and {t['id'] for t in sample['traces']} == IDS, 'six traces and no enemy')
        require(sample['visible_remains_instances'] == 19, 'nineteen visible remains instances')
        require(len(sample['meshes']) == 6 and set(sample['meshes']) == mesh_ids, 'same six shared robot meshes')
        require(len(sample['materials']) == 3 and set(sample['materials']) == material_ids, 'same three shared robot materials')
        require(sample['meshes'] == data['samples'][0]['meshes'], 'mesh topology and byte counts stable')
        for mesh in sample['meshes'].values():
            require(mesh['class'] == 'ArrayMesh' and mesh['surfaces'] == 1 and mesh['vertices'] > 0 and mesh['indices'] > 0, 'valid single-surface robot mesh')
        for trace in sample['traces']:
            expected = data['expected_poses'][trace['id']]
            require(len(trace['position']) == len(expected['position']) == 3 and all(abs(a-b) < 0.0001 for a,b in zip(trace['position'], expected['position'])) and abs(trace['yaw'] - expected['yaw']) < 0.0001, 'actual moved death pose')
            require(not trace['processing'] and trace['collision_objects'] == trace['lights'] == trace['timers'] == 0, 'inert trace subtree')
            require(len(trace['geometry']) == 3, 'three meshes per trace')
            for geometry in trace['geometry']:
                require(geometry['visible'] and geometry['mesh'] in mesh_ids and geometry['material'] in material_ids and geometry['shadow'] == 0 and geometry['range'] == 45, 'visible shared trace geometry')
        crate = sample['crate']
        require(crate['visible'] and crate['panels'] == 3 and crate['collision_layer'] == crate['collision_mask'] == 0, 'broken nonblocking crate')
        require(crate['mesh_class'] == 'BoxMesh' and crate['shared_with_world_box'] and crate['material_shared_with_world'] and crate['shadow'] == 0 and crate['range'] == 45, 'crate shares world resources')
        snapshot = sample['snapshot']
        require(snapshot['schema'] == 4 and snapshot['crate_broken'] and set(snapshot['defeated']) == set(snapshot['death_poses']) == IDS, 'canonical state survives reconstruction')
    measured = [s for s in data['samples'] if s['stage'] == 'measured']
    timings = {field: {'median': statistics.median(s[field] for s in measured), 'min': min(s[field] for s in measured), 'max': max(s[field] for s in measured)} for field in ['save_call_us','load_call_us','load_plus_settle_us']}
    counters = {field: {'first': measured[0]['counters'][field], 'last': measured[-1]['counters'][field], 'min': min(s['counters'][field] for s in measured), 'max': max(s['counters'][field] for s in measured), 'delta': measured[-1]['counters'][field]-measured[0]['counters'][field]} for field in measured[0]['counters']}
    return {'verdict': 'PASS structural resource sharing', 'global_resource_count_stable': counters['resources']['min'] == counters['resources']['max'], 'global_resource_growth_observed': counters['resources']['delta'] > 0, 'measured_reloads': len(measured), 'shared_robot_meshes': len(mesh_ids), 'shared_robot_materials': len(material_ids), 'timings_us_diagnostic_only': timings, 'global_counters_observed_not_exempted': counters, 'after_teardown_counters': data['after_teardown_counters']}

def negative_controls(data):
    cases = {}
    candidate = deepcopy(data); candidate['samples'][-1]['visible_remains_instances'] = 20; cases['extra_instance'] = candidate
    candidate = deepcopy(data); candidate['samples'][-1]['meshes']['new_mesh'] = next(iter(candidate['samples'][-1]['meshes'].values())); cases['mesh_growth'] = candidate
    candidate = deepcopy(data); candidate['samples'][-1]['materials']['new_material'] = 'StandardMaterial3D'; cases['material_growth'] = candidate
    candidate = deepcopy(data); candidate['samples'][-1]['player_id'] = candidate['samples'][0]['player_id']; cases['actors_not_reconstructed'] = candidate
    candidate = deepcopy(data); candidate['samples'][-1]['traces'][0]['position'][0] += 1; cases['wrong_death_pose'] = candidate
    candidate = deepcopy(data); candidate['samples'][-1]['crate']['collision_layer'] = 1; cases['blocking_crate'] = candidate
    candidate = deepcopy(data); candidate['samples'][-1]['traces'][0]['processing'] = True; cases['live_trace'] = candidate
    candidate = deepcopy(data); candidate['samples'].pop(); cases['incomplete_run'] = candidate
    caught = {}
    for name, candidate in cases.items():
        try:
            validate(candidate)
        except ValueError as error:
            caught[name] = str(error)
        else:
            raise AssertionError('negative control escaped: ' + name)
    return caught

if __name__ == '__main__':
    data = json.loads(Path(sys.argv[1]).read_text())
    print(json.dumps({'validation': validate(data), 'negative_controls': negative_controls(data)}, indent=2))
