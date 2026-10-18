"""Bounded, world-space triangle checks. No dependency outside Python stdlib."""
import collections
import hashlib
import json
import math
import sys

EPS = 1e-7


def sub(a, b):
    return tuple(x-y for x, y in zip(a, b))


def dot(a, b):
    return sum(x*y for x, y in zip(a, b))


def cross(a, b):
    return (a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0])


def bounds(vertices):
    return tuple(min(p[i] for p in vertices) for i in range(3)), tuple(max(p[i] for p in vertices) for i in range(3))


def overlap(a, b):
    return all(a[0][i] <= b[1][i]+EPS and b[0][i] <= a[1][i]+EPS for i in range(3))


def triangle_box(tri, low, high):
    # Separating-axis theorem: 3 box axes, triangle normal, 9 edge cross axes.
    center = tuple((a+b)/2 for a, b in zip(low, high))
    half = tuple((b-a)/2 for a, b in zip(low, high))
    points = [sub(p, center) for p in tri]
    edges = [sub(points[(i+1)%3], points[i]) for i in range(3)]
    axes = [(1,0,0), (0,1,0), (0,0,1)]
    axes += [cross(edges[0], edges[1])] + [cross(edge, axis) for edge in edges for axis in axes[:3]]
    for axis in axes:
        radius = dot(half, tuple(abs(x) for x in axis))
        projections = [dot(p, axis) for p in points]
        if min(projections) > radius+EPS or max(projections) < -radius-EPS:
            return False
    return True


def segment_triangle(start, end, tri):
    # Two-sided Moller-Trumbore, parameter restricted to this segment.
    direction = sub(end, start)
    edge1, edge2 = sub(tri[1], tri[0]), sub(tri[2], tri[0])
    normal = cross(edge1, edge2)
    if dot(normal, normal) < EPS*EPS:
        return False
    h = cross(direction, edge2)
    determinant = dot(edge1, h)
    if abs(determinant) < EPS:
        # Coplanar segments use a conservative bound, never silently pass.
        return abs(dot(sub(start, tri[0]), normal)) < EPS and overlap(bounds([start,end]), bounds(tri))
    s = sub(start, tri[0])
    u = dot(s, h)/determinant
    q = cross(s, edge1)
    v = dot(direction, q)/determinant
    t = dot(edge2, q)/determinant
    return -EPS <= u <= 1+EPS and v >= -EPS and u+v <= 1+EPS and EPS < t < 1-EPS


def vector(value):
    if not isinstance(value, list) or len(value) != 3 or not all(type(x) in (int,float) and math.isfinite(x) for x in value):
        raise ValueError('Expected three finite coordinates')


def validate(data):
    if not isinstance(data, dict) or data.get('schema') != 1:
        raise ValueError('Unsupported geometry dump schema')
    for key in ('meshes','segments','volumes','colliders'):
        if not isinstance(data.get(key), list) or not data[key]:
            raise ValueError('Missing or empty '+key)
    if not isinstance(data.get('stats'), dict) or not data['stats']:
        raise ValueError('Missing stats')
    for mesh in data['meshes']:
        if not isinstance(mesh, dict) or not isinstance(mesh.get('path'), str) or not isinstance(mesh.get('triangles'), list):
            raise ValueError('Malformed mesh')
        for tri in mesh['triangles']:
            if not isinstance(tri, list) or len(tri) != 3:
                raise ValueError('Expected triangle')
            for p in tri:
                vector(p)
    if not any(mesh['triangles'] for mesh in data['meshes']):
        raise ValueError('No extracted triangle geometry')
    for collider in data['colliders']:
        if not isinstance(collider, dict) or collider.get('type') not in ('BoxShape3D','SphereShape3D','CapsuleShape3D','CylinderShape3D'):
            raise ValueError('Unsupported collider record')
        transform = collider.get('transform')
        if not isinstance(transform,list) or len(transform) != 12 or not all(type(x) in (int,float) and math.isfinite(x) for x in transform):
            raise ValueError('Invalid collider transform')
        if any(type(collider.get(key)) is not int or not 0 <= collider[key] < 2**32 for key in ('layer','mask')):
            raise ValueError('Invalid collider layers/masks')
        if collider['type'] == 'BoxShape3D':
            vector(collider.get('size'))
            if any(x <= 0 for x in collider['size']):
                raise ValueError('Invalid box dimensions')
        else:
            for key in ('radius',) if collider['type'] == 'SphereShape3D' else ('radius','height'):
                value = collider.get(key)
                if type(value) not in (int,float) or not math.isfinite(value) or value <= 0:
                    raise ValueError('Invalid collider dimensions')
    names = set()
    for kind, first, last in [('segments','from','to'),('volumes','min','max')]:
        for check in data[kind]:
            if not isinstance(check, dict) or not isinstance(check.get('name'), str) or not check['name'] or (kind,check['name']) in names:
                raise ValueError('Missing or duplicate check name')
            names.add((kind,check['name']))
            vector(check.get(first))
            vector(check.get(last))
            if kind == 'segments' and check[first] == check[last]:
                raise ValueError('Zero-length segment')
            if kind == 'volumes' and any(a >= b for a,b in zip(check[first],check[last])):
                raise ValueError('Empty reserve')
    # Fingerprints must never silently encode NaN/Infinity.
    try:
        json.dumps(data['colliders'], allow_nan=False)
        json.dumps(data['stats'], allow_nan=False)
    except (TypeError, ValueError) as error:
        raise ValueError('Malformed colliders or statistics') from error


