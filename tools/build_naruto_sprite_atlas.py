#!/usr/bin/env python3
"""Rebuild the committed Naruto atlas from the user-supplied ZIP (requires Pillow)."""
import argparse
import hashlib
import io
import json
from pathlib import Path
import zipfile
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / 'assets/characters/sprites/naruto_part1'


def build(archive: Path) -> None:
    manifest_path = ASSETS / 'source_manifest.json'
    manifest = json.loads(manifest_path.read_text())
    cell_w, cell_h = manifest['cell_size']
    columns = manifest['columns']
    frames = manifest['frames']
    rows = (len(frames) + columns - 1) // columns
    atlas = Image.new('RGBA', (columns * cell_w, rows * cell_h))
    baseline = cell_h - 8
    with zipfile.ZipFile(archive) as source:
        for key, frame in frames.items():
            raw = source.read('Naruto Uzumaki - Part 1 (Battle)/' + frame['source'])
            image = Image.open(io.BytesIO(raw)).convert('RGBA')
            bounds = image.getbbox()
            if not bounds:
                raise ValueError(f'Empty sprite: {key}')
            image = image.crop(bounds)
            # Wide dash trails must fit the cell too; never crop their edges.
            image.thumbnail((cell_w - 16, baseline - 8), Image.Resampling.NEAREST)
            x = (cell_w - image.width) // 2
            y = baseline - image.height
            index = frame['index']
            atlas.alpha_composite(image, (index % columns * cell_w + x, index // columns * cell_h + y))
            frame['source_sha256'] = hashlib.sha256(raw).hexdigest()
            frame['bounds'] = [x, y, image.width, image.height]
    output = ASSETS / 'battle_atlas.png'
    atlas.save(output, optimize=True)
    with Image.open(output) as check:
        check.verify()
    manifest['baseline'] = baseline
    manifest['atlas_sha256'] = hashlib.sha256(output.read_bytes()).hexdigest()
    manifest['note'] = '16 complete battle poses in 192x192 cells, at original pixel scale with a shared foot baseline. Rebuild with tools/build_naruto_sprite_atlas.py. Public redistribution rights are not established.'
    manifest_path.write_text(json.dumps(manifest, indent=2) + '\n')
    print(f'Built and verified {output.name}: {atlas.size}, {len(frames)} complete poses')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('archive', type=Path)
    build(parser.parse_args().archive)
