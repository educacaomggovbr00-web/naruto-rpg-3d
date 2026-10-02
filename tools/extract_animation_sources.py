#!/usr/bin/env python3
"""Strip unused meshes/textures/clips from the pinned CC0 animation sources.

Usage: python tools/extract_animation_sources.py <UAL1.gltf> <UAL2.glb>
Preserves skeletons and sampled channels exactly; changes no motion values.
"""
import hashlib
import json
import struct
import sys
from pathlib import Path

from bake_combat_animations import Gltf, SOURCE, SPECS


def extract(path, pack):
    source = Gltf(path)
    wanted = {'A_TPose'}
    for cfg in SPECS.values():
        if cfg['pack'] == pack:
            wanted.add(cfg['clip'])
            if 'recovery' in cfg:
                wanted.add(cfg['recovery'])
    clips = [a for a in source.data['animations'] if a['name'] in wanted]
    accessors, views, buffer, remap = [], [], bytearray(), {}
    for a in clips:
        for sampler in a['samplers']:
            for key in ['input', 'output']:
                old = sampler[key]
                if old not in remap:
                    values = source.accessor(old).astype('<f4').tobytes()
                    while len(buffer) % 4:
                        buffer.append(0)
                    view = {'buffer': 0, 'byteOffset': len(buffer), 'byteLength': len(values)}
                    original = source.data['accessors'][old]
                    accessor = {k: original[k] for k in ['componentType', 'count', 'type']}
                    for k in ['min', 'max']:
                        if k in original:
                            accessor[k] = original[k]
                    accessor['bufferView'] = len(views)
                    remap[old] = len(accessors)
                    accessors.append(accessor)
                    views.append(view)
                    buffer.extend(values)
                sampler[key] = remap[old]
    nodes = [{k: v for k, v in n.items() if k in ['name', 'children', 'rotation', 'translation', 'scale', 'matrix']}
             for n in source.nodes]
    result = {'asset': {'version': '2.0', 'generator': 'CC0 animation-only extraction; original motion unchanged'},
              'nodes': nodes, 'animations': clips, 'accessors': accessors, 'bufferViews': views,
              'buffers': [{'byteLength': len(buffer)}]}
    destination = SOURCE / ('AnimationLibrary_Godot_Standard.gltf' if pack == 1 else 'UAL2_Standard.glb')
    if pack == 1:
        result['buffers'][0]['uri'] = 'AnimationLibrary_Godot_Standard.bin'
        destination.write_text(json.dumps(result, separators=(',', ':')))
        (SOURCE / result['buffers'][0]['uri']).write_bytes(buffer)
    else:
        js = json.dumps(result, separators=(',', ':')).encode()
        js += b' ' * (-len(js) % 4)
        buffer += b'\0' * (-len(buffer) % 4)
        glb = struct.pack('<4sII', b'glTF', 2, 28+len(js)+len(buffer))
        glb += struct.pack('<II', len(js), 0x4e4f534a) + js
        glb += struct.pack('<II', len(buffer), 0x004e4942) + buffer
        destination.write_bytes(glb)
    return {'pack': pack, 'original_sha256': hashlib.sha256(source.path.read_bytes()).hexdigest(),
            'original_buffer_sha256': hashlib.sha256(source.buffer).hexdigest(),
            'clips': sorted(wanted), 'extracted_file': destination.name}


if __name__ == '__main__':
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)
    records = [extract(sys.argv[1], 1), extract(sys.argv[2], 2)]
    (SOURCE / 'extraction.json').write_text(json.dumps(records, indent=2) + '\n')
