"""Independent audit of the four exploratory cost runs, not a statistical campaign."""
import argparse,hashlib,json,math,re,statistics
from pathlib import Path
parser=argparse.ArgumentParser();parser.add_argument('--confirm',action='store_true');args=parser.parse_args()
p=Path(__file__).resolve().parents[1];errors=[];checks=0;rows=[];times=[]
def check(v,s):
 global checks
 checks+=1
 if not v:errors.append(s)
sha=json.loads((p/'cost-proof-tools/SHA256.json').read_text());primary=json.loads((p/'perf-audit/audit.json').read_text())
expected={'engine':primary['artifact_hashes']['engine'],'probe':sha['probe_sector_power.gd'],'wrapper':sha['prove_sector_power.py']}
for name,d in sha.items():check(hashlib.sha256((p/'cost-proof-tools'/name).read_bytes()).hexdigest()==d,'tool hash '+name)
runs=json.loads((p/'cost-final-campaign.json').read_text())
if args.confirm:
 runs=[]
 for i in range(1,6):
  pair=json.loads((p/'cost-confirm'/f'low-{i}-pair.json').read_text())
  check([x['side'] for x in pair]==(['baseline','candidate'] if i%2 else ['candidate','baseline']),f'pair {i} order')
  for x in pair:runs.append({'name':f'cost-confirm/low-{i}-'+x['side'],'exit':x['exit_code']})
for run in runs:
 name=run['name'];side=name.split('-')[-1];low='low-' in name;folder=p/name
 m=json.loads((folder/'manifest.json').read_text());j=json.loads((folder/'journey.json').read_text());log=(folder/'engine.log').read_text()
 def c(v,s):check(v,name+': '+s)
 c(run['exit']==m['exit_code']==0 and not m['validation_errors'] and not j['failures'],'clean exits')
 c(not re.search(r'SCRIPT ERROR:|ERROR:|Parse Error|Segmentation fault',log),'log')
 c(m['head']==primary['source_heads'][side],'head')
 c(m['source_unchanged'] and m['source_before']==m['source_after'],'source stable')
 original=json.loads((p/'perf'/('normal-1-'+side)/'manifest.json').read_text())
 c(m['source_before']==original['source_before'],'source same primary campaign')
 c(m['artifacts_before']==m['artifacts_after']==expected,'artifact hashes')
 c(j['mode']=='lighting-perf' and j['scene_inspection'] is True and j['performance_valid'] is False and j['travelled_m']==0,'stationary experiment explicit')
 c(j['low_quality'] is low and j['renderer']=='llvmpipe (LLVM 21.1.8, 256 bits)' and j['display_driver']=='X11' and j['rendering_method']=='gl_compatibility' and j['resolution']==[1280,720],'render mode')
 labels=['core_off','core_on','maintenance_alarm_off','maintenance_alarm_on'];c([x['label'] for x in j['cost_windows']]==labels,'four windows')
 c([x['label'] for x in j['lighting_samples']]==labels,'four observations');c(not list(folder.glob('*.png')) and not any(x.get('png') for x in j['lighting_samples']),'no captures')
 previous=0
 for w,r in zip(j['cost_windows'],j['lighting_samples']):
  label=w['label'];before=r['observation'];after=w['observation_after'];v=w['intervals_ms'];start=w['measurement_start_usec'];end=w['measurement_end_usec'];enabled=label.endswith('_on');maint=label.startswith('maintenance')
  c(all(type(t) is int and t>0 for t in [start,end,before['usec'],after['usec']]),label+' integer ticks')
  c(previous<before['usec']<=start<end<=after['usec'],label+' enclosed ordered clocks');previous=after['usec']
  c(all(type(x) in (int,float) and math.isfinite(x) and x>0 for x in v) and len(v)>=20,label+' samples')
  c(abs(math.fsum(v)*1000-(end-start))<.01 and 6000000<=end-start<6000000+v[-1]*1000,label+' six-second boundary')
  c(w['frames_drawn']==len(v)+1,label+' rendered frames')
  c(all(before[k]==after[k] for k in ['camera_position','camera_rotation','fov','scale_3d','energy','nodes','resources','mesh_materials','materials','live_enemies','circuits','alarms','lights','flashlight']),label+' stationary unchanged observations')
  for o in [before,after]:
   c(abs(o['scale_3d']-(.67 if low else 1))<1e-5 and o['energy']==0 and len(o['live_enemies'])>0,label+' quality live actor fixture')
   c(o['circuits']=={'maintenance':not maint,'archives':True},label+' circuits')
   if maint:c(o['alarms']['maintenance']>0,label+' alarm held')
   if side=='candidate':
    flash=o['flashlight'];c(flash['visible']==enabled and flash['shadow']==(not low),label+' flashlight state/shadow')
    c(not any(x['shadow'] for x in o['lights']),label+' fixed shadow budget')
    if enabled:c(flash['energy']>0 and flash['range']>0 and flash['mask']&1,label+' flashlight contribution enabled')
    if maint:
     lamp=next(x for x in o['lights'] if x['id']=='alarm_maintenance');c(lamp['visible'] and lamp['energy']>0 and lamp['mask']&1,label+' emitting alarm')
   else:c(o['flashlight'] is None,label+' baseline no flashlight')
  sv=sorted(v);rows.append({'run':name,'window':label,'intervals':len(v),'frames':w['frames_drawn'],'duration_ms':(end-start)/1000,'p50':sv[int(len(sv)*.5)],'p95':sv[int(len(sv)*.95)],'p99':sv[int(len(sv)*.99)],'draw_calls_max':w['draw_calls_max'],'nodes_max':w['nodes_max'],'resources_max':w['resources_max']})
 times.append((m['started_unix'],m['ended_unix'],name))
