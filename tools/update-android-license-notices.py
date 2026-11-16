"""Generate Android runtime notices from actual Gradle artifacts and the NDK.

Developer-only network tool. Ordinary builds use the checked-in outputs.
The full resolved runtime graph is retained conservatively even if R8 removes
some classes. Build-only Gradle/AGP/compiler dependencies are not Maven seeds.
"""

import argparse
import hashlib
from io import BytesIO
import json
from pathlib import Path
import re
from urllib.request import Request, urlopen
import uuid
import xml.etree.ElementTree as ET
import zipfile


ROOT = Path(__file__).resolve().parents[1]
CACHE = ROOT / 'out/rel001/licensing/upstream'
MAVEN_NS = {'m': 'http://maven.apache.org/POM/4.0.0'}
LEGAL_NAMES = {'LICENSE', 'LICENSE.TXT', 'NOTICE', 'NOTICE.TXT', 'COPYING'}


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def fetch(url):
    path = CACHE / sha256(url.encode())
    if not path.exists():
        path.parent.mkdir(parents=True, exist_ok=True)
        temporary = path.with_suffix('.' + uuid.uuid4().hex)
        temporary.write_bytes(urlopen(Request(url, headers={'User-Agent': 'QShopper-license-audit'}),
                                      timeout=45).read())
        temporary.replace(path)
    return path.read_bytes()


def artifact_url(coordinate, suffix):
    group, name, version = coordinate.split(':')
    repository = ('https://dl.google.com/dl/android/maven2/' if group.startswith('androidx.')
                  else 'https://repo.maven.apache.org/maven2/')
    return repository + group.replace('.', '/') + '/' + name + '/' + version + '/' + name + '-' + version + suffix


def pom_licenses(coordinate, records):
    url = artifact_url(coordinate, '.pom')
    raw = fetch(url)
    records[url] = sha256(raw)
    pom = ET.fromstring(raw)
    licenses = [entry.findtext('m:name', namespaces=MAVEN_NS)
                for entry in pom.findall('m:licenses/m:license', MAVEN_NS)]
    parent = pom.find('m:parent', MAVEN_NS)
    if not licenses and parent is not None:
        coordinate = ':'.join(parent.findtext('m:' + name, namespaces=MAVEN_NS)
                              for name in ('groupId', 'artifactId', 'version'))
        licenses = pom_licenses(coordinate, records)
    assert licenses and all('Apache' in name and '2.0' in name for name in licenses), (
        'Review new or missing license before generating notices', coordinate, licenses)
    return licenses


def legal_entries(data):
    notices = {}
    with zipfile.ZipFile(BytesIO(data)) as archive:
        for name in archive.namelist():
            if Path(name).name.upper() in LEGAL_NAMES:
                notices[name] = archive.read(name).decode('utf-8-sig').replace('\r\n', '\n')
        if 'classes.jar' in archive.namelist():
            notices.update({'classes.jar/' + name: text
                            for name, text in legal_entries(archive.read('classes.jar')).items()})
    return notices


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--inventory', type=Path, required=True)
    parser.add_argument('--ndk', type=Path, required=True)
    parser.add_argument('--output', type=Path, default=ROOT / 'app/licenses')
    args = parser.parse_args()
    inventory = json.loads(args.inventory.read_text())
    assert inventory['modules'], 'No Maven runtime artifacts were resolved'
    source_records, components, sections = {}, [], []
    for artifact in inventory['modules']:
        coordinate = artifact['coordinate']
        print('Reading', coordinate, flush=True)
        licenses = pom_licenses(coordinate, source_records)
        source_url = artifact_url(coordinate, '-sources.jar')
        source = fetch(source_url)
        source_records[source_url] = sha256(source)
        binary = Path(artifact['file']).read_bytes()
        notices = {'artifact/' + name: text for name, text in legal_entries(binary).items()}
        notices.update({'sources/' + name: text for name, text in legal_entries(source).items()})
        if coordinate.startswith('org.jetbrains.kotlinx:kotlinx-coroutines-'):
            # These published source JARs omit the repository's attribution.
            version = coordinate.rsplit(':', 1)[1]
            legal_url = 'https://raw.githubusercontent.com/Kotlin/kotlinx.coroutines/' + version + '/LICENSE.txt'
            legal = fetch(legal_url)
            source_records[legal_url] = sha256(legal)
            notices[legal_url] = legal.decode('utf-8').replace('\r\n', '\n')
        copyrights = set()
        with zipfile.ZipFile(BytesIO(source)) as archive:
            for name in archive.namelist():
                if name.endswith(('.java', '.kt')):
                    lines = archive.read(name).decode('utf-8-sig').splitlines()[:60]
                    copyrights.update(line.strip(' /*#\t') for line in lines
                                      if re.search(r'\bCopyright\b', line, re.I))
        assert copyrights or notices, ('No attribution evidence in published source', coordinate)
        sections.extend([coordinate, 'License: Apache-2.0', 'Published sources: ' + source_url,
                         '\n'.join(sorted(copyrights))])
        for name, text in sorted(notices.items()):
            sections.extend(['Upstream notice: ' + name, text])
        components.append({'coordinate': coordinate, 'licenses': licenses,
                           'artifact_sha256': sha256(binary), 'source_url': source_url,
                           'source_sha256': sha256(source), 'copyrights': sorted(copyrights),
                           'notice_hashes': {name: sha256(text.encode()) for name, text in notices.items()}})
    apache_url = 'https://www.apache.org/licenses/LICENSE-2.0.txt'
    apache = fetch(apache_url)
    source_records[apache_url] = sha256(apache)
    ndk_version = dict(line.split('=', 1) for line in (args.ndk / 'source.properties').read_text().splitlines()
                       if '=' in line)['Pkg.Revision '].strip()
    ndk_notice_path = args.ndk / 'toolchains/llvm/prebuilt/windows-x86_64/NOTICE'
    ndk_notice = ndk_notice_path.read_bytes()
    text = ('ANDROID RUNTIME DEPENDENCIES\n\n'
            'The following resolved runtime components accompany Qt on Android.\n'
            'Their full dependency set is listed conservatively; optimization may remove some classes.\n'
            'Qt bridge JAR sources and notices are covered by the Qt source inventory.\n\n'
            + '\n\n'.join(sections)
            + '\n\nCOMPLETE APACHE LICENSE 2.0\n\n' + apache.decode().replace('\r\n', '\n')
            + '\n\nANDROID NDK C++ RUNTIME\n\n'
            + 'libc++_shared.so from Android NDK ' + ndk_version + '.\n'
            'The complete upstream LLVM toolchain NOTICE is retained conservatively below.\n'
            'QShopper ships the C++ runtime, not the compiler or all tools described by this notice.\n\n'
            + ndk_notice.decode().replace('\r\n', '\n')
            + '\n\nEND OF ANDROID RUNTIME NOTICES\n')
    args.output.mkdir(parents=True, exist_ok=True)
    output = args.output / 'AndroidRuntime.txt'
    output.write_text(text, encoding='utf-8', newline='\n')
    manifest = {'scope': 'Conservative resolved Release runtime graph; independent of R8 class removal',
                'components': components, 'sources': dict(sorted(source_records.items())),
                'ndk_version': ndk_version, 'ndk_notice_sha256': sha256(ndk_notice),
                'notice_sha256': sha256(output.read_bytes())}
    (args.output / 'android-runtime.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    print('Generated', len(components), 'Maven component notices and NDK runtime notices')


if __name__ == '__main__':
    main()
