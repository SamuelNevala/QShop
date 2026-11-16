"""Exercise source archives and source/build binding with disposable Git data."""

import hashlib
import importlib.util
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tarfile
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from source_inputs import tracked_files

spec = importlib.util.spec_from_file_location('source_set', ROOT / 'tools/create-source-set.py')
source_set = importlib.util.module_from_spec(spec)
spec.loader.exec_module(source_set)


class SourceDeliveryTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='qshopper-source-test-')
        self.root = Path(self.temporary.name)
        self.git('init', '-q')
        (self.root / 'app').mkdir()
        (self.root / 'tools').mkdir()
        (self.root / '.gitignore').write_text('out/\n.env\n')
        (self.root / 'CMakeLists.txt').write_text('project(QShopper VERSION 0.1.0)\n')
        (self.root / 'app/main.cpp').write_text('int main() { return 0; }\n')
        shutil.copyfile(ROOT / 'tools/source_inputs.py', self.root / 'tools/source_inputs.py')
        self.git('add', '.')

    def tearDown(self):
        self.temporary.cleanup()

    def git(self, *arguments):
        return subprocess.check_output(['git', '-C', str(self.root), *arguments], stderr=subprocess.STDOUT)

    def stamp(self, *arguments):
        return subprocess.run([sys.executable, str(self.root / 'tools/source_inputs.py'), *map(str, arguments)],
                              capture_output=True, text=True)

    def test_archive_has_all_tracked_source_without_private_untracked_data(self):
        (self.root / '.env').write_text('private-test-value')
        (self.root / 'out').mkdir()
        (self.root / 'out/private.sqlite').write_bytes(b'not app source')
        output = self.root / 'out/source.tar.xz'
        hashes = source_set.project_archive(self.root, output)
        with tarfile.open(output) as archive:
            names = archive.getnames()
            self.assertEqual(set(names), {'QShopper/' + name for name, _ in tracked_files(self.root)})
            self.assertEqual(archive.extractfile('QShopper/app/main.cpp').read(),
                             (self.root / 'app/main.cpp').read_bytes())
        self.assertNotIn('QShopper/.env', names)
        self.assertNotIn('QShopper/out/private.sqlite', names)
        self.assertEqual(hashes['app/main.cpp'], hashlib.sha256((self.root / 'app/main.cpp').read_bytes()).hexdigest())

    def test_source_changed_during_build_is_rejected(self):
        before = self.root / 'out/before.json'
        self.assertEqual(self.stamp('--write', before).returncode, 0)
        artifact = self.root / 'out/app.apk'
        artifact.write_bytes(b'test artifact')
        after = self.root / 'out/app.apk.source-inputs.json'
        self.assertEqual(self.stamp('--check', before, '--artifact', artifact, '--output', after).returncode, 0)
        self.assertEqual(json.loads(after.read_text())['artifact_sha256'], hashlib.sha256(artifact.read_bytes()).hexdigest())
        (self.root / 'app/main.cpp').write_text('int main() { return 1; }\n')
        result = self.stamp('--check', before, '--artifact', artifact, '--output', after)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Source inputs changed during the build', result.stderr)

    def test_tracked_private_key_is_refused(self):
        (self.root / 'debug.keystore').write_bytes(b'dummy private test value')
        self.git('add', 'debug.keystore')
        with self.assertRaisesRegex(AssertionError, 'Sensitive tracked filename'):
            tracked_files(self.root)

    def test_non_regular_index_entry_is_refused(self):
        blob = self.git('hash-object', '-w', 'app/main.cpp').decode().strip()
        self.git('update-index', '--add', '--cacheinfo', '120000,' + blob + ',app/link')
        with self.assertRaisesRegex(AssertionError, 'non-regular source entry'):
            tracked_files(self.root)


if __name__ == '__main__':
    unittest.main()
