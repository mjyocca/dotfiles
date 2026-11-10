"""Shared isolated fixtures for mise deployment and shell integration tests."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[2]
MISE = shutil.which("mise")
ZSH = shutil.which("zsh")
BASH = shutil.which("bash")


class MiseFixture(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="dotfiles-mise-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name).resolve()
        self.home = self.root / "home with spaces"
        self.home.mkdir()
        self.checkout = self.home / "checkout"
        self.config = self.checkout / ".config/mise"
        self.config.mkdir(parents=True)
        self.legacy_policy = self.home / ".config/dotfiles/shell-policy.sh"
        self.discovery_policy = self.home / ".config/mise/miserc.toml"
        self.discovery_policy.parent.mkdir(parents=True)
        self.log = self.root / "commands.log"
        self.bin = self.home / ".local/bin"
        self.bin.mkdir(parents=True)
        self.outside = self.home / "outside"
        self.outside.mkdir()
        self.env = {
            "HOME": str(self.home), "PATH": f"{self.bin}:/usr/bin:/bin",
            "XDG_CONFIG_HOME": str(self.home / ".config"),
            "XDG_DATA_HOME": str(self.home / ".local/share"),
            "XDG_STATE_HOME": str(self.home / ".local/state"),
            "XDG_CACHE_HOME": str(self.home / ".cache"),
            "MISE_CONFIG_DIR": str(self.discovery_policy.parent),
            "MISE_SYSTEM_CONFIG_DIR": str(self.root / "system-mise"),
            "MISE_DATA_DIR": str(self.home / ".local/share/mise"),
            "MISE_STATE_DIR": str(self.home / ".local/state/mise"),
            "MISE_CACHE_DIR": str(self.home / ".cache/mise"),
            "MISE_TRUSTED_CONFIG_PATHS": str(self.home),
            "MISE_AUTO_INSTALL": "0", "MISE_OFFLINE": "1",
            "MISE_DISABLE_UPDATE_WARNING": "1",
            "GIT_CONFIG_NOSYSTEM": "1", "GIT_CONFIG_GLOBAL": os.devnull,
            "TEST_LOG": str(self.log), "TERM": "dumb",
        }
        if "TMPDIR" in os.environ:
            self.env["TMPDIR"] = os.environ["TMPDIR"]

    def write(self, path, text, executable=False):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
        if executable:
            path.chmod(0o755)
        return path

    def run_command(self, arguments, cwd=None):
        return subprocess.run(arguments, cwd=cwd or self.outside, env=self.env,
                              capture_output=True, text=True, timeout=30)

    def assert_success(self, result):
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
