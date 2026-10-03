#!/usr/bin/env python3
"""Render Godot-exported world geometry on CPU. Layout diagnostic, not a GPU screenshot."""
import argparse
import json
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('geometry', type=Path)
parser.add_argument('output', type=Path)
args = parser.parse_args()
data = json.loads(args.geometry.read_text())
tri = np.concatenate([np.array(x['vertices']).reshape(-1, 3, 3) for x in data])
colors = np.concatenate([np.array(x['colors']).reshape(-1, 3, 3).mean(axis=1) for x in data])
eye = np.array([94., 86., 114.])
focus = np.array([0., 5., -3.])
forward = (focus-eye) / np.linalg.norm(focus-eye)
right = np.cross(forward, [0., 1., 0.]); right /= np.linalg.norm(right)
up = np.cross(right, forward)
relative = tri - eye
view = np.stack([relative @ right, relative @ up, relative @ forward], axis=-1)
w, h = 1280, 960
points = np.stack([w/2 + view[:, :, 0]*1250/view[:, :, 2], h/2 - view[:, :, 1]*1250/view[:, :, 2]], axis=-1)
normals = np.cross(tri[:, 1]-tri[:, 0], tri[:, 2]-tri[:, 0])
normals /= np.maximum(np.linalg.norm(normals, axis=1, keepdims=True), 1e-8)
light = np.array([.3, .8, .4]); light /= np.linalg.norm(light)
colors = np.clip(colors * (.65+.35*np.abs(normals @ light))[:, None]*255, 0, 255).astype(np.uint8)
canvas = Image.new('RGB', (w, h), '#adcbd0')
draw = ImageDraw.Draw(canvas)
for i in np.argsort(-view[:, :, 2].mean(axis=1)):
    if np.all(view[i, :, 2] > 0):
        draw.polygon([tuple(x) for x in points[i]], fill=tuple(colors[i]))
draw.rectangle((0, 0, w, 36), fill='#243a40')
draw.text((16, 12), 'ORIGINAL VILLAGE GEOMETRY - CPU LAYOUT DIAGNOSTIC / NOT ANDROID GPU CAPTURE', fill='#fff1ce')
canvas.save(args.output)
print(args.output)
