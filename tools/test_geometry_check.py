import copy
import unittest
from geometry_check import inspect_dump, compare, segment_triangle, triangle_box


OBJECTS = ('relay', 'breaker_maintenance', 'breaker_archives', 'n7', 'evidence',
           'component_0', 'component_1', 'component_2')
ENEMIES = ('sentinel_1', 'crawler_1', 'sentinel_2', 'crawler_2')
SEGMENTS = OBJECTS + tuple('combat_' + name for name in ENEMIES)
VOLUMES = (tuple('approach_' + name for name in OBJECTS) + ('central_route', 'arc_bypass')
           + tuple('patrol_' + name for name in ENEMIES)
           + tuple('door_sweep_' + room + '_' + leaf for room in ('maintenance', 'archives')
                   for leaf in ('SasGauche', 'SasDroit')))
TRANSFORM = [1,0,0,0,1,0,0,0,1,0,1,0]


def sample(vertices):
    """Complete synthetic capture; math-only cases call the intersection functions."""
    return {
        'schema': 1,
        'project': '/synthetic/silo9/',
        'engine': {'major': 4, 'minor': 5, 'patch': 1, 'string': '4.5.1.stable'},
        'source_sha256': {path: 'a' * 64 for path in (
            'scripts/world_art.gd', 'scripts/world.gd', 'scripts/player.gd',
            'scripts/data/power_consumers.gd', 'tests/test_journey.gd')},
        'measurement': 'Synthetic constructed geometry fixture.',
        'meshes': [{'path': 'Art/plate', 'triangles': [vertices]}],
        'segments': [{'name': name, 'from': [0,1,0], 'to': [0,1,-4]} for name in SEGMENTS],
        'volumes': [{'name': name, 'min': [-.4,.1,-2.4], 'max': [.4,1.8,-1.6]} for name in VOLUMES],
        'targets': [{'id': name, 'transform': TRANSFORM[:], 'aim': [0,1,-4],
                     'eye_offset': [0,1,0], 'approach_source': 'Synthetic fixture'} for name in OBJECTS],
        'stats': {'decor': {'mesh_instances': 1, 'multimesh_nodes': 0, 'instances': 1,
                            'surfaces': 1, 'triangles': 1}},
        'mesh_inventory': [{'path': 'Art/plate', 'group': 'decor', 'kind': 'MeshInstance',
                            'instances': 1, 'surfaces_per_instance': 1, 'triangles_per_instance': 1,
                            'visible_in_tree': True, 'visibility_range_end': 0}],
        'colliders': [{'type': 'BoxShape3D', 'size': [1,2,1], 'transform': TRANSFORM[:],
                       'layer': 1, 'mask': 1, 'disabled': False, 'margin': .04}],
    }


def add_triangle(data, triangle):
    data['meshes'][0]['triangles'].append(triangle)
    data['stats']['decor']['triangles'] += 1
    data['mesh_inventory'][0]['triangles_per_instance'] += 1


