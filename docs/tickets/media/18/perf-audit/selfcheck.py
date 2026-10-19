"""Synthetic validator tests only: these do not execute or certify a game."""
from copy import deepcopy
import json
from pathlib import Path
from audit_campaign import validate_report, quantile, SPAWNS, ROUTE, LIGHTS, Z, audit_host


def synthetic(side, low=False):
    def lamp(pos): return {'visible':True,'intent':True,'energy':2.5,'range':14,'mask':1,'shadow':not low,'position':pos}
    stages = [f'walk_(0.0, 0.0, {float(z)})' for z in Z for _ in range(2)]
    samples = [{'stage':s,'usec':3000000+i*1000000,'flashlight':lamp([0,1,-i])} for i,s in enumerate(stages)]
    boundary = {'defeated':list(SPAWNS),'live_ids':[],'trace_count':6 if side=='candidate' else 0,'crate':{'broken':side=='candidate','intact':side=='reference','panels':3 if side=='candidate' else 0,'collision':0 if side=='candidate' else 1},'flashlight':lamp([0,1,7]),'position':[0,0,7],'velocity':[0,0,0],'casings':0,'effects':{'impact':False,'muzzle':False,'beam':False,'light':False,'remaining':0},'usec':200000}
    end = deepcopy(boundary);end['usec']=2200000
    robots = [{'id':key,'instance':i+1,'position_before':pos,'position_after':pos,'yaw_before':0,'yaw_after':0,'health_before':35 if key.startswith('crawler') else 65,'health_after':0,'damage':1000,'collision_before':1,'collision_after':0,'physics_after':False,'defeated':True} for i,(key,pos) in enumerate(SPAWNS.items())]
    meshes = [] if side=='reference' else [{'path':f'Remains_{key}/mesh{i}','position':pos,'visible':True,'material_ids':[i+1]} for key,pos in SPAWNS.items() for i in range(3)]
    return {'schema':3,'mode':'perf','performance_valid':True,'failures':[],'low_quality':low,'require_lighting':True,'lighting_available':True,'circuits_available':True,'flashlight_requested':True,'display_driver':'x11','rendering_method':'gl_compatibility','renderer':'llvmpipe synthetic','resolution':[1280,720],'engine':{'major':4,'minor':7,'patch':2},'waypoint_positions':ROUTE,'waypoints_completed':9,'travelled_m':92.4334392547607,'frame_intervals_ms':[1000]*17,'frames_drawn':18,'frame_stages':stages[1:],'perf_flashlight_samples':samples,'terminal':{'schema':1,'variant':side,'fixture':True,'preparation_start':[0,0,7],'robots':robots,'crate_shot':{'accepted':True,'weapon':0,'impact_visible':True,'target_before':100,'ammo_before':12,'ammo_after':11,'energy_before':100,'energy_after':100,'energy_cost':0,'ray_from':[4,.4125,-9],'ray_to':[4,.4125,-14],'impact':[4,.4125,-11.25],'target_position':[4,.4125,-12],'target_half_size':[.825,.4125,.75],'usec':100000},'before_warmup':boundary,'before_measure':end,'measurement_start_usec':3000000,'measurement_end_usec':20000000},'perf_flashlight_before_warmup':{'usec':200001,'flashlight':lamp([0,1,7])},'final_observation':{'usec':20000001,'flashlight':lamp([0,1,7]),'scale_3d':.67 if low else 1,'fov':76,'circuits':{'maintenance':True,'archives':True},'live_enemies':[],'lights':[{'id':key,'shadow':False} for key in LIGHTS],'mesh_materials':meshes},'frame_p50_ms':1000,'frame_p95_ms':1000,'frame_p99_ms':1000,'draw_calls_max':45,'nodes_max':600,'resources_max':105,'health':100,'ammo':11,'phase':0,'ending':'','commands':[]}


def main():
    passed=[]
    assert quantile([5,1,3,2,4],.5)==3
    assert quantile(list(range(1,101)),.95)==96
    for side in ['reference','candidate']:
        for low in [False,True]:
            validate_report(synthetic(side,low),side,'low' if low else 'normal');passed.append(f'synthetic-positive-{side}-{low}')
    cases={}
    def mutate(name,callback):
        data=synthetic('candidate');callback(data);cases[name]=data
    mutate('quantile',lambda d:d.update(frame_p95_ms=1))
    mutate('frame_count',lambda d:d.update(frames_drawn=17))
    mutate('raw_timestamp',lambda d:d['perf_flashlight_samples'][5].update(usec=0))
    mutate('nan',lambda d:d['frame_intervals_ms'].__setitem__(3,float('nan')))
    mutate('lamp_off',lambda d:d['perf_flashlight_samples'][3]['flashlight'].update(visible=False))
    mutate('missing_station',lambda d:d.update(waypoints_completed=8))
    mutate('short_warmup',lambda d:d['terminal']['before_measure'].update(usec=2199999))
    mutate('transient_effect',lambda d:d['terminal']['before_measure']['effects'].update(beam=True))
    mutate('robot_collision',lambda d:d['terminal']['robots'][0].update(collision_after=1))
    mutate('fake_damage_bool',lambda d:d['terminal']['robots'][0].update(health_after=False))
    mutate('crate_miss',lambda d:d['terminal']['crate_shot'].update(impact=[30,0,0]))
    mutate('missing_trace',lambda d:d['final_observation']['mesh_materials'].pop())
    mutate('new_material',lambda d:d['final_observation']['mesh_materials'][0].update(material_ids=[999]))
    for name,data in cases.items():
        try: validate_report(data,'candidate','normal')
        except (ValueError,KeyError,TypeError): passed.append('reject-'+name)
        else: raise AssertionError('mutant escaped: '+name)
    host={'wrapper_pid':10,'start':0,'end':3,'unexpected_processes':[],'host_samples':[{'unix':.1,'logical_cpus':8,'load_average':[1,1,1],'processes':[]},{'unix':1.1,'logical_cpus':8,'load_average':[1,1,1],'processes':[{'pid':11,'parent':10,'name':'Godot'}]},{'unix':2.1,'logical_cpus':8,'load_average':[1,1,1],'processes':[]}]}
    audit_host(host);passed.append('synthetic-positive-host')
    for name,update in [('foreign_parent',{'parent':99}),('profiler',{'name':'perf'})]:
        invalid=deepcopy(host);invalid['host_samples'][1]['processes'][0].update(update)
        try:audit_host(invalid)
        except ValueError:passed.append('reject-'+name)
        else:raise AssertionError('host mutant escaped')
    result={'passed':True,'checks':len(passed),'details':passed,'scope':'Synthetic audit-validator controls only; no engine and no campaign verdict'}
    (Path(__file__).parent/'selfcheck.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))


if __name__=='__main__':main()
