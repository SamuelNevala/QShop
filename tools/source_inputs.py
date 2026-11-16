"""Bind a verified Android artifact to the tracked source inputs used to build it."""

import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess


ROOT = Path(__file__).resolve().parents[1]


def tracked_files(root):
    entries = subprocess.check_output(['git', '-C', str(root), 'ls-files', '--stage', '-z']).decode().split('\0')
    files = []
    for entry in filter(None, entries):
        metadata, name = entry.split('\t', 1)
        mode = metadata.split()[0]
        path = Path(name)
        assert not path.is_absolute() and '..' not in path.parts
        assert mode in ('100644', '100755'), ('Review non-regular source entry', name)
        assert not any(part.lower() in ('.git', '.ssh', '.aws', '.codex', 'out', 'dist') for part in path.parts)
        assert not re.search(r'(?i)(\.(keystore|jks|p12|pfx|sqlite|sqlite3)$|(^|/)(\.env(?:\..*)?|id_rsa|id_ed25519.*)$)', name), (
            'Sensitive tracked filename refused', name)
        assert not (root / name).is_symlink(), ('Source symlink refused', name)
        assert (root / name).resolve().is_relative_to(root.resolve()), ('Source leaves the checkout', name)
        files.append((name, int(mode[-3:], 8)))
    return sorted(files)


def input_hashes(root):
    inputs = {}
    for name, _ in tracked_files(root):
        if name.startswith(('app/', 'android/')) or name in (
                'CMakeLists.txt', 'CMakePresets.json', 'COPYRIGHT', 'LICENSE', 'build-android.ps1'):
            inputs[name] = hashlib.sha256((root / name).read_bytes()).hexdigest()
    assert 'CMakeLists.txt' in inputs and any(name.startswith('app/') for name in inputs)
    return inputs


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument('--write', type=Path)
    mode.add_argument('--check', type=Path)
    parser.add_argument('--artifact', type=Path)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    inputs = input_hashes(ROOT)
    if args.write:
        args.write.parent.mkdir(parents=True, exist_ok=True)
        args.write.write_text(json.dumps({'inputs': inputs}, indent=2) + '\n')
    else:
        assert inputs == json.loads(args.check.read_text())['inputs'], 'Source inputs changed during the build'
        assert args.artifact and args.output
        record = {'inputs': inputs, 'artifact': args.artifact.name,
                  'artifact_sha256': hashlib.sha256(args.artifact.read_bytes()).hexdigest()}
        args.output.write_text(json.dumps(record, indent=2) + '\n')
    print('PASS', len(inputs), 'tracked Android source inputs')


if __name__ == '__main__':
    main()
