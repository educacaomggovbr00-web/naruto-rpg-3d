#!/usr/bin/env python3
"""Offline pose fitting, skinning and mobile mesh preparation for supplied GLBs.

Requires numpy, scipy, Pillow and gltfpack 1.3. Large original source GLBs are
kept outside the Git repository; pass them explicitly when rebuilding.
The supplied model has an asymmetric bent-arm pose. Fit joint landmarks in that
pose, blend adjacent bone influences, then move the mesh to the combat bind pose.
Animations remain the existing artist-authored CC0 library; no runtime baking.
"""
from __future__ import annotations

import argparse
import copy
import hashlib
import io
import json
import struct
import subprocess
import tempfile
from pathlib import Path

import numpy as np
from PIL import Image
from scipy.spatial.transform import Rotation

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets/characters/base_basic"
VARIANTS = ("pbr", "shaded")
# Centimeters, after turning the supplied +Z-facing model to the rig's -Z axis.
# These landmarks describe this specific mesh, not a general automatic rigger.
LANDMARKS = {
    "Hips": [0, 88, 8], "Spine": [0, 98, 8],
    "Spine1": [0, 111, 7], "Spine2": [0, 123, 6],
    "Neck": [0, 135, 7], "Head": [0, 143, 8],
    "HeadTop_End": [0, 165, 8],
    "LeftShoulder": [-7, 130, 5], "LeftArm": [-22, 130, 5],
    "LeftForeArm": [-32, 114, -6], "LeftHand": [-25, 133, -21],
    "RightShoulder": [7, 130, 5], "RightArm": [22, 129, 5],
    "RightForeArm": [33, 109, 1], "RightHand": [25, 95, -10],
    "LeftUpLeg": [-12, 82, 8], "LeftLeg": [-20, 46, 7],
    "LeftFoot": [-25, 10, 5], "LeftToeBase": [-27, 3, -5],
    "LeftToe_End": [-27, 3, -13],
    "RightUpLeg": [12, 82, 8], "RightLeg": [20, 46, 7],
    "RightFoot": [25, 10, 5], "RightToeBase": [27, 3, -5],
    "RightToe_End": [27, 3, -13],
}
CHAINS = [
    ["Hips", "Spine", "Spine1", "Spine2", "Neck", "Head", "HeadTop_End"],
    ["Spine2", "LeftShoulder", "LeftArm", "LeftForeArm", "LeftHand"],
    ["Spine2", "RightShoulder", "RightArm", "RightForeArm", "RightHand"],
    ["Hips", "LeftUpLeg", "LeftLeg", "LeftFoot", "LeftToeBase", "LeftToe_End"],
    ["Hips", "RightUpLeg", "RightLeg", "RightFoot", "RightToeBase", "RightToe_End"],
]


class GLB:
    def __init__(self, path: Path):
        self.raw = path.read_bytes()
        assert struct.unpack_from("<4sII", self.raw) == (b"glTF", 2, len(self.raw))
        size, kind = struct.unpack_from("<II", self.raw, 12)
        assert kind == 0x4E4F534A
        self.data = json.loads(self.raw[20:20 + size])
        bin_size, kind = struct.unpack_from("<II", self.raw, 20 + size)
        assert kind == 0x004E4942
        self.buffer = self.raw[28 + size:28 + size + bin_size]

    def accessor(self, index):
        a = self.data["accessors"][index]
        v = self.data["bufferViews"][a["bufferView"]]
        dims = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}[a["type"]]
        dtype = np.dtype({5121: "u1", 5123: "<u2", 5125: "<u4", 5126: "<f4"}[a["componentType"]])
        assert "sparse" not in a
        return np.ndarray((a["count"], dims), dtype=dtype, buffer=self.buffer,
                          offset=v.get("byteOffset", 0) + a.get("byteOffset", 0),
                          strides=(v.get("byteStride", dims * dtype.itemsize), dtype.itemsize)).copy()

    def image(self, image):
        view = self.data["bufferViews"][image["bufferView"]]
        start = view.get("byteOffset", 0)
        return self.buffer[start:start + view["byteLength"]]


def combat_bind(source):
    data = source.data
    skin = next(s for s in data["skins"] if data["nodes"][s["joints"][0]]["name"] == "mixamorig:Hips")
    original_indices = skin["joints"]
    names = [data["nodes"][i]["name"].split(":")[-1] for i in original_indices]
    index = {name: i for i, name in enumerate(names)}
    remap = {old: new for new, old in enumerate(original_indices)}
    parents = {remap[c]: remap[i] for i in original_indices
               for c in data["nodes"][i].get("children", []) if c in remap}
    matrices = source.accessor(skin["inverseBindMatrices"]).reshape(-1, 4, 4).transpose(0, 2, 1)
    world = np.linalg.inv(matrices).astype(float)
    # Matches bake_combat_animations.py: skeleton lengths in centimeters.
    world[:, :3, 3] *= 100
    world[:, :3, :3] /= np.linalg.norm(world[:, :3, :3], axis=1)[:, None, :]
    return names, index, parents, world


