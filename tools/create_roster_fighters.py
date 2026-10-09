#!/usr/bin/env python3
"""Bake 21 original stylized roster bodies; never rebuild the five ready models.

Uses joint transforms from the existing development rig, not its body/texture.
Geometry, faces, clothing and props are authored here; no downloaded game meshes.
"""
import hashlib
import json
import math
from pathlib import Path
import numpy as np
import create_stylized_fighters as rig

ROOT = rig.ROOT
# shirt, trousers, hair, hairstyle, build, skin, defining garment/prop
DATA = {
 'shikamaru': ('43573a','252a31','171b23','pony',1.0,'edb993','vest'),
 'choji': ('aa3942','58554c','683c28','short',1.35,'edb993','scarf'),
 'ino': ('8655b3','8655b3','e9d17e','pony',.86,'f0c3a6','skirt'),
 'rock_lee': ('267643','267643','181e25','bowl',.92,'edb993','leg_wraps'),
 'neji': ('e7dfcc','3d3445','35252d','long',.93,'efd1b0','wraps'),
 'tenten': ('e4c7bb','81313e','452d27','buns',.88,'e9b38c','vest'),
 'shino': ('596550','383e39','252b2a','hood',1.0,'d8ad8b','glasses'),
 'kiba': ('7b8177','383d44','372c27','spikes',1.0,'edb993','fur'),
 'hinata': ('d7d4ea','394f79','252640','bob',.88,'efd1b0','jacket'),
 'gaara': ('8c3c39','4d373e','a14233','short',.92,'ecd0b2','gourd'),
 'kankuro': ('292632','292632','2c252a','hood',1.05,'dcb390','pack'),
 'temari': ('d6ccb7','473c4e','dac17d','tails',.94,'edc2a0','fan'),
 'might_guy': ('2b7944','2b7944','171c23','bowl',1.08,'dfad86','vest'),
 'jiraiya': ('922e3e','53644a','dfdfd5','long_spikes',1.17,'dfad86','scroll'),
 'tsunade': ('c9bdb2','343a49','d8bd75','tails',1.0,'f0c3a6','coat'),
 'hiruzen': ('384552','343f49','babdb9','short',.96,'c89c80','armor'),
 'orochimaru': ('d8d4bf','424050','1e212a','long',.96,'e7dfc8','rope'),
 'kabuto': ('6c638d','44455c','bdc4c9','short',.96,'edb993','glasses'),
 'kimimaro': ('dedcd7','555063','ddded7','long',.98,'e5dac9','bone'),
 'itachi': ('292831','292831','22212c','long',1.0,'dfbb9b','cloak'),
 'kisame': ('292831','292831','1f2936','spikes',1.22,'799da9','sword'),
}

def color(hexcode):
 return [int(hexcode[i:i+2],16)/255 for i in (0,2,4)] + [1.0]

def p(name): return rig.point(name)

class Body(rig.Geometry):
 def tube(self,a,b,ra,rb,color,bone,next_bone=None,segments=10):
  start=len(self.positions)
  super().tube(np.asarray(a),np.asarray(b),ra,rb,color,bone,next_bone,segments)
  if next_bone:
   axis=np.asarray(b)-a
   for i in range(start,len(self.positions)):
    t=float(np.clip(np.dot(self.positions[i]-a,axis)/np.dot(axis,axis),0,1))
    # Match the endpoint to the next joint; caps/finger joints stay connected.
    x=float(np.clip((t-.55)/.45,0,1)); blend=x*x*(3-2*x)
    self.joints[i]=[rig.names[bone],rig.names[next_bone],0,0]
    self.weights[i]=[1-blend,blend,0,0]

 def stick(self,a,b,radius,tint,bone):
  self.tube(np.asarray(a),np.asarray(b),radius,radius,tint,bone,segments=8)

 def ring(self,center,radius,tint,bone,thickness=.4):
  for i in range(16):
   a=math.tau*i/16;b=math.tau*(i+1)/16
   self.stick(center+[math.cos(a)*radius,math.sin(a)*radius,0],center+[math.cos(b)*radius,math.sin(b)*radius,0],thickness,tint,bone)

 def hair_lock(self,a,b,radius,tint):
  self.tube(np.asarray(a),np.asarray(b),radius,radius*.35,tint,'Head',segments=8)


