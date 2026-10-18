from pathlib import Path
import hashlib,json,subprocess,tarfile,zipfile
root=Path.cwd();work=root/'.worktrees/silo9-issue-18';task=root/'.cstack/orchestrate/silo9/issue18';builds=work/'builds'
head=subprocess.check_output(['git','-C',str(work),'rev-parse','HEAD'],text=True).strip()
manifest=json.loads((builds/'SHA256.json').read_text())
for name,entry in manifest.items():
 p=builds/name
 assert p.stat().st_size==entry['bytes'] and hashlib.sha256(p.read_bytes()).hexdigest()==entry['sha256'],name
entries=subprocess.check_output(['git','-C',str(work),'ls-tree','-rz','HEAD']).split(b'\0');count=0
with zipfile.ZipFile(builds/'SILO9-Source.zip') as archive:
 assert archive.testzip() is None
 expected=[]
 for entry in entries:
  if not entry:continue
  meta,name=entry.split(b'\t',1);mode,kind,sha=meta.split();assert kind==b'blob'
  target='SILO9/'+name.decode();expected.append(target);data=archive.read(target)
  assert hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()==sha.decode(),target
  count+=1
 assert sorted(archive.namelist())==sorted(expected)
proof=json.loads((task/'packaged-native-verified/verification.json').read_text())
assert type(proof['exit_code']) is int and proof['exit_code']==0, 'Exported Linux process did not exit successfully'
assert len(proof['events'])==16 and all(type(event['exit_code']) is int and event['exit_code']==0 for event in proof['events']), 'Native input sequence incomplete or failed'
with tarfile.open(builds/'SILO9-Linux-x64.tar.gz','r:gz') as archive:
 data=archive.extractfile('SILO9/SILO9.x86_64').read();assert hashlib.sha256(data).hexdigest()==proof['binary_sha256']
 for name in ['README.md','docs/VALIDATION.md','docs/tickets/18-persistence.md','docs/tickets/media/18/SHA256.json','docs/tickets/media/18/delivery-review.md']:
  assert archive.extractfile('SILO9/'+name).read()==(work/name).read_bytes(),name
with zipfile.ZipFile(builds/'SILO9-Windows-x64.zip') as archive:
 assert archive.testzip() is None
 assert archive.read('SILO9/SILO9.exe')==(builds/'windows/SILO9.exe').read_bytes()
 for name in ['README.md','docs/VALIDATION.md','docs/tickets/18-persistence.md','docs/tickets/media/18/SHA256.json','docs/tickets/media/18/delivery-review.md']:
  assert archive.read('SILO9/'+name)==(work/name).read_bytes(),name
result={'head':head,'artifacts':manifest,'source_blobs_verified':count,'linux_binary_matches_tested':True,'docs_final_in_both_packages':True,'windows_executed':False}
(task/'final-packages.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))
