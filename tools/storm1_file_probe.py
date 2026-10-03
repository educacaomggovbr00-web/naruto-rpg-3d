#!/usr/bin/env python3
"""
Inventory user-supplied Naruto Ultimate Ninja Storm research files without
copying them into the repository.

The scanner is intentionally conservative: it records path, size, SHA-256,
extension, a few known CyberConnect2 signatures and a suggested research role.
It never extracts, decodes or rewrites proprietary payloads.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Any

SCHEMA_VERSION = 1

KNOWN_EXTENSIONS = {
    ".xfbin": "CyberConnect2 XFBIN container",
    ".binary": "nuccChunkBinary payload",
    ".cpk": "CRI CPK archive",
    ".nud": "CyberConnect2 model container/chunk",
    ".nut": "CyberConnect2 texture container/chunk",
    ".anm": "animation-related file",
    ".json": "metadata / extracted research JSON",
}

MAGIC_HINTS = {
    b"NDP3": "NDP3 mesh/model payload",
    b"NTP3": "NTP3 texture payload",
    b"CPK ": "CRI CPK archive",
    b"CRID": "CRI container/media signature",
}


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def inspect_magic(path: Path, max_bytes: int = 1024 * 1024) -> list[str]:
    with path.open("rb") as handle:
        sample = handle.read(max_bytes)
    found = []
    for magic, description in MAGIC_HINTS.items():
        if magic in sample:
            found.append(description)
    return found


def suggested_role(path: Path, extension: str, magic: list[str]) -> str:
    name = path.name.lower()
    if "commandchartdata" in name:
        return "command_chart"
    if "message" in name or "itemtext" in name or extension == ".binary":
        return "text_or_binary_chunk"
    if extension == ".xfbin":
        return "xfbin_container"
    if extension in {".nud"} or any("mesh/model" in item for item in magic):
        return "model_research"
    if extension in {".nut"} or any("texture" in item for item in magic):
        return "texture_research"
    if extension == ".anm":
        return "animation_research"
    if extension == ".cpk" or any("CPK" in item for item in magic):
        return "archive_research"
    return "unknown"


def inventory(root: Path) -> dict[str, Any]:
    files = []
    totals: dict[str, int] = {}

    for path in sorted(p for p in root.rglob("*") if p.is_file()):
        extension = path.suffix.lower()
        magic = inspect_magic(path)
        role = suggested_role(path, extension, magic)
        totals[role] = totals.get(role, 0) + 1
        files.append({
            "path": path.relative_to(root).as_posix(),
            "size_bytes": path.stat().st_size,
            "sha256": sha256_file(path),
            "extension": extension,
            "format_hint": KNOWN_EXTENSIONS.get(extension, "unknown"),
            "magic_hints": magic,
            "suggested_role": role,
        })

    return {
        "schema_version": SCHEMA_VERSION,
        "root_name": root.name,
        "file_count": len(files),
        "totals_by_role": totals,
        "files": files,
        "notes": [
            "Inventory contains metadata only; source files remain outside Git.",
            "Signatures are hints, not proof of semantic meaning.",
            "Use NUNSMOD/xfbin tooling locally only on files the user supplies.",
        ],
    }


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Build a metadata-only inventory of user-supplied Storm research files."
    )
    parser.add_argument("input_dir", type=Path)
    parser.add_argument(
        "output_json",
        type=Path,
        nargs="?",
        default=Path("build/research/storm1_file_inventory.json"),
    )
    args = parser.parse_args()

    if not args.input_dir.is_dir():
        raise ValueError(f"not a directory: {args.input_dir}")

    result = inventory(args.input_dir)
    args.output_json.parent.mkdir(parents=True, exist_ok=True)
    with args.output_json.open("w", encoding="utf-8") as handle:
        json.dump(result, handle, ensure_ascii=False, indent=2)
        handle.write("\n")

    print(f"Inventoried {result['file_count']} files")
    for role, count in sorted(result["totals_by_role"].items()):
        print(f"  {role}: {count}")
    print(f"Wrote: {args.output_json}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