def fit_source_bind(names, index, parents, target):
    source = target.copy()
    child = {}
    for chain in CHAINS:
        for a, b in zip(chain, chain[1:]):
            child.setdefault(a, b)
    child["LeftHand"] = "LeftHandMiddle1"
    child["RightHand"] = "RightHandMiddle1"
    for i, name in enumerate(names):
        if name not in LANDMARKS:
            # Unweighted finger bones follow the fitted wrist frame; fist shape
            # stays on Hand rather than inventing open-finger geometry.
            parent = parents[i]
            source[i] = source[parent] @ np.linalg.inv(target[parent]) @ target[i]
            continue
        source[i, :3, 3] = LANDMARKS[name]
        end = child.get(name)
        if name.endswith("Hand"):
            direction = np.array([-2, 6, -1] if name.startswith("Left") else [-5, -3, -2], float)
            reference = target[index[end], :3, 3] - target[i, :3, 3]
        elif end in LANDMARKS:
            direction = np.array(LANDMARKS[end]) - np.array(LANDMARKS[name])
            reference = target[index[end], :3, 3] - target[i, :3, 3]
        else:
            continue
        delta, _ = Rotation.align_vectors([direction / np.linalg.norm(direction)],
                                          [reference / np.linalg.norm(reference)])
        source[i, :3, :3] = delta.as_matrix() @ target[i, :3, :3]
    return source


def skin_weights(positions, names, index):
    bones = []
    starts, ends = [], []
    neighbors = {name: {name} for name in LANDMARKS}
    for chain in CHAINS:
        for a, b in zip(chain, chain[1:]):
            neighbors[a].add(b)
            neighbors[b].add(a)
            if a not in bones:
                bones.append(a)
                starts.append(LANDMARKS[a])
                ends.append(LANDMARKS[b])
    for hand, offset in [("LeftHand", [-2, 6, -1]), ("RightHand", [-5, -3, -2])]:
        bones.append(hand)
        starts.append(LANDMARKS[hand])
        ends.append(np.array(LANDMARKS[hand]) + offset)
    starts, ends = np.array(starts), np.array(ends)
    directions = ends - starts
    relative = positions[:, None, :] - starts[None, :, :]
    t = np.clip(np.sum(relative * directions, axis=2) / np.sum(directions ** 2, axis=1), 0, 1)
    distance2 = np.sum((relative - t[:, :, None] * directions) ** 2, axis=2)
    nearest = distance2.argmin(axis=1)
    allowed = np.array([[candidate in neighbors[bone] for candidate in bones] for bone in bones])
    scores = np.where(allowed[nearest], np.exp(-(distance2 - distance2.min(axis=1)[:, None]) / 45.0), 0)
    # Hair, face and collar must follow the head rather than the raised fist.
    head = (positions[:, 1] > 139) & (positions[:, 2] > -10)
    scores[head] = 0
    scores[head, bones.index("Head")] = 1
    selected = np.argsort(scores, axis=1)[:, -4:][:, ::-1]
    weights = np.take_along_axis(scores, selected, axis=1)
    weights /= weights.sum(axis=1)[:, None]
    joints = np.array([index[name] for name in bones], dtype=np.uint16)[selected]
    assert np.isfinite(weights).all() and np.max(np.abs(weights.sum(axis=1) - 1)) < 1e-6
    return joints, weights.astype("<f4")


def repose(positions, normals, joints, weights, source, target):
    transforms = target @ np.linalg.inv(source)
    out = np.zeros_like(positions)
    normal_out = np.zeros_like(normals)
    for influence in range(4):
        matrices = transforms[joints[:, influence]]
        out += (np.einsum("nij,nj->ni", matrices[:, :3, :3], positions)
                + matrices[:, :3, 3]) * weights[:, influence, None]
        normal_out += np.einsum("nij,nj->ni", matrices[:, :3, :3], normals) * weights[:, influence, None]
    normal_out /= np.maximum(np.linalg.norm(normal_out, axis=1, keepdims=True), 1e-8)
    return out, normal_out


