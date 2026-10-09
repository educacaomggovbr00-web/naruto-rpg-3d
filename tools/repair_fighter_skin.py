#!/usr/bin/env python3
"""Repro: git show e779639:assets/characters/henrique/henrique_mobile_rigged.glb > /tmp/henrique-baseline.glb; python3 tools/repair_fighter_skin.py --henrique-baseline /tmp/henrique-baseline.glb. Originals are never overwritten."""
import sys,copy,struct,json
from pathlib import Path
import numpy as np
from scipy.spatial.transform import Rotation
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools'))
import argparse
parser=argparse.ArgumentParser(description='Recover source-pose geometry and bind the two supplied fighters without baking clothing into T-pose.')
parser.add_argument('--henrique-baseline',type=Path,required=True,help='GLB from git show e779639:assets/characters/henrique/henrique_mobile_rigged.glb')
args=parser.parse_args()
import hashlib
if hashlib.sha256(args.henrique_baseline.read_bytes()).hexdigest() != "a139e993df1d29a61d28558d9ddb5c7b6c6754d385c1e42eb93ab292bc8e0777":
 raise ValueError("Expected the Henrique baseline from commit e779639")
import os
os.chdir(ROOT)
import rig_base_basic_models as b
from rig_henrique import LANDMARKS as HLM

def patch(g,arrays,out):
 data=copy.deepcopy(g.data);buf=bytearray(g.buffer);attrs=data['meshes'][0]['primitives'][0]['attributes']
 for key,values in arrays.items():
  acc=data['accessors'][attrs[key]];view=data['bufferViews'][acc['bufferView']];off=view.get('byteOffset',0)+acc.get('byteOffset',0);buf[off:off+values.nbytes]=values.tobytes()
  if key=='POSITION':acc['min']=values.min(0).tolist();acc['max']=values.max(0).tolist()
 js=json.dumps(data,separators=(',',':')).encode();js+=b' ' *(-len(js)%4);buf+=b'\0'*(-len(buf)%4)
 Path(out).parent.mkdir(parents=True,exist_ok=True)
 Path(out).write_bytes(struct.pack('<4sII',b'glTF',2,28+len(js)+len(buf))+struct.pack('<I4s',len(js),b'JSON')+js+struct.pack('<I4s',len(buf),b'BIN\0')+buf)
