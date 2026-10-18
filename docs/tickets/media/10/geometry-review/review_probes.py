"""Independent pure-Python review probes; production proof tools stay unchanged."""
import copy
import random
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'proof-tools'))
from geometry_check import compare, triangle_box, segment_triangle
from test_geometry_check import sample


def clipped_triangle_intersects(triangle, low, high):
    polygon = triangle
    for axis in range(3):
        for limit, sign in ((low[axis], 1), (high[axis], -1)):
            result = []
            for first, second in zip(polygon, polygon[1:] + polygon[:1]):
                a = (first[axis] - limit) * sign
                b = (second[axis] - limit) * sign
                if a >= 0:
                    result.append(first)
                if (a >= 0) != (b >= 0):
                    t = a / (a-b)
                    result.append([x + t*(y-x) for x,y in zip(first,second)])
            polygon = result
            if not polygon:
                return False
    return True


rng = random.Random(1042)
for i in range(10000):
    tri = [[rng.uniform(-4,4) for _ in range(3)] for _ in range(3)]
    low, high = [-.4,.1,-2.4], [.4,1.8,-1.6]
    assert triangle_box(tri,low,high) == clipped_triangle_intersects(tri,low,high), (i,tri)
print('PASS: 10000 SAT cases agree with independent polygon clipping, seed=1042')

for z in (-2,-5,1):
    tri = [[-1,0,z],[1,0,z],[0,2,z]]
    for winding in (tri, list(reversed(tri))):
        for start,end in (([0,1,0],[0,1,-4]),([0,1,-4],[0,1,0])):
            assert segment_triangle(start,end,winding) == (z == -2)
print('PASS: bounded segment rejects behind both ends, both directions and windings')

base = sample([[-1,0,-5],[1,0,-5],[0,2,-5]])
assert compare(base,copy.deepcopy(base))['bounded_pass']
print('REPRO R1: one segment, one volume, no engine/source/targets/inventory => bounded_pass=true')
invalid = copy.deepcopy(base)
invalid['colliders'][0].update(disabled='not a bool', margin=-10)
invalid['stats'] = {'decor': {'triangles': -999}}
assert compare(invalid,copy.deepcopy(invalid))['bounded_pass']
print('REPRO R1: invalid disabled/margin and negative stats also accepted')

preexisting = sample([[-1,0,-2],[1,0,-2],[0,2,-2]])
retessellated = copy.deepcopy(preexisting)
retessellated['meshes'][0]['triangles'] = [
    [[-1,0,-2],[1,0,-2],[0,1,-2]],
    [[1,0,-2],[0,2,-2],[0,1,-2]],
    [[0,2,-2],[-1,0,-2],[0,1,-2]],
]
result = compare(preexisting,retessellated)
assert not result['bounded_pass']
print('PASS: identical occupied triangle surface retessellated reports added hits, consistent with declared limitation')

print('Tool review probes completed. R1 is reproduced; no runtime claim.')
