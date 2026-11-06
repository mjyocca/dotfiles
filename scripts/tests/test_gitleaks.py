"""Run with python3 -m unittest discover -s scripts/tests -v; requires Gitleaks."""

import os
from pathlib import Path
import shlex
import shutil
import subprocess
import tempfile
import unittest


REPO_ROOT = Path(__file__).resolve().parents[2]
GIT = shutil.which("git")
GITLEAKS = shutil.which("gitleaks")
# Synthetic, nonfunctional token assembled so the test itself isn't a finding.
FAKE_TOKEN = "ghp_" + "A1b2C3d4E5f6G7h8I9j0K1l2M3n4O5p6Q7r8"


@unittest.skipUnless(GIT and GITLEAKS, "git and gitleaks must be on PATH")
class GitleaksHookTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="gitleaks-test-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.home = self.root / "home"
        self.home.mkdir()
        self.env = {
            key: value
            for key, value in os.environ.items()
            if not key.startswith(("GIT_", "GITLEAKS_"))
        }
        self.env.update(
            HOME=str(self.home),
            PATH=str(self.bin),
            GIT_CONFIG_NOSYSTEM="1",
            GIT_CONFIG_GLOBAL=os.devnull,
        )
        (self.bin / "git").symlink_to(GIT)
        (self.bin / "gitleaks").symlink_to(GITLEAKS)
        # Keep the environment helper from appending host Homebrew paths, so
        # missing-tool tests cannot accidentally discover a host installation.
        self.write_executable("uname", "echo Linux\n")
        for relative in (
            ".githooks/pre-commit",
            ".gitleaks.toml",
            "scripts/shared/environment.sh",
        ):
            target = self.root / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(REPO_ROOT / relative, target)
        self.git("init", "--quiet")

    def run_command(self, arguments):
        return subprocess.run(
            arguments,
            cwd=self.root,
            env=self.env,
            capture_output=True,
            text=True,
        )

    def git(self, *arguments):
        result = self.run_command([GIT, *arguments])
        self.assertEqual(result.returncode, 0, result.stderr)

    def write_executable(self, name, body):
        target = self.bin / name
        target.write_text("#!/bin/bash\n" + body)
        target.chmod(0o755)

    def stage(self, content, filename="sample.txt"):
        (self.root / filename).write_text(content)
        self.git("add", "--", filename)

    def run_hook(self):
        result = self.run_command(["/bin/bash", ".githooks/pre-commit"])
        output = result.stdout + result.stderr
        self.assertNotIn(FAKE_TOKEN, output, "scan output must redact secrets")
        return result.returncode, output

    def test_clean_staged_content_passes(self):
        self.stage("ordinary configuration\n")
        status, output = self.run_hook()
        self.assertEqual(status, 0, output)
        self.assertIn("No secrets detected", output)

    def test_staged_secret_blocks_commit(self):
        self.stage(f'github_token = "{FAKE_TOKEN}"\n')
        status, output = self.run_hook()
        self.assertNotEqual(status, 0, output)
        self.assertIn("Secrets detected in staged changes", output)

    def test_unstaged_secret_does_not_affect_staged_scan(self):
        self.stage("ordinary configuration\n")
        (self.root / "sample.txt").write_text(f'github_token = "{FAKE_TOKEN}"\n')
        status, output = self.run_hook()
        self.assertEqual(status, 0, output)

    def test_dotfile_secret_blocks_commit(self):
        self.stage(f'github_token = "{FAKE_TOKEN}"\n', ".config.toml")
        status, output = self.run_hook()
        self.assertNotEqual(status, 0, output)
        self.assertIn("Secrets detected in staged changes", output)

    def test_environment_config_cannot_disable_repository_rules(self):
        self.env["GITLEAKS_CONFIG_TOML"] = 'title = "no detectors"\n'
        self.env["GITLEAKS_CONFIG"] = str(self.root / "nonexistent.toml")
        self.stage(f'github_token = "{FAKE_TOKEN}"\n')
        status, output = self.run_hook()
        self.assertNotEqual(status, 0, output)
        self.assertIn("Secrets detected in staged changes", output)

    def test_missing_scanner_blocks_commit(self):
        (self.bin / "gitleaks").unlink()
        self.write_executable("mise", "exit 1\n")
        status, output = self.run_hook()
        self.assertNotEqual(status, 0, output)
        self.assertIn("gitleaks not found", output)
        self.assertIn("Commit blocked", output)

    def test_missing_scanner_and_mise_block_commit(self):
        (self.bin / "gitleaks").unlink()
        status, output = self.run_hook()
        self.assertNotEqual(status, 0, output)
        self.assertIn("gitleaks not found", output)
        self.assertIn("Commit blocked", output)

    def test_mise_fallback_runs_scanner(self):
        (self.bin / "gitleaks").unlink()
        self.write_executable("mise", f"printf '%s\\n' {shlex.quote(GITLEAKS)}\n")
        self.stage(f'github_token = "{FAKE_TOKEN}"\n')
        status, output = self.run_hook()
        self.assertNotEqual(status, 0, output)
        self.assertIn("Secrets detected in staged changes", output)

    def test_invalid_config_is_a_scan_error_not_a_finding(self):
        (self.root / ".gitleaks.toml").write_text("[invalid\n")
        self.stage("ordinary configuration\n")
        status, output = self.run_hook()
        self.assertNotEqual(status, 0, output)
        self.assertIn("Secret scan failed", output)
        self.assertNotIn("Secrets detected in staged changes", output)

    def test_scanner_runtime_failure_blocks_commit(self):
        (self.bin / "gitleaks").unlink()
        self.write_executable("gitleaks", "echo 'scanner unavailable' >&2\nexit 2\n")
        status, output = self.run_hook()
        self.assertNotEqual(status, 0, output)
        self.assertIn("Secret scan failed (exit 2)", output)
        self.assertNotIn("Secrets detected in staged changes", output)


if __name__ == "__main__":
    unittest.main()