for id,file,old in [('naruto','assets/characters/base_basic/base_basic_pbr_rigged.glb',None),('henrique','assets/characters/henrique/henrique_mobile_rigged.glb',str(args.henrique_baseline))]:
 g=b.GLB(Path(file));o=b.GLB(Path(old)) if old else g; attrs=g.data['meshes'][0]['primitives'][0]['attributes'];oldattrs=o.data['meshes'][0]['primitives'][0]['attributes'];p=g.accessor(attrs['POSITION']).astype(float);n=g.accessor(attrs['NORMAL']).astype(float);j=o.accessor(oldattrs['JOINTS_0']);w=o.accessor(oldattrs['WEIGHTS_0'])
 skin=g.data['skins'][0];names=[g.data['nodes'][i]['name'].split(':')[-1] for i in skin['joints']];index={v:i for i,v in enumerate(names)};parents={c:i for i,node in enumerate(g.data['nodes'][:65]) for c in node.get('children',[]) if c<65};target=np.linalg.inv(g.accessor(skin['inverseBindMatrices']).reshape(-1,4,4).transpose(0,2,1)).astype(float)
 if id=='naruto': source=b.fit_source_bind(names,index,parents,target)
 else:
  source=target.copy();child={a:c for chain in b.CHAINS for a,c in zip(chain,chain[1:])}
  for i,name in enumerate(names):
   if name not in HLM:
    parent=parents[i];source[i]=source[parent]@np.linalg.inv(target[parent])@target[i];continue
   source[i,:3,3]=HLM[name];end=child.get(name)
   if end in HLM:
    d=np.array(HLM[end])-np.array(HLM[name]);ref=target[index[end],:3,3]-target[i,:3,3];delta,_=Rotation.align_vectors([d/np.linalg.norm(d)],[ref/np.linalg.norm(ref)]);source[i,:3,:3]=delta.as_matrix()@target[i,:3,:3]
   elif name.endswith('Hand'):source[i,:3,:3]=source[index[name.replace('Hand','ForeArm')],:3,:3]
 transforms=target@np.linalg.inv(source)
 blends=(transforms[j]*w[:,:,None,None]).sum(1)
 original=np.linalg.solve(blends[:,:3,:3],(p-blends[:,:3,3])[...,None])[...,0]
 original_n=np.linalg.solve(blends[:,:3,:3],n[...,None])[...,0];original_n/=np.linalg.norm(original_n,axis=1)[:,None]
 print(id,'source bounds',original.min(0),original.max(0))
 # Preserve legs and rigid head. Restrict upper-body influences to anatomically
 # adjacent torso or same-side arm chains; hands cannot pull the shirt hem.
 newj=j.copy();neww=w.copy();lm=HLM if id=='henrique' else b.LANDMARKS
 upper=(original[:,1]>lm['Hips'][1]-5)&(original[:,1]<lm['Head'][1]-5)
 head=(original[:,1]>=118) if id=='henrique' else (original[:,1]>139)&(original[:,2]>-10)
 upper &= ~head
 ax=np.abs(original[:,0]);arm_threshold=18 if id=='henrique' else 19
 torso=upper&(ax<arm_threshold)
 spine=['Hips','Spine','Spine1','Spine2'];heights=np.array([lm[k][1] for k in spine]);v=original[torso,1];interval=np.clip(np.searchsorted(heights,v)-1,0,2);t=np.clip((v-heights[interval])/(heights[interval+1]-heights[interval]),0,1)
 newj[torso]=np.column_stack([[index[spine[k]] for k in interval],[index[spine[k+1]] for k in interval],np.zeros(len(v),int),np.zeros(len(v),int)]);neww[torso]=np.column_stack([1-t,t,np.zeros(len(v)),np.zeros(len(v))])
 for side,sign in [('Left',-1),('Right',1)]:
  mask=upper&(sign*original[:,0]>=arm_threshold);chain=[side+x for x in ['Shoulder','Arm','ForeArm','Hand']];starts=np.array([lm[k] for k in chain]);ends=np.array([lm[k] for k in chain[1:]]+[np.array(lm[chain[-1]])+[0,-6,0]])
  d=ends-starts;rel=original[mask,None,:]-starts;tt=np.clip((rel*d).sum(2)/(d*d).sum(1),0,1);ds=((rel-tt[:,:,None]*d)**2).sum(2);nearest=ds.argmin(1);allowed=np.abs(np.arange(4)[None,:]-nearest[:,None])<=1;score=np.where(allowed,np.exp(-(ds-ds.min(1)[:,None])/20),0);score/=score.sum(1)[:,None];newj[mask]=[index[k] for k in chain];neww[mask]=score
 # Bind to the fitted source pose instead of baking the shirt into T-pose.
 for i in range(len(names)):
  local=np.linalg.inv(source[parents[i]])@source[i] if i in parents else source[i]
  g.data['nodes'][i]['translation']=local[:3,3].tolist()
  g.data['nodes'][i]['rotation']=Rotation.from_matrix(local[:3,:3]).as_quat().tolist()
 ib=g.data['accessors'][skin['inverseBindMatrices']];bv=g.data['bufferViews'][ib['bufferView']];off=bv.get('byteOffset',0)+ib.get('byteOffset',0)
 raw=bytearray(g.buffer);matrix=np.linalg.inv(source).transpose(0,2,1).reshape(-1,16).astype('<f4');raw[off:off+matrix.nbytes]=matrix.tobytes();g.buffer=bytes(raw)
 # Native bind-pose translation must match the new hips rest.
 for channel in g.data.get('animations',[]):
  for c in channel.get('channels',[]):
   if c['target']['node']==0 and c['target']['path']=='translation':
    ai=channel['samplers'][c['sampler']]['output'];ac=g.data['accessors'][ai];view=g.data['bufferViews'][ac['bufferView']];offset=view.get('byteOffset',0)+ac.get('byteOffset',0);values=np.tile(source[0,:3,3],(ac['count'],1)).astype('<f4');raw=bytearray(g.buffer);raw[offset:offset+values.nbytes]=values.tobytes();g.buffer=bytes(raw)
 repaired,repaired_n=original,original_n
 patch(g,{'POSITION':repaired.astype('<f4'),'NORMAL':repaired_n.astype('<f4'),'JOINTS_0':newj.astype('<u2'),'WEIGHTS_0':neww.astype('<f4')},f'assets/characters/repaired/{id}_mobile.glb')
