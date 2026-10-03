#!/usr/bin/env python3
"""Bake original low-poly fan character geometry onto the supplied Mixamo rest rig.

Development pipeline only: no Blender, Python, texture downloads or mesh generation
on the phone. Keeps ONLY the 65 body joint transforms from the user's rig. Does not
copy its geometry, images, facial rig or animations. Character likeness and the
unverified source skeleton keep these files DEVELOPMENT_ONLY.
"""
import json
import math
import struct
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
raw = (ROOT / 'assets/characters/rigged.glb').read_bytes()
length = struct.unpack_from('<I', raw, 12)[0]
source = json.loads(raw[20:20 + length])
joint_nodes = source['skins'][1]['joints']
mapping = {node: index for index, node in enumerate(joint_nodes)}
names = {source['nodes'][node]['name'].split(':')[-1]: index for index, node in enumerate(joint_nodes)}


def matrix(node):
    x, y, z, w = node.get('rotation', [0, 0, 0, 1])
    result = np.eye(4)
    result[:3, :3] = np.array([
        [1-2*y*y-2*z*z, 2*x*y-2*z*w, 2*x*z+2*y*w],
        [2*x*y+2*z*w, 1-2*x*x-2*z*z, 2*y*z-2*x*w],
        [2*x*z-2*y*w, 2*y*z+2*x*w, 1-2*x*x-2*y*y]]) @ np.diag(node.get('scale', [1, 1, 1]))
    result[:3, 3] = node.get('translation', [0, 0, 0])
    return result


nodes = []
parents = {}
for old in joint_nodes:
    original = source['nodes'][old]
    node = {key: original[key] for key in ('name', 'translation', 'rotation', 'scale') if key in original}
    children = [mapping[c] for c in original.get('children', []) if c in mapping]
    if children:
        node['children'] = children
    for child in children:
        parents[child] = mapping[old]
    nodes.append(node)


def world(index):
    local = matrix(nodes[index])
    return world(parents[index]) @ local if index in parents else local


rest = [world(index) for index in range(len(nodes))]
def point(name):
    return rest[names[name]][:3, 3].copy()


SKIN = [0.96, 0.72, 0.57, 1]
DARK = [0.045, 0.065, 0.13, 1]
WHITE = [0.94, 0.94, 0.86, 1]
SILVER = [0.60, 0.70, 0.76, 1]


