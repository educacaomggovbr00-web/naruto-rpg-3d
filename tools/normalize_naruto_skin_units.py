#!/usr/bin/env python3
"""Normalize the supplied Naruto mesh to the centimeter-space combat skeleton.

POSITION * 100 and inverseBindMatrix * scale(0.01) cancel exactly during
skinning. This repairs mesh bounds/culling without changing bones or textures.
Run once against the original meter-space asset; refuses repeated conversion.
"""
import argparse
import json
import struct
from pathlib import Path

import numpy as np


def normalize(path: Path) -> None:
    raw = path.read_bytes()
    length = struct.unpack_from('<I', raw, 12)[0]
    gltf = json.loads(raw[20:20 + length])
    binary = bytearray(raw[28 + length:])
    positions = {p['attributes']['POSITION'] for m in gltf['meshes'] for p in m['primitives']}
    if max(gltf['accessors'][i]['max'][1] for i in positions) > 10:
        raise ValueError('Mesh already uses skeleton units; refusing a second conversion')

    def array(index, width):
        accessor = gltf['accessors'][index]
        view = gltf['bufferViews'][accessor['bufferView']]
        assert accessor['componentType'] == 5126 and 'sparse' not in accessor
        return np.ndarray((accessor['count'], width), dtype='<f4', buffer=binary,
                          offset=view.get('byteOffset', 0) + accessor.get('byteOffset', 0),
                          strides=(view.get('byteStride', width * 4), 4))

    for index in positions:
        array(index, 3)[:] *= 100
        accessor = gltf['accessors'][index]
        for key in ('min', 'max'):
            accessor[key] = [v * 100 for v in accessor[key]]
    for index in {s['inverseBindMatrices'] for s in gltf['skins']}:
        # glTF matrices are column-major: scale the first three columns only.
        array(index, 16)[:, :12] *= 0.01
    metadata = json.dumps(gltf, separators=(',', ':')).encode()
    metadata += b' ' * (-len(metadata) % 4)
    output = struct.pack('<4sII', b'glTF', 2, 28 + len(metadata) + len(binary))
    output += struct.pack('<II', len(metadata), 0x4E4F534A) + metadata
    output += struct.pack('<II', len(binary), 0x004E4942) + binary
    path.write_bytes(output)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('glb', type=Path)
    normalize(parser.parse_args().glb)
