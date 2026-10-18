import hashlib,json,re
from pathlib import Path
p=Path(__file__).resolve().parents[1];errors=[]
def check(v,s):
 if not v:errors.append(s)
a=(p/'proof-tools/probe_sector_power.gd').read_text();b=(p/'profile-tools/probe_sector_power.gd').read_text()
check(b==a.replace('func performance_route() -> void:\n','func performance_route() -> void:\n\tprint("PROFILE_ROUTE_BEGIN usec=", Time.get_ticks_usec())\n'),'probe delta is marker only')
check((p/'profile-tools/prove_sector_power.py').read_bytes()==(p/'proof-tools/prove_sector_power.py').read_bytes(),'wrapper unchanged')
m=json.loads((p/'profile-route-candidate/manifest.json').read_text());link=json.loads((p/'profile-route-link.json').read_text());j=json.loads((p/'profile-route-candidate/journey.json').read_text());log=(p/'profile-route-candidate/engine.log').read_text()
check(link['profile_exit']==link['probe_exit']==m['exit_code']==0 and not m['validation_errors'] and not j['failures'],'profile/engine exits')
check(link['excluded_from_pairs'] and link['route_marker_observed'],'profile excluded and marker observed')
check(m['source_unchanged'] and m['source_before']==m['source_after'],'source stable')
check(m['artifacts_before']==m['artifacts_after'],'artifacts stable')
for key,name in [('probe','probe_sector_power.gd'),('wrapper','prove_sector_power.py')]:check(hashlib.sha256((p/'profile-tools'/name).read_bytes()).hexdigest()==m['artifacts_before'][key],key+' hash')
marker=int(re.search(r'PROFILE_ROUTE_BEGIN usec=(\d+)',log)[1]);check(log.index('PROFILE_ROUTE_BEGIN')<log.index('SECTOR_PROOF'),'marker before completion')
lines=[x.split() for x in (p/'profile-route-cpu.log').read_text().splitlines() if x.startswith('Average:')]
pid=link['engine_pid'];proc=next(x for x in lines if x[2]==pid and x[3]=='-');main=next(x for x in lines if x[3]==pid);raster=[x for x in lines if 'llvmpipe' in x[-1]]
check(len(raster)==8,'eight raster threads');cpu=float(proc[8]);raster_cpu=sum(float(x[8]) for x in raster)
result={'errors':errors,'profile_window_seconds':5,'process_cpu_percent':cpu,'llvmpipe_cpu_percent':raster_cpu,'llvmpipe_share_process_percent':raster_cpu/cpu*100,'main_thread_cpu_percent':float(main[8]),'engine_marker_seconds':marker/1e6,'profile_start_after_wrapper_seconds':link['profile_started_unix']-m['started_unix'],'measured_route_seconds':sum(j['frame_intervals_ms'])/1000,'limit':'Process CPU accounting of one separately profiled candidate Normal early-route window; no per-function attribution or baseline/Low CPU comparison.'}
(p/'perf-audit/profile.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result));raise SystemExit(bool(errors))