def export(variant, mesh, rig, textures, size):
    positions, normals, uv, indices, joints, weights = mesh
    names, index, parents, world = rig
    binary = bytearray()
    views, accessors = [], []

    def put_bytes(content, target=None):
        binary.extend(b"\0" * (-len(binary) % 4))
        view = {"buffer": 0, "byteOffset": len(binary), "byteLength": len(content)}
        if target:
            view["target"] = target
        views.append(view)
        binary.extend(content)
        return len(views) - 1

    def put(values, dtype, kind, component, target=None):
        values = np.asarray(values, dtype=dtype)
        a = {"bufferView": put_bytes(values.tobytes(), target), "componentType": component,
             "count": len(values), "type": kind}
        if kind == "VEC3":
            a.update(min=values.min(axis=0).tolist(), max=values.max(axis=0).tolist())
        accessors.append(a)
        return len(accessors) - 1

    attrs = {
        "POSITION": put(positions, "<f4", "VEC3", 5126, 34962),
        "NORMAL": put(normals, "<f4", "VEC3", 5126, 34962),
        "TEXCOORD_0": put(uv, "<f4", "VEC2", 5126, 34962),
        "JOINTS_0": put(joints, "<u2", "VEC4", 5123, 34962),
        "WEIGHTS_0": put(weights, "<f4", "VEC4", 5126, 34962),
    }
    faces = put(indices.reshape(-1, 1), "<u2" if len(positions) < 65536 else "<u4",
                "SCALAR", 5123 if len(positions) < 65536 else 5125, 34963)
    inverse = put(np.linalg.inv(world).transpose(0, 2, 1).reshape(-1, 16), "<f4", "MAT4", 5126)
    times = put([[0], [1]], "<f4", "SCALAR", 5126)
    roots = put([world[0, :3, 3]] * 2, "<f4", "VEC3", 5126)
    nodes = []
    for i, name in enumerate(names):
        local = np.linalg.inv(world[parents[i]]) @ world[i] if i in parents else world[i]
        node = {"name": "mixamorig:" + name, "translation": local[:3, 3].tolist(),
                "rotation": Rotation.from_matrix(local[:3, :3]).as_quat().tolist()}
        children = [child for child, parent in parents.items() if parent == i]
        if children:
            node["children"] = children
        nodes.append(node)
    nodes.append({"name": "BaseBasicMesh", "mesh": 0, "skin": 0})
    nodes.append({"name": "BaseBasicRig", "children": [0, len(names)]})
    original = textures.data
    images = []
    for image in original["images"]:
        im = Image.open(io.BytesIO(textures.image(image))).convert("RGB")
        im.thumbnail((size, size), Image.Resampling.LANCZOS)
        encoded = io.BytesIO()
        im.save(encoded, format="PNG", optimize=True)
        images.append({"name": image.get("name", "texture"), "mimeType": "image/png",
                       "bufferView": put_bytes(encoded.getvalue())})
    material = copy.deepcopy(original["materials"][0])
    material["name"] = "BaseBasic" + variant.capitalize()
    material["doubleSided"] = False
    document = {
        "asset": {"version": "2.0", "generator": "rig_base_basic_models.py / gltfpack 1.3"},
        "scene": 0, "scenes": [{"nodes": [len(nodes) - 1]}], "nodes": nodes,
        "meshes": [{"name": "BaseBasic", "primitives": [{"attributes": attrs, "indices": faces, "material": 0}]}],
        "skins": [{"name": "MixamoBody", "joints": list(range(len(names))), "skeleton": 0, "inverseBindMatrices": inverse}],
        "materials": [material], "textures": copy.deepcopy(original["textures"]),
        "images": images, "samplers": copy.deepcopy(original.get("samplers", [])),
        "animations": [{"name": "bind_pose", "samplers": [{"input": times, "output": roots}],
                        "channels": [{"sampler": 0, "target": {"node": 0, "path": "translation"}}]}],
        "buffers": [{"byteLength": len(binary)}], "bufferViews": views, "accessors": accessors,
    }
    metadata = json.dumps(document, separators=(",", ":")).encode()
    metadata += b" " * (-len(metadata) % 4)
    binary.extend(b"\0" * (-len(binary) % 4))
    result = struct.pack("<4sII", b"glTF", 2, 28 + len(metadata) + len(binary))
    result += struct.pack("<II", len(metadata), 0x4E4F534A) + metadata
    result += struct.pack("<II", len(binary), 0x004E4942) + binary
    path = ASSETS / f"base_basic_{variant}_rigged.glb"
    path.write_bytes(result)
    return {"path": path.relative_to(ROOT).as_posix(), "sha256": hashlib.sha256(result).hexdigest(),
            "size_bytes": len(result), "vertices": len(positions), "triangles": len(indices) // 3,
            "joints": len(names), "texture_max_size": size}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--gltfpack", default="gltfpack")
    parser.add_argument("--texture-size", type=int, default=1024)
    parser.add_argument("--pbr-source", type=Path, required=True,
                        help="Path to the original base_basic_pbr.glb supplied by the user")
    parser.add_argument("--shaded-source", type=Path, required=True,
                        help="Path to the original base_basic_shaded.glb supplied by the user")
    args = parser.parse_args()
    if not 256 <= args.texture_size <= 2048:
        parser.error("texture size must be between 256 and 2048")
    version = subprocess.run([args.gltfpack, "-v"], check=True, capture_output=True, text=True)
    if (version.stdout + version.stderr).strip() != "gltfpack 1.3":
        raise ValueError("This pipeline is pinned to gltfpack 1.3")
    source_paths = {"pbr": args.pbr_source, "shaded": args.shaded_source}
    originals = {variant: GLB(source_paths[variant]) for variant in VARIANTS}
    rig_source = GLB(ROOT / "assets/characters/rigged.glb")
    registry_path = ROOT / "assets/asset_registry.json"
    registry = json.loads(registry_path.read_text())
    registered = {entry["path"]: entry for entry in registry["assets"]}

    source_manifest = json.loads((ASSETS / "source_manifest.json").read_text())
    expected_hashes = source_manifest["source_sha256"]
    for variant, glb in originals.items():
        digest = hashlib.sha256(glb.raw).hexdigest()
        if digest != expected_hashes[variant]:
            raise ValueError("Source model hash mismatch; use the original supplied file: " + str(source_paths[variant]))
    body = json.loads((ROOT / "assets/animations/combat_manifest.json").read_text())
    assert hashlib.sha256(rig_source.raw).hexdigest() == body["target_sha256"]
    # Both variants must describe the same geometry/UV layout before sharing skin.
    for attribute in ("POSITION", "NORMAL", "TEXCOORD_0"):
        arrays = [g.accessor(g.data["meshes"][0]["primitives"][0]["attributes"][attribute]) for g in originals.values()]
        assert np.array_equal(*arrays), "Material variants have different geometry: " + attribute
    rig = combat_bind(rig_source)
    with tempfile.TemporaryDirectory() as tmp:
        simplified = Path(tmp) / "simplified.glb"
        subprocess.run([args.gltfpack, "-i", str(args.shaded_source),
                        "-o", str(simplified), "-si", "0.04", "-se", "0.008", "-sp", "-sv", "-noq"], check=True)
        source = GLB(simplified)
    primitive = source.data["meshes"][0]["primitives"][0]
    attributes = primitive["attributes"]
    orientation = np.array([-1, 1, -1])
    positions = source.accessor(attributes["POSITION"]).astype(float) * 100 * orientation
    normals = source.accessor(attributes["NORMAL"]).astype(float) * orientation
    uv = source.accessor(attributes["TEXCOORD_0"])
    indices = source.accessor(primitive["indices"]).reshape(-1)
    names, index, parents, target = rig
    source_bind = fit_source_bind(names, index, parents, target)
    joints, weights = skin_weights(positions, names, index)
    positions, normals = repose(positions, normals, joints, weights, source_bind, target)
    assert np.isfinite(positions).all() and len(indices) // 3 <= 60000
    mesh = positions, normals, uv, indices, joints, weights
    outputs = [export(variant, mesh, rig, originals[variant], args.texture_size) for variant in originals]
    profile = {"schema": 1, "source_sha256": {variant: hashlib.sha256(glb.raw).hexdigest() for variant, glb in originals.items()},
               "rig_source_sha256": hashlib.sha256(rig_source.raw).hexdigest(),
               "source_landmarks_cm": LANDMARKS, "outputs": outputs,
               "weighting": "Adjacent segment blends; rigid head and closed fists. Offline fitted bind pose.",
               "combat_library": "res://assets/animations/combat_mixamo.tres", "combat_clips": 27}
    (ASSETS / "rig_profile.json").write_text(json.dumps(profile, ensure_ascii=False, indent=2) + "\n")
    for output in outputs:
        path = ROOT / output["path"]
        glb = GLB(path)
        entry = {
            "path": output["path"], "status": "DEVELOPMENT_ONLY",
            "author": "Modelo fornecido pelo usuário / rig e preparação pelo projeto",
            "source": "GLB base_basic original fornecido externamente; skeleton corporal de assets/characters/rigged.glb",
            "license": "Origem do modelo e skeleton não comprovada; animações CC0 do Quaternius registradas separadamente",
            "modifications": f"Malha reduzida offline a {output['triangles']} triângulos, texturas {args.texture_size}, ajuste de pose, 65 bones Mixamo e pesos de skin. Originais mantidos fora do Git para reduzir o download.",
            "sha256": output["sha256"],
            "embedded_images": [{"path": path.with_name(path.stem + "_" + image["name"] + ".png").relative_to(ROOT).as_posix(),
                                 "sha256": hashlib.sha256(glb.image(image)).hexdigest()} for image in glb.data["images"]],
        }
        if output["path"] in registered:
            registered[output["path"]].update(entry)
        else:
            registry["assets"].append(entry)
    registry_path.write_text(json.dumps(registry, ensure_ascii=False, indent=2) + "\n")
    print(json.dumps(outputs, indent=2))


if __name__ == "__main__":
    main()
