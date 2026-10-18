from pathlib import Path
import subprocess,os,time,json,hashlib
r=Path.cwd();t=r/'.cstack/orchestrate/silo9/issue09';out=t/'packaged-native-verified';out.mkdir(exist_ok=False);exe=r/'.worktrees/silo9-issue-09/builds/linux/SILO9.x86_64';events=[]
command=[str(exe),'--display-driver','x11','--rendering-method','gl_compatibility','--audio-driver','Dummy','--resolution','1280x720','--position','0,0']
def action(kind,value,duration=.1):
 cmd=['python3',str(r/'tools/x11_input.py'),kind,value,'--display',':100','--duration',str(duration)];p=subprocess.run(cmd);events.append(dict(command=cmd,exit_code=p.returncode,unix=time.time()));assert p.returncode==0
 time.sleep(1.0)
def shot(name):
 subprocess.run(['ffmpeg','-v','error','-f','x11grab','-video_size','1280x720','-i',':100','-frames:v','1',str(out/(name+'.png'))],check=True)
with (out/'engine.log').open('w') as log:
 p=subprocess.Popen(command,cwd=exe.parent,env=dict(os.environ,DISPLAY=':100',XDG_DATA_HOME=str(out/'userdata')),stdout=log,stderr=subprocess.STDOUT)
 try:
  time.sleep(5);shot('menu')
  action('move','300,360');action('click','300,360');time.sleep(1)
  action('key','w',2.2);shot('flashlight-off')
  action('key','f');shot('flashlight-on')
  action('key','q');shot('scan')
  action('key','Escape');shot('pause-lamp-on');action('key','Escape');shot('resumed-lamp-on')
  action('key','f');shot('flashlight-off-again')
  action('key','Escape');shot('pause')
  action('move','300,418');action('click','300,418');time.sleep(.4);shot('menu-return')
  action('move','300,590');action('click','300,590');p.wait(timeout=8)
 except Exception:
  p.terminate();p.wait(timeout=8);raise
 finally:
  result=dict(command=command,binary_sha256=hashlib.sha256(exe.read_bytes()).hexdigest(),events=events,exit_code=p.returncode,game_source_head='653e2a79c7f36e9ac7422335c85cef3b937ed0f9',limits='Exported Linux binary, native menu/movement/F/scan/pause/resume/quit smoke only; no full mission and no Windows execution. Screenshots require visual inspection.')
  (out/'verification.json').write_text(json.dumps(result,indent=2)+'\n')
print('Native exported Linux smoke exit',p.returncode)
