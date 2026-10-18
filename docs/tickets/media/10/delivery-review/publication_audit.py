from pathlib import Path
import hashlib,json,re,subprocess
from urllib.parse import unquote
root=Path(__file__).resolve().parents[5];work=root/'.worktrees/silo9-issue-10';task=root/'.cstack/orchestrate/silo9/issue10';media=work/'docs/tickets/media/10';out=task/'delivery-review'
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
manifest=json.loads((media/'SHA256.json').read_text());actual={str(p.relative_to(media)) for p in media.rglob('*') if p.is_file() and p!=media/'SHA256.json'}
assert set(manifest)==actual, (set(manifest)-actual,actual-set(manifest))
for path,digest in manifest.items(): assert sha(media/path)==digest,path
selection=json.loads((media/'selection-manifest.json').read_text());rows=selection['files']
assert len(rows)==selection['count']==len({r['destination'] for r in rows})
assert sum(r['bytes'] for r in rows)==selection['bytes']
selected=set()
for row in rows:
 p=work/row['destination'];selected.add(str(p.relative_to(media)))
 assert p.stat().st_size==row['bytes'] and sha(p)==row['sha256'],row['destination']
 assert sha(root/row['source'])==row['sha256'],row['source']
assert actual==selected|{'selection-manifest.json'}
refs=selection['reuse_existing']
for row in refs:
 assert sha(work/row['path'])==row['sha256'],row['path']
files=[work/'README.md',work/'docs/VALIDATION.md',work/'docs/tickets/10-environment.md']+list(media.rglob('*.md'))
links=[];missing=[]
for p in files:
 for dest in re.findall(r'\]\(([^)]+)\)',p.read_text()):
  dest=dest.split('#',1)[0]
  if not dest or re.match(r'\w+://',dest): continue
  target=p.parent/unquote(dest)
  item={'file':str(p.relative_to(work)),'link':dest}
  links.append(item)
  if not target.exists(): missing.append(item)
export=json.loads((media/'export-identity.json').read_text())
for name,row in export['binaries'].items():
 p=work/'builds'/name
 assert p.stat().st_size==row['bytes'] and sha(p)==row['sha256'],name
result={'media_files_excluding_root_hash_manifest':len(actual),'selected_original_files':len(rows),'reused_historical_files_verified':len(refs),'selected_bytes':selection['bytes'],'root_manifest_exact_and_hashes_valid':True,'selection_sources_and_destinations_match':True,'local_links_checked':len(links),'missing_links':missing,'exported_binaries_match':True,'reviewed_document_sha256':{str(p.relative_to(work)):sha(p) for p in files[:3]},'branch':subprocess.check_output(['git','-C',str(work),'branch','--show-current'],text=True).strip(),'head':subprocess.check_output(['git','-C',str(work),'rev-parse','HEAD'],text=True).strip()}
(out/'publication-audit.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))
