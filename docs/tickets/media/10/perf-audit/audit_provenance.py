"""Verify frozen files, independent profile provenance and sampled host evidence."""
import hashlib, importlib.util, json, sys
from pathlib import Path
sys.dont_write_bytecode=True
t=Path(__file__).resolve().parents[1]; a=t/'perf-audit'; checks={}; failed=[]
def check(name,value):
 checks[name]=value
 if not value:failed.append(name)
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
for side in ['baseline','candidate']:
 m=json.loads((t/'perf'/f'normal-off-1-{side}'/'manifest.json').read_text());project=Path(m['project'])
 changed=[name for name,digest in m['source_before'].items() if not (project/name).is_file() or sha(project/name)!=digest]
 checks[f'{side}_all_manifest_sources_match_live_files']=not changed
 checks[f'{side}_live_modified_manifest_files']=changed
 if changed and side=='candidate':
  identity={x['name']:x for x in json.loads((t/'published-tool-identity.json').read_text())}
  expected={'tools/probe_sector_power.gd','tools/prove_sector_power.py','tools/selfcheck_sector_power.py'}
  check('candidate_only_documented_post_measurement_tool_replacements',set(changed)==expected and all(sha(project/name)==identity[Path(name).name]['sha256']==sha(t/identity[Path(name).name]['source']/Path(name).name) for name in changed))
  checks['current_full_source_identity_limit']='Candidate worktree tools were deliberately published after campaign/profile/export per parent. Current full source is not identical to measured source; 40 manifests and separate profile establish measured identity.'
 else:
  check(f'{side}_unchanged_live_manifest_files',not changed)
 checks[f'{side}_source_count']=len(m['source_before'])
 for key,path in [('engine',Path(m['command'][0])),('probe',t/'perf-proof-tools/probe_sector_power.gd'),('wrapper',t/'perf-proof-tools/prove_sector_power.py')]:
  check(f'{side}_{key}_live_digest',sha(path)==m['artifacts_before'][key])
profile=t/'profile-route-candidate';m=json.loads((profile/'manifest.json').read_text());r=json.loads((profile/'journey.json').read_text());link=json.loads((t/'profile-route-link.json').read_text())
spec=importlib.util.spec_from_file_location('proof',t/'perf-proof-tools/prove_sector_power.py');proof=importlib.util.module_from_spec(spec);spec.loader.exec_module(proof)
check('profile_valid',not proof.validate_result(r,m['exit_code'],(profile/'engine.log').read_text(),flashlight_requested=True))
check('profile_exit_codes',link['probe_exit']==link['profile_exit']==m['exit_code']==0 and not m['validation_errors'])
check('profile_sources_unchanged',m['source_before']==m['source_after'])
check('profile_same_candidate_source',m['source_before']==json.loads((t/'perf/normal-on-1-candidate/manifest.json').read_text())['source_before'])
check('profile_artifacts_unchanged',m['artifacts_before']==m['artifacts_after'])
for key,name in [('probe','probe_sector_power.gd'),('wrapper','prove_sector_power.py')]:check(f'profile_{key}_live_digest',sha(t/'profile-tools'/name)==m['artifacts_before'][key])
check('profile_only_probe_marker_delta',(t/'profile-tools/probe_sector_power.gd').read_text().replace('\tprint("PROFILE_ROUTE_BEGIN")\n','')==(t/'perf-proof-tools/probe_sector_power.gd').read_text())
check('profile_wrapper_identical',(t/'profile-tools/prove_sector_power.py').read_bytes()==(t/'perf-proof-tools/prove_sector_power.py').read_bytes())
check('profile_marker_exists','PROFILE_ROUTE_BEGIN' in (profile/'engine.log').read_text())
campaign=json.loads((a/'campaign-audit.json').read_text());end=max(x['ended_unix'] for x in campaign['runs'])
check('profile_strictly_after_all_40_runs',m['started_unix']>end)
check('profile_window_inside_engine_run',m['started_unix']<=link['profile_started_unix']<link['profile_started_unix']+5<m['ended_unix'])
check('profile_excluded',link['excluded_from_pairs'] is True)
lines=[x.split() for x in (t/'profile-route-cpu.log').read_text().splitlines() if x.startswith('Average:')]
process=next(x for x in lines if x[2]==link['engine_pid'] and x[3]=='-')
threads=[x for x in lines if 'llvmpipe-' in x[-1]]
checks['profile_process_cpu_percent']=float(process[8]);checks['profile_llvmpipe_cpu_percent_sum']=sum(float(x[8]) for x in threads);checks['profile_llvmpipe_threads']=len(threads)
checks['profile_llvmpipe_cpu_share_percent']=100*checks['profile_llvmpipe_cpu_percent_sum']/checks['profile_process_cpu_percent']
start=json.loads((t/'perf/host-start.json').read_text());host=[json.loads(x) for x in (t/'perf/host-samples.jsonl').read_text().splitlines()]
check('host_start_no_renderer_encoder_profiler',not start['active_renderer_encoder_profiler_processes'])
check('host_sampled_at_most_one_runtime',all(len(x['processes'])<=1 for x in host))
check('host_sampled_runtime_belongs_to_campaign',all('/issue10/perf/' in p and 'Godot' in p for x in host for p in x['processes']))
checks['host_sample_count']=len(host);checks['host_load_one_minute_samples']=[x['loadavg'][0] for x in host if 'loadavg' in x]
checks['host_evidence_limit']='punctual filtered process samples; no continuous external concurrency guarantee'
checks['passed']=not failed;checks['failures']=failed
(a/'provenance-audit.json').write_text(json.dumps(checks,indent=2)+'\n');print(json.dumps(checks,indent=2));raise SystemExit(bool(failed))
