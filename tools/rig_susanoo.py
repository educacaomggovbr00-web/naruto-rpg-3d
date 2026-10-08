#!/usr/bin/env python3
"""Reproducible fitted skin and original keyframes for the existing CC-BY avatar.

Source geometry, textures and attribution remain intact. Landmarks are fitted
specifically to this source in its Z-up coordinate space, not an auto-rig claim.
"""
import hashlib
import json
import math
import struct
from pathlib import Path
import numpy as np
from rig_base_basic_models import GLB

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'assets/susanoo/susanoo_mobile.glb'
TARGET = ROOT / 'assets/susanoo/susanoo_mobile_rigged.glb'
# name, parent, global bind position (source units)
BONES = [
 ('Root', -1, [0,0,0]), ('Hips',0,[0,0,235]),
 ('Spine',1,[0,0,330]), ('Chest',2,[0,0,425]), ('Head',3,[0,0,485]),
 ('LeftArm',3,[-90,0,420]), ('LeftForearm',5,[-145,0,320]), ('LeftHand',6,[-195,0,205]),
 ('RightArm',3,[90,0,420]), ('RightForearm',8,[145,0,320]), ('RightHand',9,[195,0,205]),
 ('LeftThigh',1,[-85,0,220]), ('LeftShin',11,[-90,0,115]), ('LeftFoot',12,[-100,-10,20]),
 ('RightThigh',1,[85,0,220]), ('RightShin',14,[90,0,115]), ('RightFoot',15,[100,-10,20]),
 ('LeftWing',3,[-90,52,440]), ('RightWing',3,[90,52,440]),
 ('LeftUpperArm',3,[-105,52,440]), ('LeftUpperForearm',19,[-190,52,520]), ('LeftUpperHand',20,[-260,52,565]),
 ('RightUpperArm',3,[105,52,440]), ('RightUpperForearm',22,[190,52,520]), ('RightUpperHand',23,[260,52,565]),
]

