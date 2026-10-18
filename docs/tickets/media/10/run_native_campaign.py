from pathlib import Path
import subprocess,os,time,json,hashlib
root=Path.cwd();task=root/'.cstack/orchestrate/silo9/issue10';project=root/'.worktrees/silo9-issue-10';film=task/'native-film';film.mkdir(exist_ok=False);rows=[]
video=film/'mother.mp4'
record_command=['ffmpeg','-hide_banner','-loglevel','warning','-f','x11grab','-video_size','1280x720','-framerate','15','-i',':100','-c:v','libx264','-preset','ultrafast','-crf','25','-pix_fmt','yuv420p',str(video)]
with (film/'writer.log').open('w') as log:
 writer=subprocess.Popen(record_command,stdin=subprocess.PIPE,stdout=log,stderr=subprocess.STDOUT)
 try:
  time.sleep(1)
  command=['python3',str(task/'route-proof-tools/prove_sector_power.py'),'--project',str(project),'--godot',str(root/'.tools/Godot_v4.7.2-stable_linux.x86_64'),'--output',str(task/'native-mother'),'--mode','mission','--require-circuits','--require-lighting','--timeout','180']
  started=time.time();result=subprocess.run(command);rows.append({'name':'mother','command':command,'exit':result.returncode,'started':started,'ended':time.time()})
 finally:
  writer.communicate(b'q\n',timeout=20)
 (film/'writer.json').write_text(json.dumps({'command':record_command,'exit':writer.returncode,'sha256':hashlib.sha256(video.read_bytes()).hexdigest()},indent=2)+'\n')
 if result.returncode or writer.returncode:raise SystemExit('Mother or writer failed')
command=['python3',str(task/'route-proof-tools/prove_sector_power.py'),'--project',str(project),'--godot',str(root/'.tools/Godot_v4.7.2-stable_linux.x86_64'),'--output',str(task/'native-n7-low'),'--mode','capture','--ending','n7','--low','--require-circuits','--require-lighting','--timeout','240']
started=time.time();result=subprocess.run(command);rows.append({'name':'n7-low','command':command,'exit':result.returncode,'started':started,'ended':time.time()});(task/'native-campaign.json').write_text(json.dumps(rows,indent=2)+'\n')
if result.returncode:raise SystemExit(result.returncode)
with (film/'ffprobe.json').open('w') as out:
 probe=subprocess.run(['ffprobe','-v','error','-count_frames','-show_streams','-show_format','-of','json',str(video)],stdout=out)
with (film/'decode.log').open('w') as out:
 decode=subprocess.run(['ffmpeg','-v','error','-i',str(video),'-f','null','-'],stdout=out,stderr=subprocess.STDOUT)
(film/'decode.json').write_text(json.dumps({'ffprobe_exit':probe.returncode,'decode_exit':decode.returncode},indent=2)+'\n')
if probe.returncode or decode.returncode:raise SystemExit('Video verification failed')
print('Native campaign and full video decoding passed',flush=True)