def build(id):
 shirt_hex,pants_hex,hair_hex,style,width,skin_hex,prop=DATA[id]
 shirt,pants,hair,skin=map(color,(shirt_hex,pants_hex,hair_hex,skin_hex))
 dark=color('172230'); white=color('eceade'); silver=color('9aacb4')
 mesh=Body(); hip=p('Hips'); neck=p('Neck'); head=p('Head')+[0,6,-1]
 for bone,nxt,ra,rb in [('Hips','Spine',10.5,11),('Spine','Spine1',11,12),('Spine1','Spine2',12,14)]:
  mesh.tube(p(bone),p(nxt),ra*width,rb*width,shirt,bone,nxt,14)
 mesh.tube(p('Spine2'),neck,13.5*width,4,shirt,'Spine2','Neck',14)
 mesh.ellipsoid(hip+[0,-2,0],[11.5*width,7,7.5],pants,'Hips')
 mesh.tube(neck,p('Head')+[0,3,0],3.5,3.6,skin,'Neck','Head')
 mesh.ellipsoid(head,[8.2*(1.08 if id=='choji' else 1),10.5,7.7],skin,'Head',20,14)
 for side in ('Left','Right'):
  arm,elbow,hand=p(side+'Arm'),p(side+'ForeArm'),p(side+'Hand')
  bare=id in ('ino','tenten','temari','tsunade','kimimaro')
  sleeve=skin if bare else shirt
  mesh.ellipsoid(arm,[5.2*width,5.2,5.2],sleeve,side+'Arm')
  mesh.tube(arm,elbow,5.0*width,4.1*width,sleeve,side+'Arm',side+'ForeArm')
  mesh.ellipsoid(elbow,[4.15*width]*3,sleeve,side+'ForeArm')
  lower=shirt if id in ('rock_lee','might_guy','shino','kankuro','hinata','itachi','kisame') else skin
  mesh.tube(elbow,hand,4.15*width,2.6,lower,side+'ForeArm',side+'Hand')
  palm=p(side+'HandMiddle1')
  mesh.tube(hand,palm,2.9,3.1,skin,side+'Hand')
  for finger in ('Thumb','Index','Middle','Ring','Pinky'):
   for j in range(1,4):
    name=side+'Hand'+finger+str(j); nxt=side+'Hand'+finger+str(j+1)
    mesh.tube(p(name),p(nxt),.8,.65,skin,name,nxt,6)
  thigh,knee,ankle=p(side+'UpLeg'),p(side+'Leg'),p(side+'Foot')
  mesh.tube(thigh,knee,6.8*width,4.9*width,pants,side+'UpLeg',side+'Leg')
  mesh.ellipsoid(knee,[5*width]*3,pants,side+'Leg')
  mesh.tube(knee,ankle,4.9*width,3.2,pants,side+'Leg',side+'Foot')
  toe=p(side+'ToeBase')
  mesh.tube(ankle,ankle+[0,-6,-3],3.2,3.4,dark,side+'Foot')
  mesh.ellipsoid(ankle+[0,-6,-3],[4,3.2,8],dark,side+'Foot')
  mesh.ellipsoid(toe+[0,-2,-1],[3.5,2.1,3.5],skin,side+'ToeBase')
  if id in ('rock_lee','might_guy','neji','kimimaro','tenten'):
   mesh.tube(knee+[0,-12,0],knee+[0,-26,0],5*width,4.5*width,white,side+'Leg',segments=10)
   for row in range(4):
    mesh.tube(knee+[0,-13-row*3,0],knee+[0,-14-row*3,0],5.1*width,5.1*width,color('b4b9b5'),side+'Leg',segments=10)
 # Eyes/eyebrows/nose/mouth are actual face geometry, rigidly attached to Head.
 for sign in (-1,1):
  eye=head+[sign*3.2,1,-7.15]
  mesh.ellipsoid(eye,[2.35,1.15,.7],dark,'Head',12,6)
  mesh.ellipsoid(eye+[0,0,-.5],[2.05,.90,.4],white,'Head',12,6)
  iris=color('bec0d9') if id in ('neji','hinata') else color('709990') if id=='ino' else color('88283b') if id=='itachi' else dark
  mesh.ellipsoid(eye+[0,0,-.8],[.8,.9,.25],iris,'Head',10,6)
  if id not in ('neji','hinata'):
   mesh.ellipsoid(eye+[0,0,-1],[.4,.65,.15],dark,'Head',8,4)
  mesh.box(head+[sign*3.4,3.1,-7.1],[4.4,.6,.5],hair,'Head')
 mesh.ellipsoid(head+[0,-2,-7.6],[.9,1.5,1.2],skin,'Head',10,6)
 mesh.box(head+[0,-5.8,-6.7],[3,.38,.45],color('774846'),'Head')
 mesh.ellipsoid(head+[0,6,1],[8.6,6,8],hair,'Head',18,10)
 if style in ('long','bob','long_spikes'):
  length=20 if style!='bob' else 11
  for sign in (-1,1):
   mesh.hair_lock(head+[sign*7,6,1],head+[sign*8,6-length,2],3.5,hair)
  mesh.ellipsoid(head+[0,0 if style=='bob' else -7,6],[7.7,10 if style=='bob' else 16,3.7],hair,'Head')
 if style=='bowl':
  mesh.ellipsoid(head+[0,4,0],[8.8,7,8.1],hair,'Head',18,10)
  for sign in (-1,1): mesh.box(head+[sign*3.4,3.1,-7.7],[4.4,1.0,.5],hair,'Head')
 if style in ('spikes','short','long_spikes'):
  count=11 if style!='short' else 8
  for i in range(count):
   angle=math.tau*i/count; base=head+[math.cos(angle)*6.5,8,math.sin(angle)*5.8]
   tip=base+[math.cos(angle)*3,3+(i%3)*2,math.sin(angle)*3]
   mesh.spike(base,tip,2.6,hair)
 if style=='pony':
  mesh.hair_lock(head+[0,9,5],head+[0,19 if id=='shikamaru' else -12,12],3.8,hair)
 if style in ('buns','tails'):
  for sign in (-1,1):
   mesh.ellipsoid(head+[sign*8,6,2],[3.8,3.8,3.8],hair,'Head')
   if style=='tails': mesh.hair_lock(head+[sign*8,5,3],head+[sign*11,-9,5],2.6,hair)
 if style=='hood':
  mesh.ellipsoid(head+[0,5,4],[10,10,7],shirt,'Head')
  for sign in (-1,1): mesh.ellipsoid(head+[sign*8,0,0],[2.7,9,6],shirt,'Head')
 if id not in ('gaara','ino','temari','tsunade','orochimaru','kimimaro'):
  mesh.box(head+[0,5,-7.4],[15,2.5,1.4],dark,'Head')
  mesh.box(head+[0,5,-8.2],[9,2.0,.35],silver,'Head')
  mesh.box(head+[0,5,-8.5],[3,.35,.12],dark,'Head')
 # Distinct garments and tools are part of the skinned mesh, not floating overlays.
 chest=p('Spine2'); waist=p('Hips')+[0,3,0]
 if prop in ('vest','armor'):
  tint=color('607656') if prop=='vest' else color('637484')
  mesh.tube(p('Spine'),chest,12*width,15*width,tint,'Spine','Spine2',14)
  for sign in (-1,1): mesh.box(chest+[sign*6*width,-3,-14*width],[5,7,2],tint,'Spine2')
 if prop in ('coat','cloak') or id in ('shino','kankuro','kisame'):
  tint=color('55725d') if prop=='coat' else shirt
  mesh.tube(hip+[0,-24,0],hip+[0,9,0],18*width,13*width,tint,'Hips','Spine',16)
  for sign in (-1,1): mesh.box(chest+[sign*5,1,-12],[5,19,2],tint,'Spine2')
  if prop=='cloak' or id=='kisame':
   for sign in (-1,1):
    for row in range(2):
     mesh.ellipsoid(hip+[sign*8,-3-row*12,-17],[4.5,2.2,1.1],color('a73343'),'Hips',12,6)
 if prop=='skirt': mesh.tube(hip+[0,-13,0],hip+[0,6,0],15,11,shirt,'Hips','Spine',14)
 if prop in ('rope','gourd','fan','skirt','coat','bone'):
  mesh.tube(waist+[0,-3,0],waist+[0,3,0],13*width,13*width,color('8d678e') if prop in ('rope','bone') else dark,'Hips',segments=16)
 if prop=='glasses':
  for sign in (-1,1): mesh.ring(head+[sign*3.2,1,-8.35],2.6,silver,'Head',.35)
  mesh.stick(head+[-1,1,-8.4],head+[1,1,-8.4],.3,silver,'Head')
 if prop=='gourd':
  mesh.ellipsoid(chest+[7,-6,17],[10,13,9],color('ba9969'),'Spine2')
  mesh.ellipsoid(chest+[7,10,17],[6.2,7,5.8],color('ba9969'),'Spine2')
  mesh.tube(chest+[7,15,17],chest+[7,20,17],2,2,color('62523b'),'Spine2')
 if prop=='fan':
  center=chest+[0,6,18]
  for i in range(9):
   angle=(i-4)*.19
   mesh.stick(center,center+[math.sin(angle)*34,math.cos(angle)*34,0],1.0,dark,'Spine2')
   if i<8:
    nxt=(i+1-4)*.19
    mesh.triangle(center,center+[math.sin(angle)*34,math.cos(angle)*34,0],center+[math.sin(nxt)*34,math.cos(nxt)*34,0],color('dedbc9'),'Spine2')
  for sign in (-1,1): mesh.ellipsoid(center+[sign*12,23,-.4],[4.4,4.4,.7],color('7c557d'),'Spine2',12,6)
 if prop in ('scroll','pack','sword'):
  tint=color('c5ba96')
  if prop=='scroll': mesh.tube(chest+[-18,-4,17],chest+[18,-4,17],7,7,tint,'Spine2')
  elif prop=='pack': mesh.box(chest+[0,-3,17],[17,30,12],color('795b43'),'Spine2')
  else:
   mesh.stick(chest+[-10,-23,15],chest+[18,34,15],4.7,tint,'Spine2')
   mesh.stick(chest+[18,34,15],chest+[24,46,15],2,dark,'Spine2')
 if prop=='fur':
  for i in range(12):
   angle=math.tau*i/12
   mesh.ellipsoid(neck+[math.cos(angle)*7,-2,math.sin(angle)*6],[3,3,3],color('d3cec3'),'Neck',10,6)
 if prop=='scarf': mesh.tube(neck-[0,4,0],neck+[0,1,0],7,7,color('ded4b7'),'Neck')
 if prop=='bone':
  for side in ('Left','Right'):
   elbow=p(side+'ForeArm'); hand=p(side+'Hand')
   mesh.tube(elbow+[0,0,-5],hand+[0,-14,-5],1.6,.35,white,side+'ForeArm',side+'Hand',8)
 if id=='kiba':
  for sign in (-1,1): mesh.triangle(head+[sign*4,-1,-7.8],head+[sign*6,-1,-7.1],head+[sign*4,-5,-7.2],color('a53e3f'),'Head')
 if id=='choji':
  for sign in (-1,1): mesh.ring(head+[sign*5,-2,-7],1.5,color('995442'),'Head',.3)
 if id=='hiruzen': mesh.stick(chest+[14,-38,16],chest+[14,30,16],2,dark,'Spine2')
 return mesh


