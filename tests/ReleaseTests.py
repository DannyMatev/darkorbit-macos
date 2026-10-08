"""Synthetic release-boundary checks; no local installation data is used."""
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
import audit_release
import package


class ReleaseTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='orbit-release-test-')
        self.root = Path(self.temporary.name)
        self.app = self.root / 'Example.app'
        for relative in audit_release.APP_FILES:
            file = self.app / relative
            file.parent.mkdir(parents=True, exist_ok=True)
            file.write_bytes(b'synthetic fixture')

    def tearDown(self):
        self.temporary.cleanup()

    def test_complete_bundle_and_archive(self):
        self.assertEqual(audit_release.audit_app(self.app), 4)
        members = [(p, str(p.relative_to(self.root)))
                   for p in sorted(self.app.rglob('*')) if p.is_file()]
        archive = self.root / 'candidate.zip'
        package.write_archive(archive, members)
        with zipfile.ZipFile(archive) as result:
            self.assertEqual(len(result.infolist()), 4)
            self.assertIsNone(result.testzip())

    def test_unlisted_file_is_rejected(self):
        (self.app / 'Contents' / 'Unexpected.txt').write_text('synthetic fixture')
        with self.assertRaises(ValueError):
            audit_release.audit_app(self.app)

    def test_missing_signature_file_is_rejected(self):
        (self.app / 'Contents/_CodeSignature/CodeResources').unlink()
        with self.assertRaises(ValueError):
            audit_release.audit_app(self.app)

    def test_links_are_rejected(self):
        file = self.app / 'Contents/Info.plist'
        file.unlink()
        file.symlink_to('Resources/AppIcon.icns')
        with self.assertRaises(ValueError):
            audit_release.audit_app(self.app)

    def test_parent_traversal_in_archive_is_rejected(self):
        file = self.app / 'Contents/Info.plist'
        with self.assertRaises(ValueError):
            package.write_archive(self.root / 'invalid.zip', [(file, '../outside')])

    def source_fixture(self):
        source = self.root / 'source'
        for relative in audit_release.APPROVED_FILES:
            file = source / relative
            file.parent.mkdir(parents=True, exist_ok=True)
            file.write_text('synthetic fixture\n')
        return source

    def test_exact_source_allowlist_is_accepted(self):
        source = self.source_fixture()
        with patch.object(audit_release, 'ROOT', source):
            self.assertEqual(len(audit_release.audit_source()), len(audit_release.APPROVED_FILES))

    def test_unreviewed_source_file_is_rejected(self):
        source = self.source_fixture()
        (source / 'docs/unreviewed-notes.md').write_text('synthetic fixture\n')
        with patch.object(audit_release, 'ROOT', source):
            with self.assertRaises(ValueError):
                audit_release.audit_source()

    def test_symlinked_top_level_directory_is_rejected(self):
        source = self.source_fixture()
        docs = source / 'docs'
        outside = self.root / 'synthetic-outside-docs'
        docs.rename(outside)
        docs.symlink_to(outside, target_is_directory=True)
        with patch.object(audit_release, 'ROOT', source):
            with self.assertRaises(ValueError):
                audit_release.audit_source()

    def test_symlinked_nested_ancestor_is_rejected(self):
        source = self.source_fixture()
        templates = source / '.github/ISSUE_TEMPLATE'
        outside = self.root / 'synthetic-outside-templates'
        templates.rename(outside)
        templates.symlink_to(outside, target_is_directory=True)
        with patch.object(audit_release, 'ROOT', source):
            with self.assertRaises(ValueError):
                audit_release.audit_source()

    def test_symlinked_source_file_is_rejected(self):
        source = self.source_fixture()
        file = source / 'README.md'
        file.unlink()
        file.symlink_to('LICENSE')
        with patch.object(audit_release, 'ROOT', source):
            with self.assertRaises(ValueError):
                audit_release.audit_source()

    def test_missing_source_file_is_rejected(self):
        source = self.source_fixture()
        (source / 'README.md').unlink()
        with patch.object(audit_release, 'ROOT', source):
            with self.assertRaises(ValueError):
                audit_release.audit_source()

    def test_historical_paths_must_be_allowlisted(self):
        audit_release.check_git_paths(b'README.md\0docs/compatibility.md\0')
        with self.assertRaises(ValueError) as result:
            audit_release.check_git_paths(b'README.md\0docs/synthetic-unreviewed-name.md\0')
        self.assertNotIn('synthetic-unreviewed-name', str(result.exception))


if __name__ == '__main__':
    unittest.main()
