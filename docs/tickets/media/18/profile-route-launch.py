from pathlib import Path
import subprocess,time,json
r=Path.cwd();t=r/'.cstack/orchestrate/silo9/issue18';out=t/'profile-route-candidate';cmd=['python3',str(t/'profile-tools/prove_sector_power.py'),'--project',str(r/'.worktrees/silo9-issue-18'),'--godot',str(r/'.tools/Godot_v4.7.2-stable_linux.x86_64'),'--output',str(out),'--mode','perf','--require-circuits','--require-lighting','--flashlight-on','--terminal-variant','candidate']
with (t/'profile-route-wrapper.log').open('w') as log:
 p=subprocess.Popen(cmd,stdout=log,stderr=subprocess.STDOUT);deadline=time.time()+120;pid=None
 while time.time()<deadline:
  engine_log=out/'engine.log'
  if engine_log.exists() and 'PROFILE_ROUTE_BEGIN' in engine_log.read_text(errors='replace'):
   for child in Path('/proc',str(p.pid),'task',str(p.pid),'children').read_text().split():
    try:
     if b'Godot_v4.7.2' in Path('/proc',child,'cmdline').read_bytes():pid=child
    except FileNotFoundError:pass
   break
  if p.poll() is not None:break
  time.sleep(.1)
 assert pid,'No active engine at route marker'
 sampled_at=time.time()
 with (t/'profile-route-cpu.log').open('w') as output:q=subprocess.run(['pidstat','-t','-u','-p',pid,'1','5'],stdout=output,stderr=subprocess.STDOUT)
 code=p.wait(timeout=150)
(t/'profile-route-link.json').write_text(json.dumps({'command':cmd,'engine_pid':pid,'route_marker_observed':True,'profile_started_unix':sampled_at,'profile_exit':q.returncode,'probe_exit':code,'excluded_from_pairs':True},indent=2)+'\n');print('ROUTE_PROFILE',code,q.returncode,flush=True)
assert code==0 and q.returncode==0
