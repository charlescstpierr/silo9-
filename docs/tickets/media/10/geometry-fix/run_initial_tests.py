import importlib.util
import sys
import unittest
from pathlib import Path
root = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('geometry_check', root / 'proof-tools-initial/geometry_check.py')
module = importlib.util.module_from_spec(spec)
sys.modules['geometry_check'] = module
spec.loader.exec_module(module)
suite = unittest.defaultTestLoader.discover(str(root / 'proof-tools'), pattern='test_geometry_check.py')
result = unittest.TextTestRunner(verbosity=2).run(suite)
sys.exit(not result.wasSuccessful())
