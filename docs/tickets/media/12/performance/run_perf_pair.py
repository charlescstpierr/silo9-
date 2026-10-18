from pathlib import Path
import subprocess,sys,json,time
root=Path.cwd(); task=root/'.cstack/orchestrate/silo9/issue12'
quality,index=sys.argv[1],int(sys.argv[2]); assert quality in ('normal','low') and 1<=index<=5
order=['baseline','candidate'] if index%2 else ['candidate','baseline']; rows=[]
for side in order:
 project=root/'.worktrees'/('silo9-issue-08' if side=='baseline' else 'silo9-issue-12')
 dest=task/'perf'/f'{quality}-{index}-{side}'
 command=['python3',str(task/'proof-tools/run_probe.py'),'--godot',str(root/'.tools/Godot_v4.7.2-stable_linux.x86_64'),'--project',str(project),'--mode','perf','--output',str(dest),'--timeout','120']
 if side=='candidate':command.append('--require-circuits')
 if quality=='low':command.append('--low')
 start=time.time(); p=subprocess.run(command); rows.append(dict(side=side,start=start,end=time.time(),exit_code=p.returncode,command=command))
 if p.returncode: raise SystemExit(p.returncode)
(task/'perf'/f'{quality}-{index}-pair.json').write_text(json.dumps(rows,indent=2)+'\n')