def triangle_key(tri):
    # Ignore batching/node IDs and triangle winding; retain world geometry.
    return json.dumps(sorted([round(x,6) for x in point] for point in tri), separators=(',',':'))


def inspect_dump(data):
    validate(data)
    checks = []
    for s in data['segments']:
        checks.append(('segment:'+s['name'], bounds([s['from'],s['to']]), lambda tri, s=s: segment_triangle(s['from'],s['to'],tri)))
    for v in data['volumes']:
        checks.append(('volume:'+v['name'], (v['min'],v['max']), lambda tri, v=v: triangle_box(tri,v['min'],v['max'])))
    hits = {name: {} for name, _, _ in checks}
    for mesh in data['meshes']:
        if not mesh['triangles']:
            continue
        mesh_bounds = bounds([p for tri in mesh['triangles'] for p in tri])
        nearby = [(name,box,test) for name,box,test in checks if overlap(mesh_bounds,box)]
        for tri in mesh['triangles']:
            tri_bounds = bounds(tri)
            for name, box, test in nearby:
                if overlap(tri_bounds,box) and test(tri):
                    key = triangle_key(tri)
                    hits[name].setdefault(key, {'triangle': tri, 'meshes': []})['meshes'].append(mesh['path'])
    return {'hits': hits, 'stats': data['stats']}


def collider_fingerprint(colliders):
    entries = sorted(json.dumps(c,sort_keys=True,separators=(',',':')) for c in colliders)
    return hashlib.sha256('\n'.join(entries).encode()).hexdigest(), collections.Counter(entries)


def compare(before, after):
    a, b = inspect_dump(before), inspect_dump(after)
    if before['segments'] != after['segments'] or before['volumes'] != after['volumes']:
        raise ValueError('Compared snapshots must use identical targets and reserves')
    checks = {}
    for name, old in a['hits'].items():
        new = b['hits'][name]
        checks[name] = {
            'preexisting': [old[k] for k in sorted(old)],
            'remaining': [new[k] for k in sorted(old.keys() & new.keys())],
            'removed': [old[k] for k in sorted(old.keys()-new.keys())],
            'added': [new[k] for k in sorted(new.keys()-old.keys())],
        }
    old_hash, old_shapes = collider_fingerprint(before['colliders'])
    new_hash, new_shapes = collider_fingerprint(after['colliders'])
    return {
        'bounded_pass': old_hash == new_hash and all(not c['added'] for c in checks.values()),
        'checks': checks,
        'stats_before': a['stats'], 'stats_after': b['stats'],
        'colliders': {'before_sha256':old_hash,'after_sha256':new_hash,'equal':old_hash==new_hash,
                      'removed':list((old_shapes-new_shapes).elements()),'added':list((new_shapes-old_shapes).elements())},
        'limits': ['Only exported WorldArt triangle surfaces and declared segments/reserves are checked.',
                   'Coplanar segment overlap is conservative; inspect any reported candidate.',
                   'A reserve entirely enclosed by a closed mesh without surface crossing is not detected.',
                   'No assertion about pixels, shadows, animation, all firing angles, or universal visibility.'],
    }


if __name__ == '__main__':
    try:
        if len(sys.argv) != 4:
            raise ValueError('Usage: geometry_check.py BASE.json CANDIDATE.json REPORT.json')
        with open(sys.argv[1]) as f:
            before = json.load(f)
        with open(sys.argv[2]) as f:
            after = json.load(f)
        result = compare(before, after)
        with open(sys.argv[3], 'w') as f:
            json.dump(result, f, indent=2, allow_nan=False)
        print(json.dumps({'bounded_pass':result['bounded_pass'], 'colliders_equal':result['colliders']['equal'],
                          'checks':{k:{category:len(v[category]) for category in ('preexisting','remaining','removed','added')} for k,v in result['checks'].items()}}))
        sys.exit(0 if result['bounded_pass'] else 1)
    except (ValueError, KeyError, TypeError, OSError) as error:
        print('Invalid geometry evidence: '+str(error), file=sys.stderr)
        sys.exit(2)
