"""Independent read-only audit; --partial omits group conclusions and live hashes."""
import argparse, hashlib, json, math, re, statistics, subprocess
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--partial',action='store_true');args=p.parse_args()
task=Path(__file__).resolve().parents[1]; root=task.parents[3]
route=[[0,0,z] for z in [-10,-16,-22,-32,-36,-42,-32,-12,7]]
heads={'baseline':'e5b0bafa7b8bad369e6767a908b1d8391343b9f2','candidate':'653e2a79c7f36e9ac7422335c85cef3b937ed0f9'}
sha={'engine':'8d106cbe6144c2dc7e881d61d2429c1a8a76e6b22ef48bd5e48dcf934953f71e','wrapper':'bc45ab99e5dd1cf55401fe99d67385ad365588f4f8b63fe4b887762e050124cd','probe':'28e9cd57c0e56f0c06601539d5cd7d35154e1191eea2568d9e6cbe0d2e47bf44'}
errors=[];checks=0;rows=[];sources={};timeline=[]
def check(ok, label):
 global checks
 checks+=1
 if not ok:errors.append(label)
def digest(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def quantile(v,f):return sorted(v)[min(int(len(v)*f),len(v)-1)]
for quality in ('normal','low'):
 for i in range(1,6):
  pairpath=task/'perf'/f'{quality}-{i}-pair.json'
  if not pairpath.exists():
   if not args.partial:check(False,f'missing pair {pairpath.name}')
   continue
  pair=json.loads(pairpath.read_text());expected=['baseline','candidate'] if i%2 else ['candidate','baseline']
  check([x['side'] for x in pair]==expected,f'{pairpath.name}: alternating order')
  check(pair[0]['end']<=pair[1]['start'],f'{pairpath.name}: serialization')
  for run in pair:
   side=run['side'];name=f'{quality}-{i}-{side}';folder=task/'perf'/name
   m=json.loads((folder/'manifest.json').read_text());j=json.loads((folder/'journey.json').read_text());log=(folder/'engine.log').read_text();v=j['frame_intervals_ms'];o=j['final_observation']
   def c(ok,label):check(ok,f'{name}: {label}')
   c(run['exit_code']==m['exit_code']==0 and not m['validation_errors'] and not j['failures'],'exits/failures')
   c(not re.search(r'SCRIPT ERROR:|ERROR:|Parse Error|Segmentation fault|PROOF FAILURE:',log),'engine log')
   c('SECTOR_PROOF mode=perf travelled=92.4 failures=0' in log,'completion marker')
   c(m['head']==heads[side],'source head');c(m['source_unchanged'] and m['source_before']==m['source_after'],'source before/after')
   if side not in sources:sources[side]=m['source_before']
   c(sources[side]==m['source_before'],'source across runs')
   c(m['artifacts_before']==m['artifacts_after']==sha and m['probe_sha256']==sha['probe'],'artifact hashes')
   c(run['start']<=m['started_unix']<m['ended_unix']<=run['end'],'wrapper timing containment')
   c(j['mode']=='perf' and j['performance_valid'] is True and not j['scene_inspection'],'scenario')
   c(j['waypoints_completed']==9 and j['waypoint_positions']==route and 92.3<j['travelled_m']<92.5,'nine stations / 92.4m')
   c(j['frames_drawn']==len(v)+1 and len(v)==len(j['frame_stages']) and len(v)>100,'frame counts')
   c(all(type(x) in (int,float) and math.isfinite(x) and x>0 for x in v),'positive finite intervals')
   c(j['display_driver']=='X11' and j['rendering_method']=='gl_compatibility' and j['renderer']=='llvmpipe (LLVM 21.1.8, 256 bits)' and j['resolution']==[1280,720],'render contract')
   c(j['engine']['string']=='4.7.2-stable (official)' and j['low_quality']==(quality=='low') and abs(o['scale_3d']-(.67 if quality=='low' else 1))<1e-6,'engine quality scale')
   c(j['circuits_available'] and o['circuits']=={'archives':True,'maintenance':True} and o['alarms']=={'archives':0,'maintenance':0},'power ON alarms OFF')
   c(o['live_enemies']==[] and j['shots']==0 and j['commands']==[],'actors removed / no interactions')
   c(j['lighting_available']==(side=='candidate'),'new lighting present only candidate')
   if side=='candidate':
    c(o['flashlight']['visible'] is False,'flashlight OFF');c(not any(x['shadow'] for x in o['lights']),'fixed-light shadow budget')
   else:c(o['flashlight'] is None,'baseline no flashlight')
   q={}
   for key,f in [('p50',.5),('p95',.95),('p99',.99)]:
    q[key]=quantile(v,f);c(abs(q[key]-j[f'frame_{key}_ms'])<1e-9,f'{key} raw recalculation')
   row={'name':name,'quality':quality,'side':side,'pair':i,'intervals':len(v),'frames':j['frames_drawn'],'duration_ms':sum(v),'travelled_m':j['travelled_m'],**q,'draw_calls_max':j['draw_calls_max'],'nodes_max':j['nodes_max'],'resources_max':j['resources_max'],'scale':o['scale_3d'],'lights_visible_final':sum(x['visible'] for x in o['lights']),'shadows_visible_final':sum(x['visible'] and x['shadow'] for x in o['lights'])}
   rows.append(row);timeline.append((run['start'],run['end'],name))
for a,b in zip(sorted(timeline),sorted(timeline)[1:]):check(a[1]<=b[0],f'global serialization {a[2]} / {b[2]}')
summary={}
if not args.partial:
 check(len(rows)==20,'exactly twenty complete runs')
 for quality in ('normal','low'):
  summary[quality]={}
  for metric in ('p50','p95','p99','draw_calls_max','nodes_max','resources_max'):
   groups={s:[r[metric] for r in rows if r['quality']==quality and r['side']==s] for s in heads}
   if not all(len(x)==5 for x in groups.values()):continue
   b,c=groups['baseline'],groups['candidate'];delta=[y-x for x,y in zip(b,c)]
   summary[quality][metric]={'baseline':{'median':statistics.median(b),'range':[min(b),max(b)]},'candidate':{'median':statistics.median(c),'range':[min(c),max(c)]},'median_difference_percent':(statistics.median(c)/statistics.median(b)-1)*100,'paired_differences':delta,'paired_median_difference':statistics.median(delta)}
 for k,path in {'engine':root/'.tools/Godot_v4.7.2-stable_linux.x86_64','wrapper':task/'proof-tools/prove_sector_power.py','probe':task/'proof-tools/probe_sector_power.gd'}.items():check(digest(path)==sha[k],f'current {k} hash')
 for side,files in sources.items():
  project=root/'.worktrees'/('silo9-issue-12' if side=='baseline' else 'silo9-issue-09')
  check(subprocess.check_output(['git','-C',str(project),'rev-parse','HEAD'],text=True).strip()==heads[side],f'live {side} head')
  check(subprocess.run(['git','-C',str(project),'diff','--quiet','HEAD','--']).returncode==0,f'live {side} tracked matches HEAD')
  tracked=subprocess.check_output(['git','-C',str(project),'ls-files','-z']).decode().split('\0')
  for name in filter(None,tracked):check(name in files and digest(project/name)==files[name],f'live {side} tracked {name}')
result={'partial':args.partial,'checks':checks,'errors':errors,'runs':rows,'interval_count':sum(r['intervals'] for r in rows),'summary':summary,'artifact_hashes':sha,'source_heads':heads}
(task/'perf-audit'/('partial.json' if args.partial else 'audit.json')).write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps({'partial':args.partial,'runs':len(rows),'checks':checks,'errors':errors,'intervals':result['interval_count']}))
raise SystemExit(bool(errors))
