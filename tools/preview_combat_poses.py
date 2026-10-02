#!/usr/bin/env python3
"""CPU diagnostic renderer of actual Godot-evaluated skinned character poses.

Run animation_contract.gd -- --dump-poses first. Requires numpy/scipy/Pillow.
Not a screenshot of the game renderer: verifies retargeted mesh silhouettes.
"""
import io
import json
import struct
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from scipy.spatial.transform import Rotation

ROOT = Path(__file__).resolve().parents[1]
raw = (ROOT / 'assets/characters/rigged.glb').read_bytes()
size = struct.unpack_from('<I', raw, 12)[0]
data = json.loads(raw[20:20+size])
buf = raw[28+size:]


def accessor(index):
    a = data['accessors'][index]
    view = data['bufferViews'][a['bufferView']]
    dtype = {5126: '<f4', 5123: '<u2', 5125: '<u4', 5121: 'u1'}[a['componentType']]
    dims = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4, 'MAT4': 16}[a['type']]
    return np.frombuffer(buf, dtype, a['count'] * dims,
                         view.get('byteOffset', 0) + a.get('byteOffset', 0)).reshape(-1, dims)


def matrix(node):
    m = np.eye(4)
    m[:3, :3] = Rotation.from_quat(node.get('rotation', [0, 0, 0, 1])).as_matrix() @ np.diag(node.get('scale', [1, 1, 1]))
    m[:3, 3] = node.get('translation', [0, 0, 0])
    return m


parents = {c: i for i, n in enumerate(data['nodes']) for c in n.get('children', [])}
textures = []
for img in data['images']:
    view = data['bufferViews'][img['bufferView']]
    start = view.get('byteOffset', 0)
    textures.append(np.array(Image.open(io.BytesIO(buf[start:start+view['byteLength']])).convert('RGB')))

primitives = []
for ni, node in enumerate(data['nodes']):
    if 'mesh' not in node:
        continue
    for prim in data['meshes'][node['mesh']]['primitives']:
        attrs = prim['attributes']
        pos = accessor(attrs['POSITION'])
        faces = accessor(prim['indices']).reshape(-1, 3).astype(int)
        uv = accessor(attrs['TEXCOORD_0'])[faces].mean(axis=1)
        material = data['materials'][prim['material']]['pbrMetallicRoughness']
        texture = textures[data['textures'][material['baseColorTexture']['index']]['source']]
        pixels = (uv * [texture.shape[1]-1, texture.shape[0]-1]).astype(int)
        pixels = np.clip(pixels, [0, 0], [texture.shape[1]-1, texture.shape[0]-1])
        colors = texture[pixels[:, 1], pixels[:, 0]]
        skin = node.get('skin')
        joints = accessor(attrs['JOINTS_0']).astype(int) if skin is not None else None
        weights = accessor(attrs['WEIGHTS_0']) if skin is not None else None
        primitives.append((ni, pos, faces, colors, skin, joints, weights))


def render(pose, width=220, height=220):
    globals_ = {}

    def visit(i):
        if i not in globals_:
            node = data['nodes'][i]
            name = node.get('name', '').replace(':', '_')
            if name in pose:
                m = matrix(pose[name])
                m[:3, 3] = pose[name]['position']
            else:
                m = matrix(node)
                if i in parents:
                    m = visit(parents[i]) @ m
            globals_[i] = m
        return globals_[i]

    for i in range(len(data['nodes'])):
        visit(i)
    triangles, colors = [], []
    for ni, pos, faces, color, skin_index, joints, weights in primitives:
        verts = np.c_[pos, np.ones(len(pos))]
        if skin_index is not None:
            skin = data['skins'][skin_index]
            ibm = accessor(skin['inverseBindMatrices']).reshape(-1, 4, 4).transpose(0, 2, 1)
            transforms = np.array([globals_[i] @ b for i, b in zip(skin['joints'], ibm)])
            skinned = np.zeros((len(pos), 4))
            for influence in range(4):
                skinned += np.einsum('nij,nj->ni', transforms[joints[:, influence]], verts) * weights[:, influence, None]
        else:
            skinned = verts @ globals_[ni].T
        triangles.append(skinned[faces, :3] * .00978)
        colors.append(color)
    tri = np.concatenate(triangles)
    color = np.concatenate(colors).astype(float)
    # Model faces -Z; view from that side, at a slight three-quarter angle.
    view = Rotation.from_euler('y', -25, degrees=True).as_matrix()
    tri = tri @ view.T
    normals = np.cross(tri[:, 1]-tri[:, 0], tri[:, 2]-tri[:, 0])
    normals /= np.maximum(np.linalg.norm(normals, axis=1, keepdims=True), 1e-8)
    light = np.array([.3, .7, -.6])
    shade = .5 + .5 * np.abs(normals @ light)
    color = np.clip(color * shade[:, None], 0, 255).astype(np.uint8)
    image = Image.new('RGB', (width, height), '#172230')
    draw = ImageDraw.Draw(image)
    ground = height - 12
    draw.line((0, ground, width, ground), fill='#425265')
    scale = (height - 30) / 2.1
    points = np.stack([width/2 + tri[:, :, 0]*scale, ground - tri[:, :, 1]*scale], axis=-1)
    for i in np.argsort(-tri[:, :, 2].mean(axis=1)):
        draw.polygon([tuple(p) for p in points[i]], fill=tuple(color[i]))
    return image


def main():
    poses = json.loads((ROOT / 'tests/animation_poses.json').read_text())
    names = list(poses)
    w, h = 660, 246
    sheet = Image.new('RGB', (w*3, h*((len(names)+2)//3)), '#172230')
    draw = ImageDraw.Draw(sheet)
    for index, name in enumerate(names):
        x, y = (index % 3)*w, (index // 3)*h
        for phase, pose in enumerate(poses[name]):
            sheet.paste(render(pose), (x+phase*220, y+24))
        draw.text((x+12, y+8), name + ' | 0% / 45% / 85%', fill='white')
    dest = ROOT / 'tests/animation_preview.png'
    sheet.save(dest)
    print(dest)


if __name__ == '__main__':
    main()
