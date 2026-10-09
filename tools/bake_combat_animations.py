#!/usr/bin/env python3
"""Bake CC0 Quaternius clips to this character's actual Mixamo bind skeleton.

Requires numpy and scipy; run from any directory. No Blender/runtime retargeting.
The imported node pose is NOT a T-pose: reference target rotations come from
inverse bind matrices. glTF uses xyzw quaternions, as does Godot.
"""
from pathlib import Path
import hashlib
import json
import struct

import numpy as np
from scipy.spatial.transform import Rotation, Slerp

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'assets/animations/source'
FPS = 30


class Gltf:
    def __init__(self, path):
        self.path = Path(path)
        raw = self.path.read_bytes()
        if self.path.suffix == '.glb':
            size = struct.unpack_from('<I', raw, 12)[0]
            self.data = json.loads(raw[20:20 + size])
            self.buffer = raw[28 + size:]
        else:
            self.data = json.loads(raw)
            self.buffer = (self.path.parent / self.data['buffers'][0]['uri']).read_bytes()
        self.nodes = self.data['nodes']
        self.names = {n.get('name'): i for i, n in enumerate(self.nodes)}
        self.parents = {c: i for i, n in enumerate(self.nodes) for c in n.get('children', [])}
        self.clips = {a['name']: a for a in self.data.get('animations', [])}

    def accessor(self, index):
        a = self.data['accessors'][index]
        v = self.data['bufferViews'][a['bufferView']]
        dims = {'SCALAR': 1, 'VEC3': 3, 'VEC4': 4, 'MAT4': 16}[a['type']]
        assert a['componentType'] == 5126 and 'byteStride' not in v
        return np.frombuffer(self.buffer, '<f4', a['count'] * dims,
                             v.get('byteOffset', 0) + a.get('byteOffset', 0)).reshape(-1, dims).copy()

    def duration(self, clip):
        return max(float(self.accessor(s['input'])[-1, 0]) for s in self.clips[clip]['samplers'])

    def globals(self, clip, time):
        rotations = [Rotation.from_quat(n.get('rotation', [0, 0, 0, 1])) for n in self.nodes]
        translations = [np.array(n.get('translation', [0, 0, 0]), float) for n in self.nodes]
        for channel in self.clips[clip]['channels']:
            sampler = self.clips[clip]['samplers'][channel['sampler']]
            assert sampler.get('interpolation', 'LINEAR') in ['LINEAR', 'STEP']
            times = self.accessor(sampler['input'])[:, 0]
            values = self.accessor(sampler['output'])
            t = np.clip(time, times[0], times[-1])
            if sampler.get('interpolation') == 'STEP':
                t = times[max(0, np.searchsorted(times, t, side='right') - 1)]
            index = channel['target']['node']
            kind = channel['target']['path']
            if kind == 'rotation':
                rotations[index] = (Rotation.from_quat(values[0]) if len(times) == 1 else
                                    Slerp(times, Rotation.from_quat(values))(t))
            elif kind == 'translation':
                translations[index] = np.array([np.interp(t, times, values[:, k]) for k in range(3)])
        result = {}

        def visit(i):
            if i not in result:
                r, p = rotations[i], translations[i]
                if i in self.parents:
                    pr, pp = visit(self.parents[i])
                    p, r = pp + pr.apply(p), pr * r
                result[i] = r, p
            return result[i]

        for i in range(len(self.nodes)):
            visit(i)
        return result


MAP1 = {
    'Hips': 'DEF-hips', 'Spine': 'DEF-spine.001', 'Spine1': 'DEF-spine.002',
    'Spine2': 'DEF-spine.003', 'Neck': 'DEF-neck', 'Head': 'DEF-head',
}
MAP2 = {'Hips': 'pelvis', 'Spine': 'spine_01', 'Spine1': 'spine_02',
        'Spine2': 'spine_03', 'Neck': 'neck_01', 'Head': 'Head'}