for a,b in zip(times,times[1:]):check(a[1]<b[0],'serialized runs '+a[2]+' '+b[2])
summary={}
if args.confirm:
 for label in ['core_off','core_on','maintenance_alarm_off','maintenance_alarm_on']:
  summary[label]={}
  for metric in ['p50','p95','p99']:
   groups={side:[next(r[metric] for r in rows if r['run']==f'cost-confirm/low-{i}-{side}' and r['window']==label) for i in range(1,6)] for side in ['baseline','candidate']}
   b,c=groups['baseline'],groups['candidate'];delta=[y-x for x,y in zip(b,c)]
   summary[label][metric]={'baseline':{'median':statistics.median(b),'range':[min(b),max(b)]},'candidate':{'median':statistics.median(c),'range':[min(c),max(c)]},'median_difference_percent':(statistics.median(c)/statistics.median(b)-1)*100,'paired_differences':delta,'paired_median_difference':statistics.median(delta)}
off_on={}
if args.confirm:
 for zone in ['core','maintenance_alarm']:
  off_on[zone]={}
  for metric in ['p50','p95','p99']:
   off=[next(r[metric] for r in rows if r['run']==f'cost-confirm/low-{i}-candidate' and r['window']==zone+'_off') for i in range(1,6)]
   on=[next(r[metric] for r in rows if r['run']==f'cost-confirm/low-{i}-candidate' and r['window']==zone+'_on') for i in range(1,6)]
   delta=[y-x for x,y in zip(off,on)]
   off_on[zone][metric]={'paired_differences':delta,'paired_median_difference':statistics.median(delta),'median_difference_percent':(statistics.median(on)/statistics.median(off)-1)*100,'order':'OFF then ON within every run; not counterbalanced'}
result={'checks':checks,'errors':errors,'runs':len(runs),'summary':summary,'candidate_off_on':off_on,'windows':rows,'intervals':sum(x['intervals'] for x in rows),'limitation':('five pairs Low only' if args.confirm else 'one run per quality/version; exploratory only')+'; baseline has no flashlight; held alarm and frozen actors; stationary poses, no user journey'}
(p/'perf-audit'/('cost-confirm.json' if args.confirm else 'cost.json')).write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({'checks':checks,'errors':errors,'intervals':result['intervals']}));raise SystemExit(bool(errors))
