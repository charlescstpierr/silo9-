from pathlib import Path
import hashlib, importlib.util, json, re, statistics, sys
root=Path.cwd();wt=root/'.worktrees/silo9-issue-18';media=wt/'docs/tickets/media/18';out=root/'.cstack/orchestrate/silo9/issue18/delivery-review'
def module(name,path):
 spec=importlib.util.spec_from_file_location(name,path);obj=importlib.util.module_from_spec(spec);spec.loader.exec_module(obj);return obj
proof=module('published_proof',wt/'tools/prove_sector_power.py')
audit=module('independent_perf',media/'perf-audit/audit_campaign.py')
reload=module('reload_validator',media/'reload-budget/validate.py')
errors=[];native=[];perf=[]
for name in ['native-mother','native-n7-low']:
 folder=media/name;r=json.loads((folder/'journey.json').read_text());m=json.loads((folder/'manifest.json').read_text())
 failures=proof.validate_result(r,m['exit_code'],(folder/'engine.log').read_text())+proof.validate_artifacts(r,folder)
 if failures:errors.append([name,failures])
 native.append({'name':name,'ending':r['ending'],'distance':r['travelled_m'],'failures':failures})
for quality in ['normal','low']:
 for index in range(1,6):
  for side in ['reference','candidate']:
   name=f'{quality}-{index}-{side}';folder=media/'perf'/name;r=json.loads((folder/'journey.json').read_text());m=json.loads((folder/'manifest.json').read_text())
   failures=proof.validate_result(r,m['exit_code'],(folder/'engine.log').read_text(),flashlight_requested=True,terminal_variant=side)
   if failures:errors.append([name,failures])
   values=audit.validate_report(r,side,quality);perf.append({'name':name,'quality':quality,'index':index,'side':side,**values})
low_delta=[];low_pct=[]
for i in range(1,6):
 pair={x['side']:x['p50'] for x in perf if x['quality']=='low' and x['index']==i};delta=pair['candidate']-pair['reference'];low_delta.append(delta);low_pct.append(100*delta/pair['reference'])
measurements=json.loads((media/'reload-budget/run-20261018T160950Z/measurements.json').read_text())
resources=reload.validate(measurements);negatives=reload.negative_controls(measurements)
links=[]
for filename in ['README.md','docs/VALIDATION.md','docs/tickets/18-persistence.md']:
 f=wt/filename
 for target in re.findall(r'\]\(([^)]+)\)',f.read_text()):
  if '://' in target or target.startswith('#'):continue
  path=(f.parent/target.split('#')[0]).resolve();links.append(str(path))
  if not path.exists():errors.append(['missing link',filename,target])
result={'native':native,'performance_runs':len(perf),'intervals':sum(x['samples'] for x in perf),'frames':sum(x['frames_drawn'] for x in perf),'low_p50_delta_median_ms':statistics.median(low_delta),'low_p50_delta_median_percent':statistics.median(low_pct),'reload_cycles':resources['measured_reloads'],'reload_negative_controls':len(negatives),'local_links_checked':len(links),'errors':errors}
(out/'published-artifact-audit.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result))
assert not errors
