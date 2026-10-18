import copy
import unittest
from geometry_check import inspect_dump, compare


def sample(vertices):
    return {
        'schema': 1,
        'meshes': [{'path': 'Art/plate', 'triangles': [vertices]}],
        'segments': [{'name': 'relay', 'from': [0, 1, 0], 'to': [0, 1, -4]}],
        'volumes': [{'name': 'approach', 'min': [-.4, .1, -2.4], 'max': [.4, 1.8, -1.6]}],
        'stats': {'decor': {'mesh_instances': 1, 'triangles': 1}},
        'colliders': [{'type': 'BoxShape3D', 'size': [1, 2, 1], 'transform': [1,0,0,0,1,0,0,0,1,0,1,0], 'layer': 1, 'mask': 1}],
    }


class GeometryCheck(unittest.TestCase):
    def test_plate_before_relay_rejected(self):
        result = inspect_dump(sample([[-1,0,-2],[1,0,-2],[0,2,-2]]))
        self.assertTrue(result['hits']['segment:relay'])

    def test_plate_behind_target_accepted(self):
        result = inspect_dump(sample([[-1,0,-5],[1,0,-5],[0,2,-5]]))
        self.assertFalse(result['hits']['segment:relay'])

    def test_edge_in_reserve_with_origin_outside(self):
        # Triangle centroid x=1.0 lies outside, left edge enters the reserve.
        result = inspect_dump(sample([[0,0,-2],[0,2,-2],[3,1,-2]]))
        self.assertTrue(result['hits']['volume:approach'])

    def test_rotated_triangle_enters_reserve(self):
        # World-space vertices of a plate turned 45 degrees about Y.
        result = inspect_dump(sample([[-.914,0,-3.414],[1.914,0,-.586],[-.914,2,-3.414]]))
        self.assertTrue(result['hits']['volume:approach'])

    def test_aabb_overlap_without_triangle_overlap_is_accepted(self):
        result = inspect_dump(sample([[0,0,-3],[3,0,0],[3,3,-3]]))
        self.assertFalse(result['hits']['volume:approach'])

    def test_malformed_inputs_fail_closed(self):
        for vertices in ([[[0,0,0],[1,1,1]]], [[[0,0,0],[1,1,1],[float('nan'),0,0]]]):
            data = sample([[0,0,0],[1,1,1],[2,2,2]])
            data['meshes'][0]['triangles'] = vertices
            with self.assertRaises(ValueError):
                inspect_dump(data)
        data = sample([[0,0,0],[1,1,1],[2,2,2]])
        del data['segments']
        with self.assertRaises(ValueError):
            inspect_dump(data)

    def test_malformed_collider_rejected(self):
        for change in ({'transform': [1, 2]}, {'layer': '1'}, {'type': 'UnknownShape'}, {'size': [1, -2, 1]}):
            data = sample([[-1,0,-2],[1,0,-2],[0,2,-2]])
            data['colliders'][0].update(change)
            with self.assertRaises(ValueError):
                inspect_dump(data)

    def test_empty_geometry_rejected(self):
        data = sample([[-1,0,-2],[1,0,-2],[0,2,-2]])
        data['meshes'][0]['triangles'] = []
        with self.assertRaises(ValueError):
            inspect_dump(data)

    def test_existing_hits_are_explicit_and_new_hit_is_regression(self):
        before = sample([[-1,0,-2],[1,0,-2],[0,2,-2]])
        after = copy.deepcopy(before)
        same = compare(before, after)
        self.assertTrue(same['bounded_pass'])
        self.assertTrue(same['checks']['segment:relay']['preexisting'])
        after['meshes'][0]['triangles'].append([[-1,0,-3],[1,0,-3],[0,2,-3]])
        self.assertFalse(compare(before, after)['bounded_pass'])

    def test_collider_change_rejected(self):
        before = sample([[-1,0,-5],[1,0,-5],[0,2,-5]])
        after = copy.deepcopy(before)
        after['colliders'][0]['layer'] = 2
        self.assertFalse(compare(before, after)['bounded_pass'])


if __name__ == '__main__':
    unittest.main()