class Geometry:
    def __init__(self):
        self.positions, self.normals, self.colors, self.joints, self.weights, self.indices = [], [], [], [], [], []

    def vertex(self, pos, normal, color, bones):
        self.positions.append(pos)
        self.normals.append(normal)
        self.colors.append(color)
        self.joints.append([names[bone] for bone, weight in bones] + [0] * (4-len(bones)))
        self.weights.append([weight for bone, weight in bones] + [0] * (4-len(bones)))

    def triangle(self, a, b, c, color, bone):
        normal = np.cross(b-a, c-a)
        normal /= max(np.linalg.norm(normal), 1e-8)
        start = len(self.positions)
        for vertex in (a, b, c):
            self.vertex(vertex, normal, color, [(bone, 1)])
        self.indices.extend([start, start+1, start+2])

    def ellipsoid(self, center, size, color, bone, segments=16, rings=10):
        start = len(self.positions)
        size = np.array(size)
        for ring in range(rings+1):
            phi = math.pi * ring/rings
            for segment in range(segments+1):
                angle = math.tau * segment/segments
                direction = np.array([math.sin(phi)*math.cos(angle), math.cos(phi), math.sin(phi)*math.sin(angle)])
                normal = direction/size
                normal /= np.linalg.norm(normal)
                self.vertex(center+direction*size, normal, color, [(bone, 1)])
        for ring in range(rings):
            for segment in range(segments):
                a = start+ring*(segments+1)+segment
                b = a+segments+1
                self.indices.extend([a, a+1, b, a+1, b+1, b])

    def tube(self, a, b, radius_a, radius_b, color, bone, next_bone=None, segments=12):
        direction = b-a
        axis = direction / np.linalg.norm(direction)
        u = np.cross(axis, [0, 0, 1])
        if np.linalg.norm(u) < .1:
            u = np.cross(axis, [0, 1, 0])
        u /= np.linalg.norm(u)
        v = np.cross(axis, u)
        start = len(self.positions)
        for ring in range(5):
            t = ring/4
            radius = radius_a*(1-t)+radius_b*t
            # Rounded cloth form; leave elbows/knees covered by intersecting caps.
            for segment in range(segments+1):
                angle = math.tau*segment/segments
                radial = math.cos(angle)*u+math.sin(angle)*v
                blend = max(0, (t-.7)/.3)*.35 if next_bone else 0
                bones = [(bone, 1-blend), (next_bone, blend)] if next_bone else [(bone, 1)]
                self.vertex(a+direction*t+radial*radius, radial, color, bones)
        for ring in range(4):
            for segment in range(segments):
                p = start+ring*(segments+1)+segment
                q = p+segments+1
                self.indices.extend([p, p+1, q, p+1, q+1, q])
        for end, radius, sign in [(a, radius_a, -1), (b, radius_b, 1)]:
            for segment in range(segments):
                theta = math.tau*segment/segments
                theta2 = math.tau*(segment+1)/segments
                p = end+radius*(math.cos(theta)*u+math.sin(theta)*v)
                q = end+radius*(math.cos(theta2)*u+math.sin(theta2)*v)
                self.triangle(end, q if sign < 0 else p, p if sign < 0 else q, color, bone)

    def box(self, center, size, color, bone):
        half = np.array(size)*.5
        pts = [center+half*np.array([x, y, z]) for z in [-1, 1] for y in [-1, 1] for x in [-1, 1]]
        for a, b, c, d in [(0,2,3,1),(4,5,7,6),(0,1,5,4),(2,6,7,3),(0,4,6,2),(1,3,7,5)]:
            self.triangle(pts[a], pts[b], pts[c], color, bone)
            self.triangle(pts[a], pts[c], pts[d], color, bone)

    def spike(self, base, tip, radius, color):
        axis = (tip-base)/np.linalg.norm(tip-base)
        u = np.cross(axis, [0, 0, 1])
        if np.linalg.norm(u) < .1:
            u = np.cross(axis, [0, 1, 0])
        u /= np.linalg.norm(u)
        v = np.cross(axis, u)
        for i in range(5):
            a, b = math.tau*i/5, math.tau*(i+1)/5
            p, q = base+radius*(math.cos(a)*u+math.sin(a)*v), base+radius*(math.cos(b)*u+math.sin(b)*v)
            self.triangle(p, q, tip, color, 'Head')
            self.triangle(base, q, p, color, 'Head')


