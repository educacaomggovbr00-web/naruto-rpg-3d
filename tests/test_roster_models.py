import hashlib
import json
from pathlib import Path
import sys
import unittest
import numpy as np
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from rig_base_basic_models import GLB

class RosterModelsTest(unittest.TestCase):
    def test_unique_normalized_skinned_models(self):
        manifest = json.loads((ROOT / 'assets/characters/final/roster_manifest.json').read_text())
        self.assertEqual(len(manifest['characters']), 21)
        fingerprints = set()
        for name, entry in manifest['characters'].items():
            model = GLB(ROOT / entry['path'])
            digest = hashlib.sha256(model.raw).hexdigest()
            self.assertEqual(digest, entry['sha256'])
            fingerprints.add(digest)
            self.assertEqual(len(model.data['skins'][0]['joints']), 65)
            self.assertLess(entry['triangles'], 14000)
            for mesh in model.data['meshes']:
                for primitive in mesh['primitives']:
                    weights = model.accessor(primitive['attributes']['WEIGHTS_0'])
                    self.assertTrue(np.isfinite(weights).all())
                    self.assertTrue((weights >= 0).all())
                    self.assertTrue(np.allclose(weights.sum(axis=1), 1, atol=1e-6))
                    positions = model.accessor(primitive['attributes']['POSITION'])
                    self.assertTrue(np.isfinite(positions).all())
                    joints = model.accessor(primitive['attributes']['JOINTS_0'])
                    self.assertLess(joints.max(), 65)
        self.assertEqual(len(fingerprints), 21)

    def test_ready_models_preserved(self):
        manifest = json.loads((ROOT / 'assets/characters/final/roster_manifest.json').read_text())
        self.assertEqual(len(manifest['preserved_ready_models']), 5)
        for path, fingerprint in manifest['preserved_ready_models'].items():
            self.assertEqual(hashlib.sha256((ROOT / path).read_bytes()).hexdigest(), fingerprint, path)
