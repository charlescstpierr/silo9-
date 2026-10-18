"""Read-only freeze audit; does not require or create campaign runs."""
import datetime
import json
from audit_campaign import TASK, OUT, ROOT, HEADS, PROJECTS, digest, read

frozen=read(TASK/'perf-freeze.json')
checks={}
checks['heads']=all(frozen['projects'][side]['head']==HEADS[side] for side in HEADS)
checks['runner']=digest(TASK/'run_perf_pair.py')==frozen['runner']
checks['engine']=digest(ROOT/'.tools/Godot_v4.7.2-stable_linux.x86_64')==frozen['engine']
checks['separate_real_tool_files']=all((TASK/'proof-tools'/name).is_file() and not (TASK/'proof-tools'/name).is_symlink() and digest(TASK/'proof-tools'/name)==sha for name,sha in frozen['artifacts'].items())
changed={}
for side in HEADS:
    changed[side]=[name for name,sha in frozen['projects'][side]['source'].items() if not (PROJECTS[side]/name).is_file() or digest(PROJECTS[side]/name)!=sha]
    checks[side+'_source']=not changed[side]
result={'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'passed':all(checks.values()),'checks':checks,'changed':changed,'source_counts':{side:len(frozen['projects'][side]['source']) for side in HEADS},'freeze_sha256':digest(TASK/'perf-freeze.json'),'runner_sha256':frozen['runner'],'proof_tool_hashes':frozen['artifacts'],'audit_tool_hashes':{name:digest(OUT/name) for name in ['audit_campaign.py','preflight.py','selfcheck.py']},'scope':'Pre-campaign source and tool identity only; no runtime or performance claim'}
(OUT/'preflight.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result,indent=2))
raise SystemExit(not result['passed'])
