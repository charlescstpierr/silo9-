"""Read-only audit of the separately executed CPU profile; no profiler is run."""
import json
import re
from audit_campaign import TASK, OUT, ROOT, HEADS, PROJECTS, digest, read, require, validate_report


def main():
    freeze=read(TASK/'perf-freeze.json'); campaign=read(OUT/'campaign-audit.json')
    folder=TASK/'profile-route-candidate'; manifest=read(folder/'manifest.json'); report=read(folder/'journey.json')
    link=read(TASK/'profile-route-link.json'); log=(folder/'engine.log').read_text(); files=TASK/'profile-tools'
    require(campaign['passed'],'campaign must be audited first')
    require(manifest['head']==HEADS['candidate'] and manifest['project']==str(PROJECTS['candidate']),'profile actual project/head')
    require(manifest['source_before']==manifest['source_after']==freeze['projects']['candidate']['source'] and manifest['source_unchanged'] is True,'profile same frozen candidate source')
    require(manifest['exit_code']==link['probe_exit']==link['profile_exit']==0 and manifest['validation_errors']==[],'profile/probe exit status')
    require(not re.search(r'(?:SCRIPT ERROR:|ERROR:|Parse Error|Segmentation fault)',log),'profile engine errors')
    marker='\tprint("PROFILE_ROUTE_BEGIN")\n'
    text=(files/'probe_sector_power.gd').read_text()
    require(text.count(marker)==1 and text.replace(marker,'')==(TASK/'proof-tools/probe_sector_power.gd').read_text(),'only one print-marker delta')
    require((files/'prove_sector_power.py').read_bytes()==(TASK/'proof-tools/prove_sector_power.py').read_bytes(),'profile wrapper identical')
    require((files/'selfcheck_sector_power.py').read_bytes()==(TASK/'proof-tools/selfcheck_sector_power.py').read_bytes(),'profile selfcheck identical')
    artifacts={'engine':freeze['engine'],'probe':digest(files/'probe_sector_power.gd'),'wrapper':digest(files/'prove_sector_power.py'),'selfcheck':digest(files/'selfcheck_sector_power.py'),'input_helper':freeze['projects']['candidate']['source']['tools/x11_input.py']}
    require(manifest['artifacts_before']==manifest['artifacts_after']==artifacts,'profile artifact identity')
    command=manifest['command']
    require(command[command.index('--script')+1]==str(files/'probe_sector_power.gd') and '--terminal-variant=candidate' in command and '--flashlight-on' in command and '--low' not in command,'actual profile probe and Normal ON scenario')
    require(link['command'][1]==str(files/'prove_sector_power.py'),'profile launched actual wrapper')
    values=validate_report(report,'candidate','normal')
    require(link['excluded_from_pairs'] is True and folder.name not in {r['name'] for r in campaign['runs']},'profile not counted as campaign')
    require(manifest['started_unix']>max(r['ended_unix'] for r in campaign['runs']),'profile starts strictly after campaign')
    require(link['route_marker_observed'] is True and log.count('PROFILE_ROUTE_BEGIN')==1,'marker observed at route entry')
    require(manifest['started_unix']<=link['profile_started_unix']<link['profile_started_unix']+5<manifest['ended_unix'],'five-second profile within executed engine run')
    require(values['measured_elapsed_ms']>5000,'route longer than five-second profile')
    lines=[line.split() for line in (TASK/'profile-route-cpu.log').read_text().splitlines() if line.startswith('Average:')]
    pid=str(link['engine_pid'])
    process=[line for line in lines if line[2]==pid and line[3]=='-']
    main_thread=[line for line in lines if line[2]=='-' and line[3]==pid]
    llvmpipe=[line for line in lines if line[2]=='-' and 'llvmpipe-' in line[-1]]
    require(len(process)==len(main_thread)==1 and len(llvmpipe)==8,'profile correct engine and eight rasterizer threads')
    samples=[line.split() for line in (TASK/'profile-route-cpu.log').read_text().splitlines() if re.match(r'^\d\d:\d\d:\d\d\s',line)]
    process_samples=[line for line in samples if len(line)>10 and line[2]==pid and line[3]=='-']
    require(len(process_samples)==5,'five raw one-second process samples')
    cpu=float(process[0][8]); render=sum(float(line[8]) for line in llvmpipe)
    require(cpu>0 and 0<render<=cpu+1,'CPU arithmetic is physically consistent')
    output={'passed':True,'profile_engine_pid':pid,'profile_seconds':5,'profile_after_campaign':True,'source_unchanged':True,'only_instrumentation':'one print marker at performance_route entry','source_head':HEADS['candidate'],'quality':'normal','lamp':'on','process_cpu_percent':cpu,'main_thread_cpu_percent':float(main_thread[0][8]),'llvmpipe_cpu_percent_sum':render,'llvmpipe_process_cpu_share_percent':100*render/cpu,'llvmpipe_threads':8,'raw_process_cpu_percent':[float(line[8]) for line in process_samples],'warnings':re.findall(r'^WARNING:.*',log,re.M),'profile_window_unix':[link['profile_started_unix'],link['profile_started_unix']+5],'source_count':len(manifest['source_before']),'limits':['CPU percentages are normalized to one logical CPU; 100 percent equals one core','Thread names identify dominant software-renderer CPU work, not the marginal cost of carcasses','Single five-second Normal sample, not a separate Low profile or full-route attribution','Route-marker handshake and source establish phase; no continuous per-frame profile timestamps','Profile frame timings intentionally excluded from all paired campaign results']}
    (OUT/'profile-audit.json').write_text(json.dumps(output,indent=2)+'\n');print(json.dumps(output,indent=2))


if __name__=='__main__':main()
