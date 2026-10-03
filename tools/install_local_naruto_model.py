#!/usr/bin/env python3
"""Install a user-supplied GLB as a local-only development character asset.

The destination is ignored by Git so licensed/downloaded assets are not
redistributed as standalone files from this public repository.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "external" / "character_assets" / "naruto_sketchfab.glb"


def read_glb_metadata(path: Path) -> dict:
    data = path.read_bytes()
    if len(data) < 20:
        raise ValueError("arquivo curto demais para GLB")
    magic, version, total = struct.unpack_from("<4sII", data, 0)
    if magic != b"glTF" or version != 2 or total != len(data):
        raise ValueError("GLB 2.0 inválido")
    offset = 12
    gltf = None
    while offset + 8 <= len(data):
        length, chunk_type = struct.unpack_from("<II", data, offset)
        offset += 8
        chunk = data[offset:offset + length]
        offset += length
        if chunk_type == 0x4E4F534A:
            gltf = json.loads(chunk.decode("utf-8").rstrip("\x00 "))
    if not isinstance(gltf, dict):
        raise ValueError("chunk JSON do GLB não encontrado")
    asset = gltf.get("asset", {})
    extras = asset.get("extras", {}) if isinstance(asset, dict) else {}
    return {
        "sha256": hashlib.sha256(data).hexdigest(),
        "size_bytes": len(data),
        "nodes": len(gltf.get("nodes", [])),
        "meshes": len(gltf.get("meshes", [])),
        "skins": len(gltf.get("skins", [])),
        "animations": len(gltf.get("animations", [])),
        "materials": len(gltf.get("materials", [])),
        "images": len(gltf.get("images", [])),
        "author": extras.get("author", ""),
        "license": extras.get("license", ""),
        "source": extras.get("source", ""),
        "title": extras.get("title", ""),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("glb", type=Path)
    args = parser.parse_args()

    if not args.glb.is_file():
        raise ValueError(f"arquivo não encontrado: {args.glb}")

    info = read_glb_metadata(args.glb)
    DEST.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(args.glb, DEST)

    print(json.dumps(info, ensure_ascii=False, indent=2))
    print(f"Instalado localmente em: {DEST}")
    if info["skins"] == 0:
        print("AVISO: este GLB não possui skin/skeleton; será usado apenas como preview estático até ser rigado.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