def main():
 manifest={'generator':'tools/create_roster_fighters.py','source_skeleton_sha256':hashlib.sha256((ROOT/'assets/characters/rigged.glb').read_bytes()).hexdigest(),'characters':{}}
 manifest['preserved_ready_models'] = {path: hashlib.sha256((ROOT/path).read_bytes()).hexdigest() for path in [
  'assets/characters/base_basic/base_basic_pbr_rigged.glb', 'assets/characters/stylized/sasuke.glb',
  'assets/characters/stylized/kakashi.glb', 'assets/characters/sakura_user/sakura_mobile_rigged.glb',
  'assets/characters/henrique/henrique_mobile_rigged.glb']}
 for id in DATA:
  destination=ROOT/f'assets/characters/final/{id}/{id}_mobile.glb'
  if destination.exists(): raise SystemExit('Refusing to overwrite existing ready model: '+str(destination))
 for id in DATA:
  mesh=build(id); destination=ROOT/f'assets/characters/final/{id}/{id}_mobile.glb'
  rig.export(id,mesh,destination)
  manifest['characters'][id]={'path':destination.relative_to(ROOT).as_posix(),'vertices':len(mesh.positions),'triangles':len(mesh.indices)//3,'joints':65,'sha256':hashlib.sha256(destination.read_bytes()).hexdigest()}
 (ROOT/'assets/characters/final/roster_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
if __name__=='__main__': main()
