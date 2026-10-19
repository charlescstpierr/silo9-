"""Checks runner guards with temporary synthetic files; never runs Godot."""
from pathlib import Path
import copy
import importlib.util
import json
import tempfile
import unittest
from unittest.mock import patch

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('pair', HERE.parent / 'run_perf_pair.py')
pair = importlib.util.module_from_spec(spec)
spec.loader.exec_module(pair)

class RunnerChecks(unittest.TestCase):
    def test_host_sample_reads_only_names_and_parents(self):
        with tempfile.TemporaryDirectory(dir=HERE) as dirname:
            proc=Path(dirname)
            for pid,name,parent in [(1,'Godot_v4.7.2',22),(2,'ffmpeg',33),(3,'python3',44)]:
                entry=proc/str(pid);entry.mkdir()
                (entry/'comm').write_text(name+'\n')
                (entry/'status').write_text('Name:\t'+name+'\nPPid:\t'+str(parent)+'\n')
            with patch.object(pair,'Path',lambda value: proc if str(value)=='/proc' else Path(value)):
                sample=pair.host_sample()
            self.assertEqual(sorted(sample['processes'],key=lambda x:x['pid']),[
                {'pid':1,'parent':22,'name':'Godot_v4.7.2'}, {'pid':2,'parent':33,'name':'ffmpeg'}])
            self.assertEqual(set(sample),{'unix','load_average','logical_cpus','processes'})

    def test_manifest_rejections(self):
        frozen = {'projects': {'reference': {'head': 'ref', 'source': {'tools/x11_input.py': 'input', 'source': 's'}}},
                  'engine': 'engine', 'artifacts': {'probe_sector_power.gd':'p','prove_sector_power.py':'w','selfcheck_sector_power.py':'t'}}
        artifacts = {'engine':'engine','probe':'p','wrapper':'w','selfcheck':'t','input_helper':'input'}
        baseline = {'head':'ref','source_before':frozen['projects']['reference']['source'],
                    'source_after':frozen['projects']['reference']['source'], 'exit_code':0,'validation_errors':[],
                    'artifacts_before':artifacts,'artifacts_after':artifacts}
        with tempfile.TemporaryDirectory(dir=HERE) as dirname:
            folder=Path(dirname)
            (folder/'journey.json').write_text(json.dumps({'terminal':{'variant':'reference'}}))
            def check(value):
                (folder/'manifest.json').write_text(json.dumps(value))
                return pair.check_run(folder,frozen,'reference')
            check(baseline)
            for key,value in [('head','other'),('exit_code',1),('validation_errors',['bad']),('source_after',{})]:
                changed=copy.deepcopy(baseline);changed[key]=value
                with self.subTest(key=key), self.assertRaises((AssertionError,ValueError)): check(changed)
            for key in ['engine','wrapper','probe','selfcheck','input_helper']:
                changed=copy.deepcopy(baseline)
                changed['artifacts_before'][key]='other';changed['artifacts_after'][key]='other'
                with self.subTest(artifact=key), self.assertRaises((AssertionError,ValueError)):check(changed)

    def test_fixture_changes_are_observable(self):
        import sys
        sys.path.insert(0,str(HERE/'snapshot'))
        from selfcheck_sector_power import terminal_fixture
        baseline=terminal_fixture()
        for group,key,value in [('robot','position_before',[99,0,0]),('robot','yaw_before',9),
                                ('crate','impact',[99,0,0]),('crate','ammo_after',2),('quality',None,True)]:
            changed=copy.deepcopy(baseline)
            if group=='robot':changed['terminal']['robots'][0][key]=value
            elif group=='crate':changed['terminal']['crate_shot'][key]=value
            else:changed['low_quality']=value
            with self.subTest(group=group,key=key):self.assertNotEqual(pair.fixture(baseline),pair.fixture(changed))

if __name__=='__main__': unittest.main()