for side, suffix in [('Left', 'L'), ('Right', 'R')]:
    for target, src1, src2 in [('Shoulder', 'shoulder', 'clavicle'), ('Arm', 'upper_arm', 'upperarm'),
                               ('ForeArm', 'forearm', 'lowerarm'), ('Hand', 'hand', 'hand'),
                               ('UpLeg', 'thigh', 'thigh'), ('Leg', 'shin', 'calf'),
                               ('Foot', 'foot', 'foot'), ('ToeBase', 'toe', 'ball')]:
        MAP1[side + target] = f'DEF-{src1}.{suffix}'
        MAP2[side + target] = f'{src2}_{suffix.lower()}'
    for finger in ['Thumb', 'Index', 'Middle', 'Ring', 'Pinky']:
        for j in range(1, 4):
            name = finger.lower()
            MAP1[f'{side}Hand{finger}{j}'] = f'DEF-{name if name == "thumb" else "f_" + name}.0{j}.{suffix}'
            MAP2[f'{side}Hand{finger}{j}'] = f'{name}_0{j}_{suffix.lower()}'


def spec(pack, clip, duration=None, loop=False, **kw):
    return dict(pack=pack, clip=clip, duration=duration, loop=loop, **kw)


# These are adaptations of sampled artist-made clips, never synthetic sine poses.
# Aerial strikes keep the real upper-body motion and use NinjaJump's leg motion.
SPECS = {
    'idle': spec(1, 'Idle_Loop', loop=True),
    'run': spec(1, 'Jog_Fwd_Loop', loop=True),
    'sprint': spec(1, 'Sprint_Loop', loop=True),
    'strafe_left': spec(1, 'Jog_Fwd_Loop', loop=True, leg_yaw=-70),
    'strafe_right': spec(1, 'Jog_Fwd_Loop', loop=True, leg_yaw=70),
    'back_run': spec(1, 'Jog_Fwd_Loop', loop=True, reverse=True),
    'rasengan': spec(1, 'Punch_Cross', .95, start=.10, end=.90, impact=.38, bone='RightHand'),
    'guard_break': spec(2, 'Idle_Shield_Break', 1.0),
    'jump': spec(2, 'NinjaJump_Start', .36, start=.25, end=.88),
    'fall': spec(2, 'NinjaJump_Idle_Loop', loop=True),
    'land': spec(2, 'NinjaJump_Land', .18, start=0, end=.35),
    'attack_1': spec(1, 'Punch_Jab', .28, start=.10, end=.75, impact=.12, bone='LeftHand'),
    'attack_2': spec(1, 'Punch_Cross', .30, start=.10, end=.90, impact=.14, bone='RightHand'),
    'attack_3': spec(2, 'Melee_Hook', .34, recovery='Melee_Hook_Rec', impact=.10, bone='RightHand'),
    'attack_4': spec(2, 'Melee_Hook', .40, recovery='Melee_Hook_Rec', uppercut=True,
                     impact=.12, bone='RightHand'),
    'air_attack_1': spec(1, 'Punch_Jab', .30, start=.10, end=.75, aerial=True, impact=.13, bone='LeftHand'),
    'air_attack_2': spec(1, 'Punch_Cross', .30, start=.10, end=.90, aerial=True, impact=.14, bone='RightHand'),
    'air_attack_3': spec(2, 'Melee_Hook', .34, recovery='Melee_Hook_Rec', aerial=True, impact=.10, bone='RightHand'),
    'air_attack_4': spec(2, 'Sword_Heavy_Combo', .44, start=2.20, end=3.40, aerial=True,
                         impact=.15, bone='RightHand'),
    'guard': spec(2, 'Idle_Shield_Loop', loop=True),
    'dodge': spec(1, 'Roll', .24),
    'chakra_dash': spec(2, 'Sword_Dash', .30, start=.15, end=.80),
    'chakra_charge': spec(1, 'Spell_Simple_Idle_Loop', loop=True),
    'jutsu': spec(1, 'Spell_Simple_Shoot', .48, impact=.24),
    'hit': spec(1, 'Hit_Chest', .30),
    'knockback': spec(2, 'Hit_Knockback', .55),
    'defeat': spec(1, 'Death01', 1.25),
}