class GeometryCheck(unittest.TestCase):
    def test_plate_before_relay_rejected(self):
        self.assertTrue(segment_triangle([0,1,0], [0,1,-4], [[-1,0,-2],[1,0,-2],[0,2,-2]]))

    def test_plate_behind_target_accepted(self):
        self.assertFalse(segment_triangle([0,1,0], [0,1,-4], [[-1,0,-5],[1,0,-5],[0,2,-5]]))

    def test_edge_in_reserve_with_origin_outside(self):
        # Triangle centroid x=1.0 lies outside, left edge enters the reserve.
        self.assertTrue(triangle_box([[0,0,-2],[0,2,-2],[3,1,-2]], [-.4,.1,-2.4], [.4,1.8,-1.6]))

    def test_rotated_triangle_enters_reserve(self):
        self.assertTrue(triangle_box([[-.914,0,-3.414],[1.914,0,-.586],[-.914,2,-3.414]],
                                     [-.4,.1,-2.4], [.4,1.8,-1.6]))

    def test_aabb_overlap_without_triangle_overlap_is_accepted(self):
        self.assertFalse(triangle_box([[0,0,-3],[3,0,0],[3,3,-3]], [-.4,.1,-2.4], [.4,1.8,-1.6]))

    def assert_invalid(self, data):
        # Identical corruption in both captures must never receive bounded_pass.
        with self.assertRaises(ValueError):
            compare(data, copy.deepcopy(data))

    def test_complete_capture_passes_all_thirty_checks(self):
        data = sample([[-1,0,-5],[1,0,-5],[0,2,-5]])
        result = compare(data, copy.deepcopy(data))
        self.assertTrue(result['bounded_pass'])
        self.assertEqual(len(result['checks']), 30)

    def test_exact_catalogue_required(self):
        for kind in ('segments', 'volumes'):
            for index in range(len(sample([])[kind])):
                for mode in ('remove', 'replace', 'duplicate', 'extra'):
                    with self.subTest(kind=kind, index=index, mode=mode):
                        data = sample([[-1,0,-5],[1,0,-5],[0,2,-5]])
                        if mode == 'remove':
                            del data[kind][index]
                        elif mode == 'replace':
                            data[kind][index]['name'] = 'unexpected'
                        elif mode == 'duplicate':
                            data[kind][index]['name'] = data[kind][(index+1) % len(data[kind])]['name']
                        else:
                            extra = copy.deepcopy(data[kind][index])
                            extra['name'] = 'unexpected'
                            data[kind].append(extra)
                        self.assert_invalid(data)

    def test_required_capture_fields(self):
        for key in ('project', 'engine', 'source_sha256', 'measurement', 'targets', 'mesh_inventory'):
            for mode in ('missing', 'empty'):
                with self.subTest(key=key, mode=mode):
                    data = sample([[-1,0,-5],[1,0,-5],[0,2,-5]])
                    if mode == 'missing':
                        del data[key]
                    else:
                        data[key] = type(data[key])()
                    self.assert_invalid(data)

    def test_invalid_capture_records(self):
        for key, value in (
            ('project', 'relative/path'), ('engine', {'string': '4.5.1'}),
            ('source_sha256', {'scripts/world.gd': 'invalid'}),
            ('measurement', 123), ('targets', [{}]), ('mesh_inventory', [{}]),
        ):
            with self.subTest(key=key):
                data = sample([[-1,0,-5],[1,0,-5],[0,2,-5]])
                data[key] = value
                self.assert_invalid(data)

    def test_target_catalogue_and_aim_consistency(self):
        for mutation in ('missing', 'duplicate', 'wrong_aim', 'bad_transform', 'bad_eye'):
            with self.subTest(mutation=mutation):
                data = sample([[-1,0,-5],[1,0,-5],[0,2,-5]])
                if mutation == 'missing':
                    data['targets'].pop()
                elif mutation == 'duplicate':
                    data['targets'][0]['id'] = data['targets'][1]['id']
                elif mutation == 'wrong_aim':
                    data['targets'][0]['aim'] = [8,9,10]
                elif mutation == 'bad_transform':
                    data['targets'][0]['transform'] = [1]
                else:
                    data['targets'][0]['eye_offset'] = [float('inf'),0,0]
                self.assert_invalid(data)

    def test_malformed_inputs_fail_closed(self):
        for vertices in ([[[0,0,0],[1,1,1]]], [[[0,0,0],[1,1,1],[float('nan'),0,0]]]):
            data = sample([[0,0,0],[1,1,1],[2,2,2]])
            data['meshes'][0]['triangles'] = vertices
            self.assert_invalid(data)

    def test_malformed_collider_rejected(self):
        for change in ({'transform': [1,2]}, {'layer': '1'}, {'type': 'UnknownShape'},
                       {'size': [1,-2,1]}, {'disabled': 'not a bool'}, {'disabled': 0},
                       {'margin': -10}, {'margin': True}, {'margin': float('nan')}):
            with self.subTest(change=change):
                data = sample([[-1,0,-2],[1,0,-2],[0,2,-2]])
                data['colliders'][0].update(change)
                self.assert_invalid(data)
        for key in ('disabled', 'margin'):
            data = sample([[-1,0,-2],[1,0,-2],[0,2,-2]])
            del data['colliders'][0][key]
            self.assert_invalid(data)

    def test_statistics_require_all_nonnegative_integral_counts(self):
        for key in ('mesh_instances', 'multimesh_nodes', 'instances', 'surfaces', 'triangles'):
            for value in (-999, .5, True, '1', float('inf'), None):
                with self.subTest(key=key, value=value):
                    data = sample([[-1,0,-5],[1,0,-5],[0,2,-5]])
                    data['stats']['decor'][key] = value
                    self.assert_invalid(data)
            data = sample([[-1,0,-5],[1,0,-5],[0,2,-5]])
            del data['stats']['decor'][key]
            self.assert_invalid(data)

    def test_triangle_count_and_inventory_must_match_export(self):
        for mutation in ('stats', 'inventory_count', 'inventory_path', 'inventory_visibility',
                         'inventory_range', 'inventory_kind', 'extra_mesh'):
            with self.subTest(mutation=mutation):
                data = sample([[-1,0,-5],[1,0,-5],[0,2,-5]])
                if mutation == 'stats':
                    data['stats']['decor']['triangles'] = 2
                elif mutation == 'extra_mesh':
                    data['meshes'].append(copy.deepcopy(data['meshes'][0]))
                else:
                    key, value = {
                        'inventory_count': ('triangles_per_instance', 2),
                        'inventory_path': ('path', 'Unknown'),
                        'inventory_visibility': ('visible_in_tree', 'true'),
                        'inventory_range': ('visibility_range_end', -1),
                        'inventory_kind': ('kind', 'Unknown'),
                    }[mutation]
                    data['mesh_inventory'][0][key] = value
                self.assert_invalid(data)

    def test_integral_json_float_counts_and_multimesh_supported(self):
        data = sample([[-1,0,-5],[1,0,-5],[0,2,-5]])
        data['stats']['decor'].update(mesh_instances=0.0, multimesh_nodes=1.0)
        data['mesh_inventory'][0].update(kind='MultiMesh', declared_visible_instances=-1,
                                         instances=1.0, triangles_per_instance=1.0)
        self.assertTrue(compare(data, copy.deepcopy(data))['bounded_pass'])
        for value in (-2, 2, True, .5):
            with self.subTest(value=value):
                invalid = copy.deepcopy(data)
                invalid['mesh_inventory'][0]['declared_visible_instances'] = value
                self.assert_invalid(invalid)

    def test_empty_geometry_rejected(self):
        data = sample([[-1,0,-2],[1,0,-2],[0,2,-2]])
        data['meshes'][0]['triangles'] = []
        self.assert_invalid(data)

    def test_existing_hits_are_explicit_and_new_hit_is_regression(self):
        before = sample([[-1,0,-2],[1,0,-2],[0,2,-2]])
        after = copy.deepcopy(before)
        same = compare(before, after)
        self.assertTrue(same['bounded_pass'])
        self.assertTrue(same['checks']['segment:relay']['preexisting'])
        add_triangle(after, [[-1,0,-3],[1,0,-3],[0,2,-3]])
        self.assertFalse(compare(before, after)['bounded_pass'])

    def test_collider_change_rejected(self):
        before = sample([[-1,0,-5],[1,0,-5],[0,2,-5]])
        for change in ({'layer': 2}, {'disabled': True}, {'margin': .05}):
            after = copy.deepcopy(before)
            after['colliders'][0].update(change)
            self.assertFalse(compare(before, after)['bounded_pass'])


if __name__ == '__main__':
    unittest.main()
