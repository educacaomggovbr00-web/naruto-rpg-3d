"""Baked-motion provenance, uniqueness and immutable legacy choreography."""
import hashlib
import json
import re
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import numpy as np
from rig_base_basic_models import GLB
from refine_henrique_weights import refine


class CombatExpansionContract(unittest.TestCase):
    def test_100_spatially_distinct_clips_and_27_unchanged_originals(self):
        text = (ROOT / 'assets/animations/combat_mixamo.tres').read_text()
        blocks = dict(re.findall(r'\[sub_resource type="Animation" id="Animation_([^"\n]+)"\]\n(.*?)(?=\n\n\[|\Z)', text, re.S))
        legacy = {n: v for n, v in blocks.items() if not n.startswith('combat_')}
        self.assertEqual(len(legacy), 27)
        self.assertEqual(hashlib.sha256(json.dumps(legacy, sort_keys=True).encode()).hexdigest(),
                         '00168e89fdc884d3bc32ae088843defa52a4ada9cd5997adeb94c2c9bf97f16a')
        new = {n: v for n, v in blocks.items() if n.startswith('combat_')}
        # Remove the resource name; renaming a duplicate does not make new motion.
        motions = {re.sub(r'resource_name = "[^"]+"\n', '', v) for v in new.values()}
        self.assertEqual(len(new), 100)
        self.assertEqual(len(motions), 100)
        manifest = json.loads((ROOT / 'assets/animations/combat_manifest.json').read_text())
        self.assertEqual(set(blocks), set(manifest['clips']))
        families = {}
        for name in new:
            clip = manifest['clips'][name]
            families.setdefault(clip['category'], set()).add(clip['variant'])
            self.assertEqual(clip['license'], 'CC0-1.0')
            self.assertEqual(clip['bone_count'], 65)
            if 'impact' in clip:
                self.assertGreater(clip['recovery'], 0)
                self.assertLess(clip['impact'] + clip['active'], clip['duration'])
                self.assertEqual(clip['startup'], clip['impact'])
        self.assertEqual(len(families), 10)
        self.assertTrue(all(len(variants) == 10 for variants in families.values()))
        for name, digest in manifest['source_sha256'].items():
            self.assertEqual(hashlib.sha256((ROOT / 'assets/animations/source' / name).read_bytes()).hexdigest(), digest)

    def test_refined_skin_is_normalized_side_local_and_repeatable(self):
        path = ROOT / 'assets/characters/henrique/henrique_mobile_rigged.glb'
        skin = GLB(path)
        attrs = skin.data['meshes'][0]['primitives'][0]['attributes']
        immutable = bytearray(skin.raw)
        json_size = int.from_bytes(immutable[12:16], 'little')
        for name in ['JOINTS_0', 'WEIGHTS_0']:
            accessor = skin.data['accessors'][attrs[name]]
            view = skin.data['bufferViews'][accessor['bufferView']]
            offset = 28 + json_size + view.get('byteOffset', 0) + accessor.get('byteOffset', 0)
            size = skin.accessor(attrs[name]).nbytes
            immutable[offset:offset + size] = bytes(size)
        self.assertEqual(hashlib.sha256(immutable).hexdigest(),
                         'f0a4e9dce934f61c23e33d8ef808ea09ba86b3915ed561aa6bd87ca4657eaa2b',
                         'Only joint indices/weights may change; preserve geometry, rest, textures and head')
        joints, weights = skin.accessor(attrs['JOINTS_0']), skin.accessor(attrs['WEIGHTS_0'])
        positions = skin.accessor(attrs['POSITION'])
        self.assertTrue(np.all(np.isfinite(weights)))
        self.assertTrue(np.allclose(weights.sum(axis=1), 1, atol=1e-6))
        self.assertTrue(np.all(weights >= 0))
        names = [skin.data['nodes'][i]['name'].split(':')[-1] for i in skin.data['skins'][0]['joints']]
        head = positions[:, 1] >= 118
        self.assertTrue(np.all(joints[head, 0] == names.index('Head')))
        self.assertTrue(np.all(weights[head, 0] == 1))
        for side, sign in [('Left', -1), ('Right', 1)]:
            fist = (sign * positions[:, 0] >= 58) & (positions[:, 1] < 118)
            hand = names.index(side + 'Hand')
            self.assertGreater(int(fist.sum()), 100)
            self.assertTrue(np.all((weights[fist] * (joints[fist] == hand)).sum(axis=1) == 1))
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / 'repeat.glb'
            refine(path, output)
            self.assertEqual(path.read_bytes(), output.read_bytes())


if __name__ == '__main__':
    unittest.main()
