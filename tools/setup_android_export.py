#!/usr/bin/env python3
"""Configure local Godot Android debug export; no machine paths enter the repo."""
import argparse
import os
from pathlib import Path
import re
import subprocess
import zipfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', required=True)
    parser.add_argument('--sdk', type=Path, required=True)
    parser.add_argument('--java', type=Path, required=True)
    parser.add_argument('--templates', type=Path, required=True, help='Official matching export_templates.tpz')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    version = subprocess.check_output([args.godot, '--version'], text=True).strip()
    template_version = '.'.join(version.split('.')[:4])
    settings_version = '.'.join(version.split('.')[:2])
    if not (args.sdk / 'platform-tools/adb').is_file() or not (args.sdk / 'build-tools/35.0.0/apksigner').is_file():
        raise SystemExit('Install Android platform-tools, build-tools;35.0.0 and platforms;android-35 first.')
    if not (args.sdk / 'platforms/android-35/android.jar').is_file() or not (args.java / 'bin/keytool').is_file():
        raise SystemExit('Android platform 35 and a JDK with keytool are required.')
    data_dir = Path(os.environ.get('XDG_DATA_HOME', Path.home() / '.local/share')) / 'godot'
    config_dir = Path(os.environ.get('XDG_CONFIG_HOME', Path.home() / '.config')) / 'godot'
    templates_dir = data_dir / 'export_templates' / template_version
    with zipfile.ZipFile(args.templates) as archive:
        if archive.read('templates/version.txt').decode().strip() != template_version:
            raise SystemExit('Export templates must match the Godot executable exactly.')
        templates_dir.mkdir(parents=True, exist_ok=True)
        for name in ['android_debug.apk', 'android_release.apk', 'version.txt']:
            (templates_dir / name).write_bytes(archive.read('templates/' + name))
    keystore = data_dir / 'keystores/debug.keystore'
    if not keystore.exists():
        keystore.parent.mkdir(parents=True, exist_ok=True)
        # Standard development-only key; never use for a public release.
        subprocess.run([str(args.java / 'bin/keytool'), '-genkeypair', '-keystore', str(keystore),
                        '-storepass', 'android', '-keypass', 'android', '-alias', 'androiddebugkey',
                        '-dname', 'CN=Android Debug,O=Android,C=US', '-keyalg', 'RSA',
                        '-keysize', '2048', '-validity', '10000', '-storetype', 'JKS'], check=True)
    settings = config_dir / f'editor_settings-{settings_version}.tres'
    if not settings.exists():
        subprocess.run([args.godot, '--headless', '--path', str(root), '--editor', '--quit'], check=True)
    text = settings.read_text()
    values = {'export/android/android_sdk_path': args.sdk.resolve().as_posix(),
              'export/android/java_sdk_path': args.java.resolve().as_posix(),
              'export/android/debug_keystore': keystore.as_posix(),
              'export/android/debug_keystore_user': 'androiddebugkey',
              'export/android/debug_keystore_pass': 'android'}
    for key, value in values.items():
        line = f'{key} = "{value}"'
        text, count = re.subn(r'^' + re.escape(key) + r' = .*$', lambda _: line, text, flags=re.M)
        if not count:
            text += '\n' + line + '\n'
    settings.write_text(text)
    print(f'Android debug export configured for Godot {template_version}.')


if __name__ == '__main__':
    main()
