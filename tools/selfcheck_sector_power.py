import unittest
from prove_sector_power import validate_result


def valid():
    return {'mode': 'perf', 'failures': [], 'frames_drawn': 150, 'frame_intervals_ms': [16.7] * 120, 'frame_stages': ['walk'] * 120, 'travelled_m': 98, 'waypoints_completed': 8, 'rendering_method': 'gl_compatibility', 'display_driver': 'X11', 'renderer': 'llvmpipe', 'resolution': [1280, 720], 'commands': []}


class ProofValidation(unittest.TestCase):
    def test_valid_rendered_walk(self):
        self.assertEqual(validate_result(valid(), 0, ''), [])

    def test_rejects_failed_or_empty_runtime(self):
        for key, value in [('failures', ['blocked']), ('frames_drawn', 0), ('frame_intervals_ms', []), ('travelled_m', 0), ('waypoints_completed', 0), ('renderer', ''), ('resolution', [640, 480])]:
            with self.subTest(key=key):
                report = valid()
                report[key] = value
                self.assertTrue(validate_result(report, 0, ''))
        self.assertTrue(validate_result(valid(), 1, ''))
        self.assertTrue(validate_result(valid(), 0, 'SCRIPT ERROR: Invalid call'))

    def test_mission_requires_native_breakers_and_ending(self):
        report = valid() | {'mode': 'mission', 'ending': 'mother', 'expected_ending': 'mother', 'health': 52, 'circuits_available': True, 'phase': 4}
        self.assertTrue(validate_result(report, 0, ''))
        report['commands'] = [{'id': 'breaker_' + name, 'native': True, 'aim_valid': True, 'changed': True, 'prompt_changed': True} for name in ['maintenance', 'archives']]
        self.assertEqual(validate_result(report, 0, ''), [])
        report['ending'] = ''
        self.assertTrue(validate_result(report, 0, ''))


if __name__ == '__main__':
    unittest.main()
