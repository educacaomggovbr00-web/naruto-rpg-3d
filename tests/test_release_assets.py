import hashlib
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from validate_release_assets import validate


class ReleaseGateContract(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(dir=Path(__file__).parent)
        self.root = Path(self.temp.name)
        (self.root / 'assets').mkdir()
        self.asset = self.root / 'assets/model.glb'
        self.asset.write_bytes(b'original fixture')
        self.entry = dict(path='assets/model.glb', status='SAFE_FOR_RELEASE',
                          sha256=hashlib.sha256(self.asset.read_bytes()).hexdigest(),
                          author='Test author', source='Original fixture', license='CC0',
                          modifications='None')
        self.registry = dict(assets=[self.entry], presentation_distribution_authorized=True)
        self.write()

    def tearDown(self):
        self.temp.cleanup()

    def write(self):
        (self.root / 'assets/asset_registry.json').write_text(json.dumps(self.registry))

    def test_cleared_original_can_release(self):
        self.assertEqual(validate(self.root, True)[0], [])

    def test_unknown_is_dev_only(self):
        self.entry['status'] = 'UNKNOWN_LICENSE'
        self.write()
        self.assertEqual(validate(self.root, False)[0], [])
        self.assertTrue(validate(self.root, True)[0])

    def test_new_asset_is_not_implicitly_cleared(self):
        (self.root / 'assets/rip.png').write_bytes(b'unregistered fixture')
        self.assertTrue(validate(self.root, True)[0])

    def test_other_importable_model_formats_are_not_implicitly_cleared(self):
        (self.root / 'assets/imported.obj').write_bytes(b'unregistered model fixture')
        self.assertTrue(validate(self.root, True)[0])

    def test_development_only_cannot_release(self):
        self.entry['status'] = 'DEVELOPMENT_ONLY'
        self.write()
        self.assertTrue(validate(self.root, True)[0])

    def test_changed_content_requires_review(self):
        self.asset.write_bytes(b'changed fixture')
        self.assertTrue(validate(self.root, True)[0])

    def test_attribution_is_required(self):
        self.entry['status'] = 'NEEDS_ATTRIBUTION'
        self.write()
        self.assertTrue(validate(self.root, True)[0])
        self.entry['credit'] = 'Test author — CC0'
        self.write()
        self.assertEqual(validate(self.root, True)[0], [])

    def test_character_presentation_requires_authorization(self):
        self.registry['presentation_distribution_authorized'] = False
        self.write()
        self.assertTrue(validate(self.root, True)[0])

    def test_embedded_paths_cannot_escape_checkout(self):
        self.entry['embedded_images'] = [{'path': '../private.png', 'sha256': 'invalid'}]
        self.write()
        self.assertTrue(validate(self.root, True)[0])


if __name__ == '__main__':
    unittest.main()
