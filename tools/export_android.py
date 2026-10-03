#!/usr/bin/env python3
"""Supported Android export entry point; release is gated before starting Godot."""
import argparse
import subprocess
from pathlib import Path
from validate_release_assets import ROOT, validate

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--godot', required=True)
parser.add_argument('--release', action='store_true')
parser.add_argument('--output', required=True)
args = parser.parse_args()
errors, _ = validate(release=args.release)
if errors:
    raise SystemExit('\n'.join(errors))
output = Path(args.output).resolve()
output.parent.mkdir(parents=True, exist_ok=True)
raise SystemExit(subprocess.call([args.godot, '--headless', '--path', str(ROOT), '--export-release' if args.release else '--export-debug', 'Android (Play Store)' if args.release else 'Android', str(output)]))
