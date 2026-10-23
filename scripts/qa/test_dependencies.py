"""Host regression tests: python3 -m unittest discover -s scripts/qa -p 'test_*.py'."""
import sys
sys.dont_write_bytecode = True

import contextlib
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest

SPEC = importlib.util.spec_from_file_location(
    "dependencies", Path(__file__).resolve().parents[1] / "dependencies.py"
)
dependencies = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(dependencies)


class DependencyLockTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.source = self.root / "source"
        self.source.mkdir()
        self.git("init", "-q")
        self.git("config", "user.name", "Test")
        self.git("config", "user.email", "test@example.invalid")
        (self.source / "input").write_text("first\n")
        self.git("add", "input")
        self.git("commit", "-qm", "first")
        self.first = self.git("rev-parse", "HEAD")
        (self.root / "Onyx.vent").write_text(f"git {self.source} .vent/repos/Fixture\n")
        self.write_lock(self.first)
        self.repos = self.root / "repos"
        self.repos.mkdir()

    def git(self, *args, repo=None):
        return dependencies.git(repo or self.source, *args)

    def write_lock(self, sha):
        (self.root / "Onyx.lock.json").write_text(
            json.dumps({"version": 1, "revisions": {"Fixture": sha}})
        )

    def run_mode(self, mode):
        with contextlib.redirect_stdout(io.StringIO()):
            dependencies.run(mode, self.root, self.repos)

    def test_sync_clones_and_selects_exact_commit_instead_of_latest(self):
        (self.source / "input").write_text("second\n")
        self.git("commit", "-qam", "second")
        self.run_mode("sync")
        checkout = self.repos / "Fixture"
        self.assertEqual(self.git("rev-parse", "HEAD", repo=checkout), self.first)
        self.assertEqual((checkout / "input").read_text(), "first\n")
        self.run_mode("check")

    def test_check_rejects_changed_revision(self):
        self.run_mode("sync")
        self.write_lock("0" * 40)
        with self.assertRaisesRegex(ValueError, "revision differs"):
            self.run_mode("check")

    def test_check_and_sync_preserve_dirty_tracked_and_untracked_files(self):
        self.run_mode("sync")
        checkout = self.repos / "Fixture"
        (checkout / "input").write_text("local edit\n")
        (checkout / "untracked").write_text("keep me\n")
        for mode in ["check", "sync", "update"]:
            with self.assertRaisesRegex(ValueError, "uncommitted changes"):
                self.run_mode(mode)
        self.assertEqual((checkout / "input").read_text(), "local edit\n")
        self.assertEqual((checkout / "untracked").read_text(), "keep me\n")
        self.run_mode("workspace")

    def test_sync_never_checks_out_symlinked_developer_repository(self):
        (self.repos / "Fixture").symlink_to(self.source, target_is_directory=True)
        with self.assertRaisesRegex(ValueError, "symlink"):
            self.run_mode("sync")
        self.assertEqual(self.git("rev-parse", "HEAD"), self.first)

    def test_sync_rejects_directory_inside_an_unrelated_git_worktree(self):
        nested = self.source / "nested"
        nested.mkdir()
        self.repos = self.source
        (self.source / "Fixture").mkdir()
        with self.assertRaisesRegex(ValueError, "not a repository root"):
            self.run_mode("sync")
        self.assertEqual(self.git("rev-parse", "HEAD"), self.first)

    def test_update_records_clean_committed_head(self):
        self.run_mode("sync")
        self.write_lock("0" * 40)
        self.run_mode("update")
        self.assertEqual(dependencies.revisions(self.root)["Fixture"], self.first)

    def test_lock_requires_every_manifest_dependency_and_full_shas(self):
        self.write_lock("main")
        with self.assertRaisesRegex(ValueError, "full Git commit SHA"):
            self.run_mode("check")
        (self.root / "Onyx.lock.json").write_text('{"version": 1, "revisions": {}}')
        with self.assertRaisesRegex(ValueError, "exactly the manifest"):
            self.run_mode("check")


if __name__ == "__main__":
    unittest.main()
