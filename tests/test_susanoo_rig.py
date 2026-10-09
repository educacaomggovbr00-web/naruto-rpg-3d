import hashlib
import json
from pathlib import Path
import sys
import unittest
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from rig_base_basic_models import GLB

class SusanooRigTest(unittest.TestCase):
    def test_geometry_preserved_and_weights_valid(self):
        source = GLB(ROOT / 'assets/susanoo/susanoo_mobile.glb')
        rig = GLB(ROOT / 'assets/susanoo/susanoo_mobile_rigged.glb')
        self.assertEqual(rig.buffer[:len(source.buffer)], source.buffer)
        self.assertEqual(rig.data['materials'], source.data['materials'])
        self.assertEqual(rig.data['images'], source.data['images'])
        self.assertEqual(len(rig.data['skins'][0]['joints']), 25)
        for source_mesh, mesh in zip(source.data['meshes'], rig.data['meshes']):
            for original, primitive in zip(source_mesh['primitives'], mesh['primitives']):
                self.assertEqual(primitive['indices'], original['indices'])
                for attribute, index in original['attributes'].items():
                    self.assertEqual(primitive['attributes'][attribute], index)
                weights = rig.accessor(primitive['attributes']['WEIGHTS_0'])
                joints = rig.accessor(primitive['attributes']['JOINTS_0'])
                self.assertTrue(np.isfinite(weights).all())
                self.assertTrue((weights >= 0).all())
                self.assertTrue(np.allclose(weights.sum(axis=1), 1, atol=1e-6))
                self.assertLess(joints.max(), 25)
        manifest = json.loads((ROOT / 'assets/susanoo/source_manifest.json').read_text())
        self.assertEqual(manifest['rigged_runtime']['sha256'], hashlib.sha256(rig.raw).hexdigest())

    def test_animation_recovery_and_unit_quaternions(self):
        rig = GLB(ROOT / 'assets/susanoo/susanoo_mobile_rigged.glb')
        self.assertEqual({a['name'] for a in rig.data['animations']}, {'idle', 'walk', 'slash', 'guard', 'summon'})
        for animation in rig.data['animations']:
            self.assertEqual(len(animation['channels']), 25)
            for sampler in animation['samplers']:
                times = rig.accessor(sampler['input']).flatten()
                rotations = rig.accessor(sampler['output'])
                self.assertTrue((np.diff(times) > 0).all())
                self.assertTrue(np.allclose(np.linalg.norm(rotations, axis=1), 1, atol=1e-6))
                self.assertTrue(np.allclose(rotations[0], rotations[-1], atol=1e-6))