def bake():
 source = GLB(SOURCE)
 data = source.data
 binary = bytearray(source.buffer)
 positions = np.array([b[2] for b in BONES],dtype=float)
 names = {b[0]:i for i,b in enumerate(BONES)}
 def put(values, dtype, kind, component, target=None):
  values = np.asarray(values,dtype=dtype)
  binary.extend(b'\0' * (-len(binary)%4))
  view = {'buffer':0,'byteOffset':len(binary),'byteLength':values.nbytes}
  if target: view['target']=target
  vi=len(data['bufferViews']); data['bufferViews'].append(view)
  binary.extend(values.tobytes())
  a={'bufferView':vi,'componentType':component,'count':len(values),'type':kind}
  if kind in ('VEC3','SCALAR'):
   a.update(min=values.min(axis=0).tolist(),max=values.max(axis=0).tolist())
  ai=len(data['accessors']); data['accessors'].append(a); return ai
 # Append skeleton alongside meshes under the source's coordinate conversion.
 first=len(data['nodes'])
 for i,(name,parent,point) in enumerate(BONES):
  local=positions[i]-(positions[parent] if parent>=0 else 0)
  node={'name':'Susanoo_'+name,'translation':local.tolist()}
  children=[first+j for j,b in enumerate(BONES) if b[1]==i]
  if children: node['children']=children
  data['nodes'].append(node)
 data['nodes'][1]['children'].append(first)
 ibm=np.repeat(np.eye(4)[None],len(BONES),axis=0)
 ibm[:,:3,3]=-positions
 data['skins']=[{'name':'SusanooFittedRig','skeleton':first,'joints':list(range(first,first+len(BONES))),
                 'inverseBindMatrices':put(ibm.transpose(0,2,1).reshape(-1,16),'<f4','MAT4',5126)}]
 for node in data['nodes'][:first]:
  if 'mesh' not in node: continue
  node['skin']=0
  for primitive in data['meshes'][node['mesh']]['primitives']:
   p=source.accessor(primitive['attributes']['POSITION'])
   joints=np.zeros((len(p),4),dtype='<u2'); weights=np.zeros((len(p),4),dtype='<f4')
   for vi,point in enumerate(p):
    x,y,z=point; side='Left' if x<0 else 'Right'
    if node['name'] == 'Object_7':
     candidates=[names[side+'Wing']]
    elif node['name']=='Object_10' or z>480 and abs(x)>80:
     candidates=[names[side+'Upper'+part] for part in ('Arm','Forearm','Hand')]
    elif node['name'] in ('Object_4','Object_9','Object_11'):
     candidates=[names['Head']]
    elif node['name'] in ('Object_2','Object_8'):
     candidates=[names['RightHand']]
    elif node['name']=='Object_3':
     candidates=[names['LeftHand']]
    elif abs(x)>120 and z>150:
     candidates=[names[side+part] for part in ('Arm','Forearm','Hand')]
    elif z<230 and abs(x)>35:
     candidates=[names[side+part] for part in ('Thigh','Shin','Foot')]
    else:
     candidates=[names[n] for n in ('Hips','Spine','Chest','Head')]
    distances=np.linalg.norm(positions[candidates]-point,axis=1)
    order=np.argsort(distances)[:2]
    chosen=np.array(candidates)[order]
    blend=1/np.maximum(distances[order],18)**4; blend/=blend.sum()
    joints[vi,:len(chosen)]=chosen; weights[vi,:len(chosen)]=blend
   primitive['attributes']['JOINTS_0']=put(joints,'<u2','VEC4',5123,34962)
   primitive['attributes']['WEIGHTS_0']=put(weights,'<f4','VEC4',5126,34962)
 data['animations']=[]
 for clip,duration,loop in [('idle',2.4,True),('walk',0.8,True),('slash',1.0,False),('guard',1.0,False),('summon',1.0,False)]:
  times=np.linspace(0,duration,round(duration*30)+1)
  animation={'name':clip,'samplers':[],'channels':[],'extras':{'loop':loop,'authorship':'Original fitted keyframes'}}
  ti=put(times[:,None],'<f4','SCALAR',5126)
  for i,(name,_,_) in enumerate(BONES):
   quats=[]
   for t in times/duration:
    wave=math.sin(t*math.tau); angle=0.; axis=np.array([0.,1.,0.])
    if clip=='idle':
     if name in ('Chest','Head'): angle=.018*wave
     elif 'Wing' in name: angle=.035*wave*(1 if 'Left' in name else -1)
    elif clip=='walk':
     if name.endswith(('Arm','Thigh','Shin')):
      angle=wave*(.14 if 'Arm' in name else .24)*(1 if 'Left' in name else -1)
     if name=='Chest': angle=.04*wave
    elif clip=='slash':
     # Fully recover, strongest extension at normalized impact 0.42.
     def ease(a,b,v):
      q=min(1,max(0,(v-a)/(b-a))); return q*q*(3-2*q)
     swing=(-.85*ease(0,.273,t) if t<.273 else -.85+2.25*ease(.273,.42,t) if t<.42 else 1.4*(1-ease(.42,1,t)))
     if name=='Chest': angle=swing*.22; axis=np.array([0.,0.,1.])
     elif name=='LeftArm': angle=swing*.70
     elif name=='LeftForearm': angle=swing*.30
     elif name=='RightArm': angle=-swing*.18
     elif 'Wing' in name: angle=swing*.06
    elif clip=='guard':
     if name.endswith('Arm'): angle=-.38*math.sin(math.pi*t)
     if name.endswith('Forearm'): angle=-.65*math.sin(math.pi*t)
    elif clip=='summon':
     if name.endswith('Arm'): angle=-.30*math.sin(math.pi*t)
     if 'Wing' in name: angle=.22*math.sin(math.pi*t)*(1 if 'Left' in name else -1)
    quats.append([*(axis*math.sin(angle/2)),math.cos(angle/2)])
   sampler=len(animation['samplers'])
   animation['samplers'].append({'input':ti,'output':put(quats,'<f4','VEC4',5126),'interpolation':'LINEAR'})
   animation['channels'].append({'sampler':sampler,'target':{'node':first+i,'path':'rotation'}})
  data['animations'].append(animation)
 data['asset']['extras']['rig_modifications']='25-bone fitted skin and 5 original animation clips; tools/rig_susanoo.py'
 data['buffers'][0]['byteLength']=len(binary)
 raw=json.dumps(data,separators=(',',':')).encode(); raw+=b' '*(-len(raw)%4)
 binary.extend(b'\0'*(-len(binary)%4))
 TARGET.write_bytes(struct.pack('<4sII',b'glTF',2,28+len(raw)+len(binary))+struct.pack('<II',len(raw),0x4e4f534a)+raw+struct.pack('<II',len(binary),0x004e4942)+binary)
 manifest=json.loads((ROOT/'assets/susanoo/source_manifest.json').read_text())
 manifest['rigged_runtime']={'path':str(TARGET.relative_to(ROOT)), 'sha256':hashlib.sha256(TARGET.read_bytes()).hexdigest(), 'bytes':TARGET.stat().st_size,'bones':len(BONES),'animations':[a['name'] for a in data['animations']], 'source_geometry_preserved':True,'animation_authorship':'Original fitted keyframes, not source artist animations'}
 (ROOT/'assets/susanoo/source_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
 print(manifest['rigged_runtime'])
if __name__=='__main__': bake()
