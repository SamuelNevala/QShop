"""Prepare a local, hash-verified source set for a verified Android artifact.

Requires a completed build-android.ps1 -VerifyPackage source-input record.
Normal mode requires a clean checkout; --candidate explicitly labels local work.
This tool prepares files and does not publish a release or accept store terms.
"""

import argparse
import hashlib
from io import BytesIO
import json
from pathlib import Path
import re
import shutil
import subprocess
import tarfile
from urllib.request import Request, urlopen
import zipfile

from source_inputs import input_hashes, tracked_files


ROOT = Path(__file__).resolve().parents[1]
CACHE = ROOT / 'out/rel001/licensing/upstream'


def file_hash(path):
    with path.open('rb') as file:
        return hashlib.file_digest(file, 'sha256').hexdigest()


def fetch_file(url):
    CACHE.mkdir(parents=True, exist_ok=True)
    path = CACHE / hashlib.sha256(url.encode()).hexdigest()
    if not path.exists():
        temporary = path.with_suffix('.download')
        with urlopen(Request(url, headers={'User-Agent': 'QShopper-source-audit'}), timeout=90) as response:
            with temporary.open('wb') as target:
                shutil.copyfileobj(response, target)
        temporary.replace(path)
    return path


def project_archive(root, output):
    hashes = {}
    with tarfile.open(output, 'w:xz', preset=3) as archive:
        for name, mode in tracked_files(root):
            data = (root / name).read_bytes()
            hashes[name] = hashlib.sha256(data).hexdigest()
            entry = tarfile.TarInfo('QShopper/' + name)
            entry.size, entry.mode = len(data), mode
            entry.mtime = 0
            archive.addfile(entry, BytesIO(data))
    return hashes


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--artifact', type=Path, required=True)
    parser.add_argument('--package-report', type=Path, required=True)
    parser.add_argument('--qt-kit', type=Path, required=True)
    parser.add_argument('--ndk', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--candidate', action='store_true')
    args = parser.parse_args()
    dirty = bool(subprocess.check_output(['git', '-C', str(ROOT), 'status', '--porcelain']))
    assert args.candidate or not dirty, 'Commit accepted sources first, or explicitly prepare a --candidate'
    stamp = json.loads(Path(str(args.artifact) + '.source-inputs.json').read_text())
    assert stamp['artifact_sha256'] == file_hash(args.artifact), 'Artifact differs from its verified build record'
    assert stamp['inputs'] == input_hashes(ROOT), 'Source differs from the artifact build inputs; rebuild first'
    package = json.loads(args.package_report.read_text())
    cmake = (ROOT / 'CMakeLists.txt').read_text()
    code = int(re.search(r'set\(QSHOPPER_ANDROID_VERSION_CODE (\d+)\)', cmake).group(1))
    version = re.search(r'project\(QShopper VERSION ([0-9.]+)', cmake).group(1)
    assert package['version_code'] == code and package['version_name'] == version
    assert package['passed'] and not package['debuggable'], 'Use the verified Release package report'
    args.output.mkdir(parents=True, exist_ok=True)
    assert not list(args.output.iterdir()), 'Choose a new empty source-set directory'
    project = args.output / 'qshopper-source.tar.xz'
    project_files = project_archive(ROOT, project)
    assert stamp['inputs'] == {name: project_files[name] for name in stamp['inputs']}
    components, artifacts = [], []
    for module in ('qtbase', 'qtdeclarative', 'qtsvg'):
        candidates = list((args.qt_kit / 'sbom').glob(module + '-*.spdx.json'))
        assert len(candidates) == 1, ('Expected one installed Qt module SBOM', module)
        bom_path = candidates[0]
        bom = json.loads(bom_path.read_text())
        location = bom['packages'][0]['downloadLocation']
        commit = location.rsplit('@', 1)[1]
        assert re.fullmatch('[a-f0-9]{40}', commit), ('Qt source commit missing', module)
        url = 'https://codeload.github.com/qt/' + module + '/tar.gz/' + commit
        print('Obtaining complete Qt source:', module, commit, flush=True)
        source = fetch_file(url)
        target = args.output / (module + '-' + commit + '.tar.gz')
        shutil.copyfile(source, target)
        with tarfile.open(target, 'r:gz') as archive:
            names = set(archive.getnames())
            assert module + '-' + commit + '/CMakeLists.txt' in names, 'Unexpected Qt source archive'
            assert any('/LICENSES/' in name for name in names), 'Qt source license files missing'
        components.append({'module': module, 'version': bom_path.name[len(module) + 1:-len('.spdx.json')],
                           'revision': bom['packages'][0]['versionInfo'],
                           'commit': commit, 'upstream': url, 'archive': target.name,
                           'sbom': bom_path.name})
    runtime = json.loads((ROOT / 'app/licenses/android-runtime.json').read_text())
    runtime_zip = args.output / 'android-runtime-sources.zip'
    with zipfile.ZipFile(runtime_zip, 'w', compression=zipfile.ZIP_DEFLATED) as archive:
        for index, (url, digest) in enumerate(runtime['sources'].items()):
            source = fetch_file(url)
            assert file_hash(source) == digest, ('Changed upstream runtime source', url)
            archive.write(source, str(index).zfill(3) + '-' + url.rsplit('/', 1)[1])
        archive.writestr('sources.json', json.dumps(runtime, indent=2) + '\n')
        for name in ('source.properties', 'toolchains/llvm/prebuilt/windows-x86_64/NOTICE',
                     'toolchains/llvm/prebuilt/windows-x86_64/AndroidVersion.txt',
                     'toolchains/llvm/prebuilt/windows-x86_64/clang_source_info.md'):
            archive.write(args.ndk / name, 'ndk/' + Path(name).name)
        for module in ('qtbase', 'qtdeclarative', 'qtsvg'):
            for suffix in ('.opt', '.summary'):
                path = args.qt_kit / ('config_' + module + suffix)
                archive.write(path, 'qt-build/' + path.name)
            path = args.qt_kit / 'sbom' / next(entry['sbom'] for entry in components if entry['module'] == module)
            archive.write(path, 'qt-build/' + path.name)
        archive.write(args.qt_kit / 'mkspecs/qconfig.pri', 'qt-build/qconfig.pri')
    for path in sorted(args.output.iterdir()):
        artifacts.append({'name': path.name, 'bytes': path.stat().st_size, 'sha256': file_hash(path)})
    manifest = {'version': version, 'android_code': code, 'abi': package['abi'],
                'min_sdk': package['min_sdk'], 'target_sdk': package['target_sdk'],
                'ndk_version': runtime['ndk_version'],
                'candidate': args.candidate, 'published': False,
                'git_base': subprocess.check_output(['git', '-C', str(ROOT), 'rev-parse', 'HEAD']).decode().strip(),
                'dirty_snapshot': dirty, 'project_files': project_files, 'qt': components,
                'binary': {'name': args.artifact.name, 'sha256': file_hash(args.artifact)},
                'archives': artifacts,
                'source_delivery': 'Publish all listed archives and this manifest beside the binary download/source link; verify downloads before store release.'}
    (args.output / 'source-manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print('Prepared source set:', args.output, 'candidate=' + str(args.candidate))


if __name__ == '__main__':
    main()
