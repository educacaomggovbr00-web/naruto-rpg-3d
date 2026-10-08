#!/usr/bin/env python3
"""Fit the supplied Henrique chibi mesh to the existing combat skeleton.

Requires numpy/scipy/Pillow and gltfpack 1.3. Original ZIP stays outside Git.
Landmarks are specific to this upload, in centimeters facing -Z.
"""
import argparse
import hashlib
import json
import subprocess
import tempfile
from pathlib import Path

import numpy as np
from scipy.spatial.transform import Rotation
import rig_base_basic_models as base
from refine_henrique_weights import refine

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / 'assets/characters/henrique'
SOURCE_SHA = '701a61f74ba02666bd672df53ea88000ccdb71d994e38dfd16dd942ac8505852'
LANDMARKS = {
    'Hips': [0, 69, 12], 'Spine': [0, 80, 12], 'Spine1': [0, 94, 12],
    'Spine2': [0, 107, 12], 'Neck': [0, 118, 10], 'Head': [0, 130, 0],
    'HeadTop_End': [0, 167, 0],
    'LeftShoulder': [-9, 109, 12], 'LeftArm': [-19, 107, 12],
    'LeftForeArm': [-24, 90, 12], 'LeftHand': [-23, 73, 10],
    'RightShoulder': [9, 109, 12], 'RightArm': [19, 107, 12],
    'RightForeArm': [24, 90, 12], 'RightHand': [23, 73, 10],
    'LeftUpLeg': [-13, 66, 12], 'LeftLeg': [-23, 36, 12],
    'LeftFoot': [-32, 9, 10], 'LeftToeBase': [-33, 3, -8], 'LeftToe_End': [-33, 3, -17],
    'RightUpLeg': [13, 66, 12], 'RightLeg': [23, 36, 12],
    'RightFoot': [32, 9, 10], 'RightToeBase': [33, 3, -8], 'RightToe_End': [33, 3, -17],
}


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--source', type=Path, required=True)
    p.add_argument('--gltfpack', default='gltfpack')
    args = p.parse_args()
    original = base.GLB(args.source)
    if hashlib.sha256(original.raw).hexdigest() != SOURCE_SHA:
        raise ValueError('Expected the PBR GLB from 3970037e-fd4c-4114-b9f6-75905e547ff4.zip')
    version = subprocess.run([args.gltfpack, '-v'], check=True, capture_output=True, text=True)
    if (version.stdout + version.stderr).strip() != 'gltfpack 1.3':
        raise ValueError('Use gltfpack 1.3')
    with tempfile.TemporaryDirectory() as tmp:
        simple = Path(tmp) / 'mobile.glb'
        subprocess.run([args.gltfpack, '-i', str(args.source), '-o', str(simple),
                        '-si', '0.22', '-se', '0.008', '-sp', '-sv', '-noq'], check=True)
        source = base.GLB(simple)
    attr = source.data['meshes'][0]['primitives'][0]['attributes']
    primitive = source.data['meshes'][0]['primitives'][0]
    orientation = np.array([-1, 1, -1])
    positions = source.accessor(attr['POSITION']).astype(float) * 100 * orientation
    normals = source.accessor(attr['NORMAL']).astype(float) * orientation
    names, index, parents, reference = base.combat_bind(base.GLB(ROOT / 'assets/characters/rigged.glb'))
    # Preserve chibi proportions, with a conventional T-pose for animation deltas.
    target = reference.copy()
    target_landmarks = dict(LANDMARKS)
    for side, sign in [('Left', -1), ('Right', 1)]:
        target_landmarks[side + 'ForeArm'] = [sign * 37, 107, 12]
        target_landmarks[side + 'Hand'] = [sign * 54, 107, 12]
    for i, name in enumerate(names):
        if name in target_landmarks:
            target[i, :3, 3] = target_landmarks[name]
        else:
            parent = parents[i]
            target[i] = target[parent] @ np.linalg.inv(reference[parent]) @ reference[i]
    source_bind = target.copy()
    child = {a: b for chain in base.CHAINS for a, b in zip(chain, chain[1:])}
    for i, name in enumerate(names):
        if name not in LANDMARKS:
            parent = parents[i]
            source_bind[i] = source_bind[parent] @ np.linalg.inv(target[parent]) @ target[i]
            continue
        source_bind[i, :3, 3] = LANDMARKS[name]
        end = child.get(name)
        if end in LANDMARKS:
            direction = np.array(LANDMARKS[end]) - np.array(LANDMARKS[name])
            reference_direction = target[index[end], :3, 3] - target[i, :3, 3]
            delta, _ = Rotation.align_vectors([direction / np.linalg.norm(direction)],
                                               [reference_direction / np.linalg.norm(reference_direction)])
            source_bind[i, :3, :3] = delta.as_matrix() @ target[i, :3, :3]
        elif name.endswith('Hand'):
            # Closed hands follow the down-hanging wrist into T-pose.
            source_bind[i, :3, :3] = source_bind[index[name.replace('Hand', 'ForeArm')], :3, :3]
    base.LANDMARKS = LANDMARKS
    joints, weights = base.skin_weights(positions, names, index)
    head = positions[:, 1] >= 118
    joints[head] = index['Head']
    weights[head] = [1, 0, 0, 0]
    positions, normals = base.repose(positions, normals, joints, weights, source_bind, target)
    mesh = (positions, normals, source.accessor(attr['TEXCOORD_0']),
            source.accessor(primitive['indices']).reshape(-1), joints, weights)
    DEST.mkdir(parents=True, exist_ok=True)
    base.ASSETS = DEST
    output = base.export('pbr', mesh, (names, index, parents, target), original, 1024)
    old = ROOT / output['path']
    final = DEST / 'henrique_mobile_rigged.glb'
    old.rename(final)
    refinement = refine(final, final)
    output['sha256'] = refinement['output_sha256']
    output['path'] = final.relative_to(ROOT).as_posix()
    profile = {'schema': 1, 'source_zip': '3970037e-fd4c-4114-b9f6-75905e547ff4.zip',
               'source_sha256': SOURCE_SHA, 'source_landmarks_cm': LANDMARKS,
               'output': output, 'combat_library': 'res://assets/animations/combat_mixamo.tres',
               'combat_clips': 127, 'license': 'User-supplied; provenance unverified',
               'refinement': refinement,
               'weighting': 'Four normalized influences; rigid chibi head; smooth shoulder/elbow/wrist zones and rigid fists'}
    (DEST / 'rig_profile.json').write_text(json.dumps(profile, indent=2) + '\n')
    print(json.dumps(output, indent=2))


if __name__ == '__main__':
    main()
