from pathlib import Path
import hashlib,json,subprocess,os
root=Path(__file__).resolve().parents[5]
work=root/'.worktrees/silo9-issue-10'
task=root/'.cstack/orchestrate/silo9/issue10'
out=task/'delivery-review'
def digest(p): return hashlib.sha256(p.read_bytes()).hexdigest()
checks={}
rows=json.loads((task/'published-tool-identity.json').read_text())
for row in rows:
    assert digest(work/'tools'/row['name']) == row['sha256'] == digest(task/row['source']/row['name']),row['name']
checks['six_published_tools_match_frozen_tools']=True
art=digest(work/'scripts/world_art.gd')
assert art=='c3a973b5774ba521a29deff13dd9234db260c5e0329a0ecfc20da3d53b866cf0'
checks['production_source_sha256']=art
rows=json.loads((task/'implementation/final-tests/results.json').read_text())
for row in rows:
    assert digest(work/row['command'][-1])==row['test_sha256']
    assert row['source_sha256']==art and row['exit']==0 and row['errors']==[]
    log=task/'implementation/final-tests'/(row['test']+'.log')
    assert log.exists(),str(log)
checks['test_sources_match_recorded_runs']=len(rows)
proof=json.loads((task/'packaged-native-verified/verification.json').read_text())
assert digest(Path(proof['command'][0]))==proof['binary_sha256']
assert proof['exit_code']==0 and all(e['exit_code']==0 for e in proof['events'])
checks['linux_binary_matches_native_smoke_sha256']=proof['binary_sha256']
checks['native_inputs_success']=len(proof['events'])
checks['selfchecks']={}
for name in ('test_geometry_check.py','selfcheck_sector_power.py'):
    result=subprocess.run(['python3',str(work/'tools'/name)],env=os.environ|{'PYTHONDONTWRITEBYTECODE':'1'},capture_output=True,text=True)
    (out/(name+'.log')).write_text(result.stdout+result.stderr)
    assert result.returncode==0,name
    checks['selfchecks'][name]={'exit':0,'output':result.stdout+result.stderr}
(out/'initial-audit.json').write_text(json.dumps(checks,indent=2)+'\n')
print(json.dumps(checks,indent=2))