def build(character):
    mesh = Geometry()
    hair = {'naruto':[1,.72,.12,1], 'sasuke':[.035,.055,.11,1], 'sakura':[.92,.39,.53,1], 'kakashi':[.80,.86,.88,1]}[character]
    shirt = {'naruto':[.98,.36,.065,1], 'sasuke':[.10,.21,.52,1], 'sakura':[.72,.07,.16,1], 'kakashi':[.25,.39,.27,1]}[character]
    pants = shirt if character == 'naruto' else WHITE if character == 'sasuke' else DARK
    hip = point('Hips')
    neck = point('Neck')
    head = point('Head')+np.array([0,8,-1])
    slim = .88 if character == 'sakura' else 1
    # Four rings of torso weighted along the spine, one opaque vertex-color surface.
    for bone, next_bone, ra, rb in [('Hips','Spine',11*slim,11.5*slim),('Spine','Spine1',11.5*slim,13*slim),('Spine1','Spine2',13*slim,15*slim)]:
        mesh.tube(point(bone), point(next_bone)+[0,1,0], ra, rb, shirt, bone, next_bone, 16)
    mesh.tube(point('Spine2'), neck, 14*slim, 6, shirt, 'Spine2', 'Neck', 16)
    mesh.ellipsoid(hip+[0,-2,0], [12*slim,8,8], pants, 'Hips')
    mesh.box(point('Spine')+[0,0,-11], [1.1,22,1.1], WHITE if character == 'naruto' else SILVER, 'Spine')
    mesh.tube(neck, point('Head')+[0,3,0], 4.5, 4.5, SKIN, 'Neck', 'Head')
    mesh.ellipsoid(head, [11*slim,14,10], SKIN, 'Head', 24, 16)
    for side in ('Left','Right'):
        shoulder, elbow, hand = point(side+'Arm'), point(side+'ForeArm'), point(side+'Hand')
        sleeve = shirt if character in ('naruto','sasuke') else DARK if character == 'kakashi' else SKIN
        mesh.ellipsoid(shoulder, [6.8,6.8,6.8], sleeve, side+'Arm')
        mesh.tube(shoulder, elbow, 6.5, 5.4, sleeve, side+'Arm', side+'ForeArm')
        mesh.ellipsoid(elbow, [5.4,5.4,5.4], sleeve, side+'ForeArm')
        lower_color = shirt if character == 'naruto' else DARK if character == 'kakashi' else SKIN
        mesh.tube(elbow, hand, 5.4, 3.5, lower_color, side+'ForeArm', side+'Hand')
        hand_end = hand+rest[names[side+'Hand']][:3,1]*6
        mesh.ellipsoid(hand_end, [4.2,6,3.2], SKIN, side+'Hand')
        thigh, knee, ankle = point(side+'UpLeg'), point(side+'Leg'), point(side+'Foot')
        mesh.tube(thigh, knee, 7.7*slim, 5.8*slim, pants, side+'UpLeg', side+'Leg')
        mesh.ellipsoid(knee, [5.9*slim,5.9*slim,5.9*slim], pants, side+'Leg')
        lower = SKIN if character in ('sasuke','sakura') else pants
        mesh.tube(knee, ankle+[0,4,0], 5.8*slim, 3.7*slim, lower, side+'Leg', side+'Foot')
        mesh.ellipsoid(ankle+[0,-8,-4], [4.8,3.6,10], DARK, side+'Foot')
        # Sandal open toe and bandage visible from combat camera distance.
        mesh.ellipsoid(ankle+[0,-8,-11], [4.2,2.7,3.8], SKIN, side+'Foot')
        mesh.tube(knee+[0,-17,0], knee+[0,-25,0], 5.5, 5, WHITE, side+'Leg')
    # Modelled eyes, eyelids, irises and nose. Front of source rig faces -Z.
    for sign in (-1,1):
        eye = head+np.array([sign*4.4,1,-9.3])
        mesh.ellipsoid(eye, [3.2,2.0,1.1], DARK, 'Head', 12, 6)
        mesh.ellipsoid(eye+[0,0,-.6], [2.8,1.55,.7], WHITE, 'Head', 12, 6)
        iris = [.14,.53,.91,1] if character == 'naruto' else [.19,.66,.47,1] if character == 'sakura' else DARK
        mesh.ellipsoid(eye+[0,0,-1.15], [1.15,1.45,.35], iris, 'Head', 12, 6)
        mesh.ellipsoid(eye+[-.25,.6,-1.45], [.34,.40,.2], WHITE, 'Head', 8, 4)
        mesh.box(head+[sign*4.6,4.3,-9.5], [5.5,.55,.6], hair, 'Head')
    mesh.ellipsoid(head+[0,-3,-10], [1.2,2,1.7], SKIN, 'Head', 10, 6)
    mesh.box(head+[0,-7,-8.9], [4,.48,.6], [.45,.23,.22,1], 'Head')
    mesh.ellipsoid(head+[0,8,1], [11.4*slim,8.5,10.5], hair, 'Head', 20, 10)
    if character == 'sakura':
        for sign in (-1,1):
            mesh.ellipsoid(head+[sign*10.2,0,2], [3.2,15,7], hair, 'Head')
        mesh.ellipsoid(head+[0,0,8], [10.5,14,4], hair, 'Head')
        mesh.tube(hip+[0,-9,0], hip+[0,6,0], 16, 11.8, shirt, 'Hips', 'Spine', 16)
        mesh.box(head+[0,11,-6], [16,2.4,2], DARK, 'Head')
    else:
        count = 13 if character == 'naruto' else 10
        for i in range(count):
            angle = math.tau*i/count
            base = head+np.array([math.cos(angle)*8.2,9,math.sin(angle)*7.4])
            shift = -5 if character == 'kakashi' else 0
            tip = base+np.array([math.cos(angle)*6+shift,6+(i%3)*2,math.sin(angle)*5])
            mesh.spike(base,tip,4,hair)
        if character == 'sasuke':
            for sign in (-1,1):
                mesh.spike(head+[sign*8,7,-5],head+[sign*9,-7,-8],3.8,hair)
        band = head+[0,7,-9.2]
        mesh.box(band, [20,4.1,2.8], DARK, 'Head')
        mesh.box(band+[0,0,-1.6], [12,3.4,.6], SILVER, 'Head')
        # Generic original engraved motif, not copied game artwork.
        mesh.box(band+[0,0,-2], [4,.5,.2], DARK, 'Head')
        if character == 'kakashi':
            mesh.ellipsoid(head+[0,-5,-6.8], [10,7,4], DARK, 'Head')
            mesh.box(head+[4.5,4,-10], [8,8,1.4], DARK, 'Head')
            for sign in (-1,1):
                mesh.box(point('Spine1')+[sign*7,1,-16], [5.8,10,2.3], [.33,.47,.31,1], 'Spine1')
        elif character == 'naruto':
            for sign in (-1,1):
                for i in range(3):
                    mesh.box(head+[sign*7,-3-i*1.4,-8], [3,.34,.5], [.43,.24,.17,1], 'Head')
            mesh.tube(point('Spine2')+[0,6,0], neck+[0,1,0], 8.8, 7, DARK, 'Spine2')
            for sign in (-1,1):
                mesh.ellipsoid(point('Spine2')+[sign*9,5,-3], [7,4,8], [.10,.22,.48,1], 'Spine2')
    return mesh


