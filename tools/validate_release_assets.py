#!/usr/bin/env python3
"""Fail closed on unregistered/changed runtime assets; dev may use unknown files."""
import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STATUSES = {'SAFE_FOR_RELEASE', 'NEEDS_ATTRIBUTION', 'DEVELOPMENT_ONLY', 'UNKNOWN_LICENSE'}
EXTENSIONS = {'.glb', '.gltf', '.fbx', '.tres', '.png', '.jpg', '.webp', '.ogg', '.wav', '.mp3', '.gdshader'}


def validate(root=ROOT, release=False):
    registry = json.loads((root / 'assets/asset_registry.json').read_text())
    errors, blocked = [], []
    registered = set()
    for entry in registry['assets']:
        relative = entry['path']
        path = root / relative
        if relative in registered or not path.is_relative_to(root) or '..' in Path(relative).parts:
            errors.append(f'invalid or duplicate path: {relative}')
            continue
        registered.add(relative)
        for image in entry.get('embedded_images', []):
            registered.add(image['path'])
            extracted = root / image['path']
            if extracted.exists() and hashlib.sha256(extracted.read_bytes()).hexdigest() != image['sha256']:
                errors.append(f'changed embedded image: {image["path"]}')
        if entry.get('status') not in STATUSES or not path.is_file():
            errors.append(f'invalid status or missing file: {relative}')
            continue
        if hashlib.sha256(path.read_bytes()).hexdigest() != entry.get('sha256'):
            errors.append(f'changed asset must be reviewed: {relative}')
        if entry['status'] in {'DEVELOPMENT_ONLY', 'UNKNOWN_LICENSE'}:
            blocked.append(relative)
        elif not all(entry.get(field) for field in ('author', 'source', 'license', 'modifications')):
            errors.append(f'missing license provenance: {relative}')
        if entry['status'] == 'NEEDS_ATTRIBUTION' and not entry.get('credit'):
            errors.append(f'missing required attribution: {relative}')
    for path in (root / 'assets').rglob('*'):
        if not path.is_file() or path.suffix.lower() not in EXTENSIONS:
            continue
        if any((parent / '.gdignore').exists() for parent in path.parents if parent.is_relative_to(root / 'assets')):
            continue
        relative = path.relative_to(root).as_posix()
        if relative not in registered:
            errors.append(f'unregistered runtime asset: {relative}')
    if release:
        errors += [f'not cleared for release: {path}' for path in blocked]
        if not registry.get('presentation_distribution_authorized', False):
            errors.append('public character/brand presentation authorization is not recorded')
    return errors, blocked


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--release', action='store_true')
    args = parser.parse_args()
    failures, blocked_assets = validate(release=args.release)
    for failure in failures:
        print(f'ASSET ERROR: {failure}')
    if blocked_assets and not args.release:
        print('Development only until provenance resolved: ' + ', '.join(blocked_assets))
    print('ASSET REGISTRY: ' + ('FAIL' if failures else 'PASS'))
    raise SystemExit(bool(failures))
