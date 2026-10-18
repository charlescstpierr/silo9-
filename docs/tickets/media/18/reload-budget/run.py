from pathlib import Path
import datetime, hashlib, json, os, re, subprocess, sys, time
from validate import validate, negative_controls

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[4]
WT = ROOT/'.worktrees/silo9-issue-18'
HEAD = 'c105da61b2b490546f01c9d67703bfb405a2a44f'
BINARY = ROOT/'.tools/Godot_v4.7.2-stable_linux.x86_64'

def tracked_hashes():
    names = subprocess.check_output(['git','ls-files','-z'],cwd=WT).decode().split('\0')
    return {name:hashlib.sha256((WT/name).read_bytes()).hexdigest() for name in names if name}

def godot_processes():
    found=[]
    for path in Path('/proc').iterdir():
        if not path.name.isdigit(): continue
        try:
            comm=(path/'comm').read_text().strip()
            if 'godot' in comm.lower(): found.append({'pid':int(path.name),'comm':comm})
        except (OSError,ProcessLookupError): pass
    return found

if sys.argv[1:] != ['--execute']:
    raise SystemExit('Prepared only. Run with --execute after explicit runtime transfer.')
assert not godot_processes(), 'Runtime is occupied'
assert subprocess.check_output(['git','rev-parse','HEAD'],cwd=WT,text=True).strip()==HEAD
assert not subprocess.check_output(['git','diff','--name-only',HEAD],cwd=WT,text=True).strip(), 'Tracked source changed'
run_dir=OUT/datetime.datetime.now(datetime.timezone.utc).strftime('run-%Y%m%dT%H%M%SZ')
run_dir.mkdir()
before=tracked_hashes()
metadata={'head':HEAD,'tracked_before':before,'binary_sha256':hashlib.sha256(BINARY.read_bytes()).hexdigest(),'tools':{name:hashlib.sha256((OUT/name).read_bytes()).hexdigest() for name in ['probe.gd','validate.py','run.py']},'load_average':os.getloadavg(),'logical_cpus':os.cpu_count()}
(run_dir/'metadata.json').write_text(json.dumps(metadata,indent=2)+'\n')
env=os.environ.copy()
env.update(XDG_DATA_HOME=str(run_dir/'userdata'), XDG_CONFIG_HOME=str(run_dir/'config'), XDG_CACHE_HOME=str(run_dir/'cache'), SILO_RELOAD_OUTPUT=str(run_dir))
command=[str(BINARY),'--headless','--verbose','--path',str(WT),'--script',str(OUT/'probe.gd')]
start=time.monotonic()
try:
    result=subprocess.run(command,cwd=WT,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=180)
    output,code=result.stdout,result.returncode
except subprocess.TimeoutExpired as error:
    output=error.stdout or b''
    if isinstance(output,bytes): output=output.decode(errors='replace')
    code=124
(run_dir/'runtime.log').write_text(output)
status={'command':command,'environment':{key:env[key] for key in ['XDG_DATA_HOME','XDG_CONFIG_HOME','XDG_CACHE_HOME','SILO_RELOAD_OUTPUT']},'exit':code,'elapsed_seconds':time.monotonic()-start,'errors':re.findall(r'^(?:ERROR|SCRIPT ERROR|FAIL):.*',output,re.M),'warnings':re.findall(r'^WARNING:.*',output,re.M),'leaked_instances':re.findall(r'^Leaked instance:.*',output,re.M),'source_unchanged':tracked_hashes()==before,'godot_processes_after':godot_processes()}
if code==0 and not status['errors']:
    try:
        measurements=json.loads((run_dir/'measurements.json').read_text())
        status['validation']=validate(measurements)
        status['negative_controls']=negative_controls(measurements)
    except (OSError,ValueError,KeyError,AssertionError) as error:
        status['validation_error']=str(error)
(run_dir/'result.json').write_text(json.dumps(status,indent=2)+'\n')
(OUT/'last-run.json').write_text(json.dumps({'path':str(run_dir)},indent=2)+'\n')
print(json.dumps({'path':str(run_dir),**status},indent=2))
raise SystemExit(0 if code==0 and not status['errors'] and not status.get('validation_error') and status['source_unchanged'] and not status['godot_processes_after'] else 1)
