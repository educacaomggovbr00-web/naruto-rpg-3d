import sys
import unittest
from pathlib import Path
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools'))
from rig_base_basic_models import GLB

class SkinRepairTest(unittest.TestCase):
    def test_clothing_topology_and_textures_preserved_without_stretched_edges(self):
        for character,original in [('naruto','base_basic/base_basic_pbr_rigged.glb'),('henrique','henrique/henrique_mobile_rigged.glb')]:
            old=GLB(ROOT/'assets/characters'/original)
            new=GLB(ROOT/'assets/characters/repaired'/f'{character}_mobile.glb')
            a=old.data['meshes'][0]['primitives'][0];b=new.data['meshes'][0]['primitives'][0]
            np.testing.assert_array_equal(old.accessor(a['indices']),new.accessor(b['indices']))
            np.testing.assert_array_equal(old.accessor(a['attributes']['TEXCOORD_0']),new.accessor(b['attributes']['TEXCOORD_0']))
            self.assertEqual(old.data['materials'],new.data['materials'])
            for left,right in zip(old.data['images'],new.data['images']):self.assertEqual(old.image(left),new.image(right))
            triangles=new.accessor(b['indices']).reshape(-1,3)
            def longest(model,primitive):
                p=model.accessor(primitive['attributes']['POSITION'])
                return max(np.linalg.norm(p[triangles[:,i]]-p[triangles[:,(i+1)%3]],axis=1).max() for i in range(3))
            self.assertLess(longest(new,b),longest(old,a)*.35)
            weights=new.accessor(b['attributes']['WEIGHTS_0'])
            self.assertTrue(np.isfinite(weights).all() and (weights>=0).all())
            np.testing.assert_allclose(weights.sum(1),1,atol=1e-6)
            self.assertEqual(len(new.data['skins'][0]['joints']),65)
    def test_rest_hierarchy_matches_inverse_binds(self):
        from scipy.spatial.transform import Rotation
        for character in ['naruto','henrique']:
            model=GLB(ROOT/'assets/characters/repaired'/f'{character}_mobile.glb')
            joints=model.data['skins'][0]['joints'];world={}
            parents={child:index for index,node in enumerate(model.data['nodes']) for child in node.get('children',[])}
            def transform(index):
                if index in world:return world[index]
                node=model.data['nodes'][index];local=np.eye(4);local[:3,:3]=Rotation.from_quat(node.get('rotation',[0,0,0,1])).as_matrix();local[:3,3]=node.get('translation',[0,0,0])
                world[index]=transform(parents[index])@local if index in parents else local
                return world[index]
            inverse=model.accessor(model.data['skins'][0]['inverseBindMatrices']).reshape(-1,4,4).transpose(0,2,1)
            for index,joint in enumerate(joints):np.testing.assert_allclose(transform(joint)@inverse[index],np.eye(4),atol=1e-4)