def export(character, mesh):
    binary = bytearray()
    views, accessors = [], []
    def buffer(data, dtype, kind, component):
        array = np.asarray(data, dtype=dtype)
        binary.extend(b'\0' * (-len(binary)%4))
        start = len(binary)
        binary.extend(array.tobytes())
        views.append({'buffer':0,'byteOffset':start,'byteLength':array.nbytes})
        accessor = {'bufferView':len(views)-1,'componentType':component,'count':len(array),'type':kind}
        if kind == 'VEC3':
            accessor.update(min=array.min(axis=0).tolist(), max=array.max(axis=0).tolist())
        accessors.append(accessor)
        return len(accessors)-1
    attrs = {name:buffer(values,dtype,kind,component) for name,values,dtype,kind,component in [
        ('POSITION',mesh.positions,'<f4','VEC3',5126),('NORMAL',mesh.normals,'<f4','VEC3',5126),
        ('COLOR_0',mesh.colors,'<f4','VEC4',5126),('JOINTS_0',mesh.joints,'<u2','VEC4',5123),('WEIGHTS_0',mesh.weights,'<f4','VEC4',5126)]}
    indices = buffer(mesh.indices,'<u2','SCALAR',5123)
    inverse = buffer([np.linalg.inv(m).T.flatten() for m in rest],'<f4','MAT4',5126)
    times = buffer([0,1],'<f4','SCALAR',5126)
    positions = buffer([nodes[0]['translation']]*2,'<f4','VEC3',5126)
    output_nodes = json.loads(json.dumps(nodes))
    output_nodes.append({'name':'FighterMesh','mesh':0,'skin':0})
    output_nodes.append({'name':'FighterRig','children':[0,len(nodes)]})
    document = {'asset':{'version':'2.0','generator':'Original stylized fan geometry / create_stylized_fighters.py'},
        'scene':0,'scenes':[{'nodes':[len(nodes)+1]}],'nodes':output_nodes,
        'skins':[{'name':'MixamoBody','joints':list(range(len(nodes))),'inverseBindMatrices':inverse,'skeleton':0}],
        'meshes':[{'name':character,'primitives':[{'attributes':attrs,'indices':indices,'material':0}]}],
        'materials':[{'name':'OriginalVertexColors','doubleSided':False,'pbrMetallicRoughness':{'baseColorFactor':[1,1,1,1],'metallicFactor':0,'roughnessFactor':.85}}],
        'animations':[{'name':'bind_pose','samplers':[{'input':times,'output':positions,'interpolation':'LINEAR'}],
            'channels':[{'sampler':0,'target':{'node':0,'path':'translation'}}]}],
        'buffers':[{'byteLength':len(binary)}],'bufferViews':views,'accessors':accessors}
    encoded = json.dumps(document,separators=(',',':')).encode()
    encoded += b' ' * (-len(encoded)%4)
    binary.extend(b'\0' * (-len(binary)%4))
    result = struct.pack('<III',0x46546c67,2,28+len(encoded)+len(binary))+struct.pack('<II',len(encoded),0x4e4f534a)+encoded+struct.pack('<II',len(binary),0x004e4942)+binary
    destination = ROOT/f'assets/characters/stylized/{character}.glb'
    destination.parent.mkdir(parents=True,exist_ok=True)
    destination.write_bytes(result)
    print(f'{character}: {len(mesh.positions)} vertices, {len(mesh.indices)//3} triangles, {len(result)} bytes, {len(nodes)} skin joints')


if __name__ == '__main__':
    for character in ('naruto','sasuke','sakura','kakashi'):
        export(character,build(character))
