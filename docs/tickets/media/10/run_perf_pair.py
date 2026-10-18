from pathlib import Path
import subprocess,sys,json,time
root=Path.cwd();task=root/'.cstack/orchestrate/silo9/issue10'
quality,lamp,index=sys.argv[1],sys.argv[2],int(sys.argv[3]);assert quality in ('normal','low') and lamp in ('off','on') and 1<=index<=5
order=['baseline','candidate'] if index%2 else ['candidate','baseline'];rows=[]
for side in order:
 project=root/'.worktrees'/('silo9-issue-09' if side=='baseline' else 'silo9-issue-10')
 dest=task/'perf'/f'{quality}-{lamp}-{index}-{side}'
 command=['python3',str(task/'perf-proof-tools/prove_sector_power.py'),'--godot',str(root/'.tools/Godot_v4.7.2-stable_linux.x86_64'),'--project',str(project),'--mode','perf','--output',str(dest),'--timeout','120','--require-circuits','--require-lighting']
 if quality=='low':command.append('--low')
 if lamp=='on':command.append('--flashlight-on')
 start=time.time();p=subprocess.run(command);rows.append(dict(side=side,start=start,end=time.time(),exit_code=p.returncode,command=command))
 if p.returncode:
  (task/'perf'/f'{quality}-{lamp}-{index}-FAILED.json').write_text(json.dumps(rows,indent=2)+'\n');raise SystemExit(p.returncode)
(task/'perf'/f'{quality}-{lamp}-{index}-pair.json').write_text(json.dumps(rows,indent=2)+'\n')
