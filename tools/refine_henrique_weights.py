#!/usr/bin/env python3
"""Refine Henrique's baked T-pose skin without needing the private upload.

Only JOINTS_0/WEIGHTS_0 change. Geometry, textures, rest and rigid head are kept.
For the initial baked file: git show e779639:assets/characters/henrique/henrique_mobile_rigged.glb > /tmp/henrique-v1.glb
"""
import argparse
import hashlib
import json
from pathlib import Path
import numpy as np
from rig_base_basic_models import GLB


def smoothstep(low, high, values):
    t = np.clip((values - low) / (high - low), 0, 1)
    return t * t * (3 - 2 * t)


def refine(source, output):
    glb = GLB(Path(source))
    attr = glb.data['meshes'][0]['primitives'][0]['attributes']
    positions = glb.accessor(attr['POSITION'])
    joints = glb.accessor(attr['JOINTS_0'])
    weights = glb.accessor(attr['WEIGHTS_0'])
    names = [glb.data['nodes'][i]['name'].split(':')[-1] for i in glb.data['skins'][0]['joints']]
    metrics = {}
    for side, sign in [('Left', -1), ('Right', 1)]:
        chain = [names.index(side + part) for part in ['Shoulder', 'Arm', 'ForeArm', 'Hand']]
        membership = np.isin(joints, chain)
        mask = ((weights * membership).sum(axis=1) > .55) & (positions[:, 1] < 118) & (sign * positions[:, 0] > 12)
        reach = sign * positions[mask, 0]
        # Broad smooth joint zones prevent distant influences from collapsing
        # sleeves. The closed fist follows Hand, never animated finger bones.
        shoulder = smoothstep(13, 25, reach)
        elbow = smoothstep(32, 43, reach)
        wrist = smoothstep(48, 58, reach)
        values = np.column_stack([1 - shoulder, shoulder * (1 - elbow),
                                  elbow * (1 - wrist), wrist])
        values /= values.sum(axis=1, keepdims=True)
        joints[mask] = chain
        weights[mask] = values
        metrics[side.lower() + '_vertices'] = int(mask.sum())
        metrics[side.lower() + '_rigid_fist_vertices'] = int((wrist == 1).sum())
    assert np.isfinite(weights).all() and np.allclose(weights.sum(axis=1), 1, atol=1e-6)
    raw = bytearray(glb.raw)
    json_size = int.from_bytes(raw[12:16], 'little')
    for key, values in [('JOINTS_0', joints), ('WEIGHTS_0', weights)]:
        acc = glb.data['accessors'][attr[key]]
        view = glb.data['bufferViews'][acc['bufferView']]
        assert 'byteStride' not in view
        offset = 28 + json_size + view.get('byteOffset', 0) + acc.get('byteOffset', 0)
        content = values.tobytes()
        raw[offset:offset + len(content)] = content
    Path(output).write_bytes(raw)
    return {**metrics, 'input_sha256': hashlib.sha256(glb.raw).hexdigest(),
            'output_sha256': hashlib.sha256(raw).hexdigest(),
            'method': 'T-pose smoothstep shoulder/elbow/wrist zones; rigid closed fists; geometry/rest/head unchanged'}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--input', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    print(json.dumps(refine(args.input, args.output), indent=2))
