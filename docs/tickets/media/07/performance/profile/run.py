from pathlib import Path
import importlib.util, json, os, threading, time
from types import SimpleNamespace
ROOT=Path(__file__).resolve().parents[5]
WORK=ROOT/'.worktrees/silo9-issue-07'
OUT=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('shot_proof', ROOT/'.cstack/orchestrate/silo9/issue07/proof-tools/prove_ads.py')
runner=importlib.util.module_from_spec(spec);spec.loader.exec_module(runner)
args=SimpleNamespace(project=WORK,godot=(WORK/'.tools/Godot_v4.7.2-stable_linux.x86_64').resolve())
args.campaign=runner.freeze_campaign([WORK],args.godot,WORK)
runner.write_json(OUT/'campaign.json',args.campaign)
runner.prepare(args,WORK,OUT/'prepare')
stop=threading.Event();observations=[]
def sample():
    previous={};previous_time=time.monotonic();clock=os.sysconf('SC_CLK_TCK')
    while not stop.wait(.5):
        pids=[]
        for path in Path('/proc').iterdir():
            if not path.name.isdigit():continue
            try: argv=(path/'cmdline').read_bytes().split(b'\0')
            except OSError:continue
            if argv and b'Godot_v4.7.2' in argv[0] and str(OUT/'run/probe-at-launch.gd').encode() in argv:pids.append(path)
        now=time.monotonic();current={};rows=[]
        for proc in pids:
            try: tasks=list((proc/'task').iterdir())
            except FileNotFoundError: continue
            for task in tasks:
                try:
                    stat=(task/'stat').read_text().split(') ',1)[1].split();ticks=int(stat[11])+int(stat[12]);name=(task/'comm').read_text().strip()
                except OSError:continue
                key=(int(proc.name),int(task.name));current[key]=ticks
                if key in previous:rows.append({'pid':key[0],'tid':key[1],'name':name,'cpu_percent':100*(ticks-previous[key])/clock/(now-previous_time)})
        if rows:observations.append({'monotonic':now,'threads':rows,'load':os.getloadavg()})
        previous=current;previous_time=now
thread=threading.Thread(target=sample);thread.start()
try:
    result=runner.invoke(args,WORK,OUT/'run','perf')
    runner.write_json(OUT/'profile-result.json',{'excluded_from_comparison':True,'reason':'thread sampler active','journey':result})
finally:
    stop.set();thread.join()
    runner.write_json(OUT/'cpu-threads.json',{'excluded_from_comparison':True,'cpu_count':os.cpu_count(),'clock_ticks':os.sysconf('SC_CLK_TCK'),'samples':observations})
