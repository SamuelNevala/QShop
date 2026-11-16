"""Check actual resolved Android runtime artifacts against their bundled notices."""

import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import tempfile
import zipfile


ROOT = Path(__file__).resolve().parents[1]


def validate(inventory, manifest, notice, ndk):
    actual = {entry['coordinate']: entry for entry in inventory['modules']}
    documented = {entry['coordinate']: entry for entry in manifest['components']}
    assert actual.keys() == documented.keys(), (
        'Runtime dependency notices are stale', sorted(actual.keys() - documented.keys()),
        sorted(documented.keys() - actual.keys()))
    for coordinate, entry in actual.items():
        digest = hashlib.sha256(Path(entry['file']).read_bytes()).hexdigest()
        assert digest == documented[coordinate]['artifact_sha256'], ('Changed runtime artifact', coordinate)
    assert hashlib.sha256(notice).hexdigest() == manifest['notice_sha256'], 'Changed offline runtime notice'
    upstream = ndk / 'toolchains/llvm/prebuilt/windows-x86_64/NOTICE'
    assert hashlib.sha256(upstream.read_bytes()).hexdigest() == manifest['ndk_notice_sha256'], 'Changed NDK notices'
    assert ('Pkg.Revision = ' + manifest['ndk_version']) in (ndk / 'source.properties').read_text()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--inventory', type=Path, required=True)
    parser.add_argument('--ndk', type=Path, required=True)
    parser.add_argument('--artifact', type=Path, required=True)
    parser.add_argument('--abi', choices=('arm64-v8a', 'x86_64'), required=True)
    args = parser.parse_args()
    manifest = json.loads((ROOT / 'app/licenses/android-runtime.json').read_text())
    validate(json.loads(args.inventory.read_text()), manifest,
             (ROOT / 'app/licenses/AndroidRuntime.txt').read_bytes(), args.ndk)
    readelf = args.ndk / 'toolchains/llvm/prebuilt/windows-x86_64/bin/llvm-readelf.exe'
    triple = {'arm64-v8a': 'aarch64-linux-android', 'x86_64': 'x86_64-linux-android'}[args.abi]
    original = args.ndk / 'toolchains/llvm/prebuilt/windows-x86_64/sysroot/usr/lib' / triple / 'libc++_shared.so'
    def build_id(path):
        text = subprocess.check_output([str(readelf), '-n', str(path)], text=True)
        return re.search(r'Build ID: (\w+)', text).group(1)
    with tempfile.TemporaryDirectory(prefix='qshopper-license-') as temporary:
        with zipfile.ZipFile(args.artifact) as package:
            prefix = 'base/' if args.artifact.suffix == '.aab' else ''
            runtime = Path(temporary) / 'libc++_shared.so'
            runtime.write_bytes(package.read(prefix + 'lib/' + args.abi + '/libc++_shared.so'))
        assert build_id(original) == build_id(runtime), 'Packaged C++ runtime differs from the documented NDK'
    print('PASS', len(manifest['components']), 'actual Maven artifacts, offline notices and packaged NDK runtime')


if __name__ == '__main__':
    main()