# Ten combat trajectories, each with ten spatial adaptations. These are
# explicitly variants of the pinned CC0 sources, not 100 new mocap recordings.
COMBAT_FORMS = {
    'jab': spec(1, 'Punch_Jab', .34, start=.06, end=.80, impact=.14, bone='LeftHand'),
    'cross': spec(1, 'Punch_Cross', .38, start=.06, end=.96, impact=.18, bone='RightHand'),
    'hook': spec(2, 'Melee_Hook', .42, recovery='Melee_Hook_Rec', impact=.14, bone='RightHand'),
    'uppercut': spec(2, 'Melee_Hook', .46, recovery='Melee_Hook_Rec', uppercut=True, impact=.18, bone='RightHand'),
    'slash': spec(2, 'Sword_Heavy_Combo', .58, start=.15, end=1.35, impact=.24, bone='RightHand'),
    'overhead': spec(2, 'Sword_Heavy_Combo', .62, start=2.10, end=3.65, impact=.28, bone='RightHand'),
    'thrust': spec(2, 'Sword_Dash', .52, start=.10, end=1.10, impact=.22, bone='RightHand'),
    'cast': spec(1, 'Spell_Simple_Shoot', .56, impact=.28, bone='RightHand'),
    'evade': spec(1, 'Roll', .48, start=.05, end=1.40),
    'recoil': spec(2, 'Hit_Knockback', .50, start=.02, end=.80),
}
VARIANTS = {
    'center': {}, 'left': {'aim_yaw': -25}, 'right': {'aim_yaw': 25},
    'low': {'aim_pitch': -24}, 'high': {'aim_pitch': 24},
    'mirror': {'mirror': True},
    'mirror_left': {'mirror': True, 'aim_yaw': -25},
    'mirror_right': {'mirror': True, 'aim_yaw': 25},
    'aerial': {'aerial': True}, 'aerial_mirror': {'aerial': True, 'mirror': True},
}
for form, config in COMBAT_FORMS.items():
    for variant, changes in VARIANTS.items():
        cfg = {**config, **changes, 'expansion': True, 'category': form, 'variant': variant}
        if cfg.get('mirror') and 'bone' in cfg:
            cfg['bone'] = cfg['bone'].replace('Right', 'Left') if cfg['bone'].startswith('Right') else cfg['bone'].replace('Left', 'Right')
        SPECS[f'combat_{form}_{variant}'] = cfg


def fmt(values):
    return ', '.join(f'{float(v):.8g}' for v in np.asarray(values).flatten())


def bake():
    target = Gltf(ROOT / 'assets/characters/rigged.glb')
    sources = {1: Gltf(SOURCE / 'AnimationLibrary_Godot_Standard.gltf'),
               2: Gltf(SOURCE / 'UAL2_Standard.glb')}
    skin = next(s for s in target.data['skins'] if target.nodes[s['joints'][0]]['name'] == 'mixamorig:Hips')
    matrices = target.accessor(skin['inverseBindMatrices']).reshape(-1, 4, 4).transpose(0, 2, 1)
    bind = {}
    for i, m in zip(skin['joints'], matrices):
        g = np.linalg.inv(m)
        # Skin inverse binds contain 0.01 scale; Skeleton3D uses centimeter units.
        bind[i] = Rotation.from_matrix(g[:3, :3] / np.linalg.norm(g[:3, :3], axis=0)), g[:3, 3] * 100
    local = {}
    for i, (r, p) in bind.items():
        pr, pp = bind.get(target.parents.get(i), (Rotation.identity(), np.zeros(3)))
        local[i] = pr.inv() * r, pr.inv().apply(p - pp)
    alignment = Rotation.from_euler('y', 180, degrees=True)
    references = {k: s.globals('A_TPose', 0) for k, s in sources.items()}
    maps = {1: MAP1, 2: MAP2}
    output = []
    manifest = {'schema': 1, 'fps': FPS, 'target_sha256': hashlib.sha256(target.path.read_bytes()).hexdigest(),
                'source_sha256': {p.name: hashlib.sha256(p.read_bytes()).hexdigest()
                                  for p in sorted(SOURCE.iterdir()) if p.suffix in ['.glb', '.gltf', '.bin']}, 'clips': {}}
    for name, cfg in SPECS.items():
        s = sources[cfg['pack']]
        start = cfg.get('start', 0)
        end = cfg.get('end', s.duration(cfg['clip']))
        source_length = end - start
        if 'recovery' in cfg:
            source_length += s.duration(cfg['recovery'])
        length = cfg['duration'] or source_length
        times = np.linspace(0, length, max(3, int(np.ceil(length * FPS)) + 1))
        rotations = {i: [] for i in bind}
        positions = []
        for time in times:
            phase = time / length
            st = start + (1.0 - phase if cfg.get("reverse") else phase) * source_length
            clip = cfg['clip']
            if st > end and 'recovery' in cfg:
                clip, st = cfg['recovery'], st - end
            pose = s.globals(clip, st)
            ref = references[cfg['pack']]
            mapping = maps[cfg['pack']]
            airborne = sources[2].globals('NinjaJump_Idle_Loop', phase * 2.0) if cfg.get('aerial') else None
            desired = {}
            for i, (tr, _) in bind.items():
                short = target.nodes[i]['name'].split(':')[-1]
                ps, rs, mp = pose, ref, mapping
                src = s
                if airborne is not None and any(x in short for x in ['UpLeg', 'Leg', 'Foot', 'Toe']):
                    ps, rs, mp, src = airborne, references[2], MAP2, sources[2]
                if short in mp:
                    si = src.names[mp[short]]
                    delta = alignment * ps[si][0] * rs[si][0].inv() * alignment.inv()
                    desired[i] = delta * tr
                else:
                    parent = target.parents.get(i)
                    desired[i] = desired[parent] * local[i][0] if parent in desired else tr
            # Uppercut: rotate the hook's sampled arm trajectory upward in world space.
            # Use a smooth 0 -> peak -> 0 envelope while preserving all source motion.
            if cfg.get('uppercut'):
                weight = np.sin(np.pi * phase)
                for short in ['RightArm', 'RightForeArm', 'RightHand']:
                    i = target.names['mixamorig:' + short]
                    desired[i] = Rotation.from_euler('x', 55 * weight, degrees=True) * desired[i]
            if cfg.get("leg_yaw"):
                leg_rotation = Rotation.from_euler("y", cfg["leg_yaw"], degrees=True)
                for i in bind:
                    short = target.nodes[i]["name"].split(":")[-1]
                    if any(x in short for x in ["UpLeg", "Leg", "Foot", "Toe"]):
                        desired[i] = leg_rotation * desired[i]
            if cfg.get('mirror'):
                # Reflect animation deltas, then apply each target bone's own
                # bind frame; reflecting bind rotations breaks asymmetric rigs.
                reflection = np.diag([-1.0, 1.0, 1.0])
                original = desired.copy()
                for i, (tr, _) in bind.items():
                    name_i = target.nodes[i]['name']
                    opposite = name_i.replace('Left', 'Right') if 'Left' in name_i else name_i.replace('Right', 'Left')
                    other = target.names.get(opposite, i)
                    delta = original[other] * bind[other][0].inv()
                    desired[i] = Rotation.from_matrix(reflection @ delta.as_matrix() @ reflection) * tr
            if cfg.get('aim_yaw') or cfg.get('aim_pitch'):
                envelope = np.sin(np.pi * phase)
                aim = Rotation.from_euler('yx', [cfg.get('aim_yaw', 0) * envelope,
                                                cfg.get('aim_pitch', 0) * envelope], degrees=True)
                for i in bind:
                    short = target.nodes[i]['name'].split(':')[-1]
                    if not any(x in short for x in ['Hips', 'UpLeg', 'Leg', 'Foot', 'Toe']):
                        desired[i] = aim * desired[i]
            for i in bind:
                parent = target.parents.get(i)
                pr = desired.get(parent, Rotation.identity())
                rotations[i].append((pr.inv() * desired[i]).as_quat())
            hi = s.names[mapping['Hips']]
            displacement = alignment.apply(pose[hi][1] - ref[hi][1])
            scale = bind[target.names['mixamorig:Hips']][1][1] / ref[hi][1][1]
            displacement *= scale
            if cfg.get('mirror'):
                displacement[0] *= -1
            # In-place controller owns travel/jump. Keep authored pelvis bob/collapse.
            displacement[[0, 2]] = np.clip(displacement[[0, 2]], -15, 15)
            if name in ['jump', 'fall', 'land'] or cfg.get('aerial'):
                displacement[1] = 0
            positions.append(local[target.names['mixamorig:Hips']][1] + displacement)
        tracks = []
        # bind iteration is skin order, parent before child. All bones write their
        # fixed target length, so mixing cannot leak happy's non-bind translations.
        for i in bind:
            short = target.nodes[i]['name'].replace(':', '_')
            quats = np.array(rotations[i])
            for k in range(1, len(quats)):
                if np.dot(quats[k-1], quats[k]) < 0:
                    quats[k] *= -1
            if cfg['loop']:
                quats[-1] = quats[0]
            for typ, vals, ts in [('rotation_3d', quats, times),
                                  ('position_3d', np.array(positions) if short == 'mixamorig_Hips'
                                   else np.array([local[i][1]]), times if short == 'mixamorig_Hips' else [0])]:
                if cfg['loop'] and typ == 'position_3d' and len(vals) > 1:
                    vals[-1] = vals[0]
                flat = []
                for t, v in zip(ts, vals):
                    flat.extend([t, 1, *v])
                n = len(tracks)
                tracks.append(f'tracks/{n}/type = "{typ}"\n'
                              f'tracks/{n}/path = NodePath("Skeleton3D:{short}")\n'
                              f'tracks/{n}/interp = 1\n'
                              f'tracks/{n}/loop_wrap = true\n'
                              f'tracks/{n}/enabled = true\n'
                              f'tracks/{n}/keys = PackedFloat32Array({fmt(flat)})')
        output.append(f'[sub_resource type="Animation" id="Animation_{name}"]\n'
                      f'resource_name = "{name}"\nlength = {length:.8g}\nstep = {1/FPS:.8g}\n'
                      f'loop_mode = {1 if cfg["loop"] else 0}\n' + '\n'.join(tracks))
        manifest['clips'][name] = {**cfg, 'duration': length, 'samples': len(times), 'bone_count': len(bind),
                                   'license': 'CC0-1.0', 'author': 'Quaternius',
                                   'adaptation': 'uppercut' if cfg.get('uppercut') else
                                                 'aerial legs' if cfg.get('aerial') else 'retarget/in-place'}
    for name, config in manifest['clips'].items():
        if 'attack_' in name or name == 'rasengan' or (config.get('expansion') and 'impact' in config):
            config['startup'] = config['impact']
            config['active'] = .09 if name != 'rasengan' else .3
            config['recovery'] = round(config['duration'] - config['startup'] - config['active'], 3)
            config['cancel_open'] = config['startup'] + config['active']
            config['cancel_close'] = config['duration']
            config['cancel_requires_hit'] = True
    text = f'[gd_resource type="AnimationLibrary" load_steps={len(output)+1} format=3]\n\n'
    text += '\n\n'.join(output)
    text += '\n\n[resource]\n_data = {\n'
    text += ',\n'.join(f'&"{n}": SubResource("Animation_{n}")' for n in SPECS)
    text += '\n}\n'
    (ROOT / 'assets/animations/combat_mixamo.tres').write_text(text)
    (ROOT / 'assets/animations/combat_manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(f'Baked {len(SPECS)} clips (27 preserved + 100 CC0 adaptations), {len(bind)} bones each, {len(text):,} bytes')


if __name__ == '__main__':
    bake()
