"""Native mise integration tests using temporary homes and checkouts only.

Run with python3 -m unittest discover -s scripts/tests -v.
Requires mise with dotfiles and early .miserc.local.toml support.
"""

import json
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import tempfile
import unittest


REPO_ROOT = Path(__file__).resolve().parents[2]
MISE = shutil.which("mise")
ZSH = shutil.which("zsh")


@unittest.skipUnless(MISE, "mise is required for native workspace tests")
class MiseWorkspaceTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="mise-workspace-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name).resolve()
        self.home = self.root / "home"
        self.checkout = self.home / "checkout with spaces"
        self.config = self.checkout / ".config/mise"
        self.config.mkdir(parents=True)
        self.target = self.checkout / ".miserc.local.toml"
        self.global_config = self.home / ".config/mise"
        self.global_config.mkdir(parents=True)
        self.outside = self.home / "unrelated-project"
        self.outside.mkdir()
        self.env = {
            "HOME": str(self.home),
            "PATH": "/usr/bin:/bin",
            "XDG_CONFIG_HOME": str(self.home / ".config"),
            "XDG_DATA_HOME": str(self.home / ".local/share"),
            "XDG_STATE_HOME": str(self.home / ".local/state"),
            "XDG_CACHE_HOME": str(self.home / ".cache"),
            "MISE_CONFIG_DIR": str(self.global_config),
            "MISE_SYSTEM_CONFIG_DIR": str(self.root / "system-mise"),
            "MISE_DATA_DIR": str(self.home / ".local/share/mise"),
            "MISE_STATE_DIR": str(self.home / ".local/state/mise"),
            "MISE_CACHE_DIR": str(self.home / ".cache/mise"),
            "MISE_TRUSTED_CONFIG_PATHS": str(self.checkout),
            "MISE_AUTO_INSTALL": "0",
            "MISE_OFFLINE": "1",
            "MISE_DISABLE_UPDATE_WARNING": "1",
            "GIT_CONFIG_NOSYSTEM": "1",
            "GIT_CONFIG_GLOBAL": os.devnull,
        }
        if "TMPDIR" in os.environ:
            self.env["TMPDIR"] = os.environ["TMPDIR"]

        # No real package/tool declarations: native mise only writes the scoped seed.
        (self.config / "config.toml").write_text('[env]\nTEST_WORKSPACE_BASE = "loaded"\n')
        for profile in ("macos", "omarchy"):
            text = (REPO_ROOT / f".config/mise/config.{profile}.toml").read_text()
            declaration = re.search(
                r"(?ms)^\[dotfiles\.workspace-mise-env\]\n.*?(?=^\[|\Z)", text
            )
            self.assertIsNotNone(declaration, f"Missing workspace seed declaration: {profile}")
            (self.config / f"config.{profile}.toml").write_text(
                f'[env]\nTEST_WORKSPACE_PLATFORM = "{profile}"\n\n' + declaration.group()
            )
        shutil.copytree(REPO_ROOT / ".config/mise/workspace", self.config / "workspace")

        # Simulate all existing global layers without installing or resolving tools.
        (self.global_config / "config.toml").write_text('[env]\nTEST_GLOBAL_CONFIG = "preserved"\n')
        (self.global_config / "config.local.toml").write_text('[env]\nTEST_GLOBAL_LOCAL = "preserved"\n')
        fragments = self.global_config / "conf.d"
        fragments.mkdir()
        (fragments / "10-dotfiles-tools.toml").write_text('[env]\nTEST_GLOBAL_TOOLS = "inherited"\n')
        (fragments / "20-dotfiles-platform.toml").write_text('[env]\nTEST_GLOBAL_PLATFORM = "inherited"\n')
        shutil.copyfile(REPO_ROOT / ".config/mise/global/miserc.toml.tera", self.global_config / "miserc.toml")

    def run_mise(self, *arguments, cwd=None, env=None):
        return subprocess.run(
            [MISE, *arguments], cwd=cwd or self.checkout, env=env or self.env,
            capture_output=True, text=True, timeout=30,
        )

    def assert_success(self, result):
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def seed(self, profile):
        # Preview and apply only this fixture's checkout-local target.
        self.assert_success(self.run_mise("-E", profile, "dot", "apply", "--dry-run", str(self.target)))
        self.assert_success(self.run_mise("-E", profile, "dot", "apply", str(self.target)))

    def read_environment(self, *arguments, cwd=None, env=None):
        result = self.run_mise(*arguments, "env", "--json", cwd=cwd, env=env)
        self.assert_success(result)
        return json.loads(result.stdout)

    def test_first_deployment_seeds_each_platform_and_native_discovery(self):
        for profile in ("macos", "omarchy"):
            with self.subTest(profile=profile):
                self.target.unlink(missing_ok=True)
                self.seed(profile)
                self.assertIn(f'env = ["{profile}"]', self.target.read_text())
                self.assertFalse(self.target.is_symlink())
                self.assertEqual(self.target.stat().st_mode & 0o777, 0o600)
                self.assertEqual(self.read_environment()["TEST_WORKSPACE_PLATFORM"], profile)
                self.assert_success(self.run_mise("dot", "apply", "--dry-run", str(self.target)))

    def test_dry_run_does_not_create_default(self):
        self.assert_success(self.run_mise("-E", "macos", "dot", "apply", "--dry-run", str(self.target)))
        self.assertFalse(self.target.exists())

    def test_existing_workspace_default_and_edits_are_preserved(self):
        original = '# Personal selection\nenv = ["omarchy"]\n'
        self.target.write_text(original)
        self.target.chmod(0o644)
        self.seed("macos")
        self.assertEqual(self.target.read_text(), original)
        self.assertEqual(self.target.stat().st_mode & 0o777, 0o644)
        self.assertEqual(self.read_environment()["TEST_WORKSPACE_PLATFORM"], "omarchy")

    def test_existing_symlink_is_preserved(self):
        local = self.root / "personal-miserc.toml"
        local.write_text('env = ["omarchy"]\n')
        self.target.symlink_to(local)
        self.seed("macos")
        self.assertTrue(self.target.is_symlink())
        self.assertEqual(self.target.resolve(), local)
        self.assertEqual(local.read_text(), 'env = ["omarchy"]\n')

    def test_explicit_environment_variable_overrides_workspace_default(self):
        self.seed("macos")
        env = dict(self.env, MISE_ENV="omarchy")
        self.assertEqual(self.read_environment(env=env)["TEST_WORKSPACE_PLATFORM"], "omarchy")

    def test_explicit_cli_flag_overrides_shell_and_workspace(self):
        self.seed("omarchy")
        env = dict(self.env, MISE_ENV="omarchy")
        self.assertEqual(self.read_environment("-E", "macos", env=env)["TEST_WORKSPACE_PLATFORM"], "macos")

    def test_global_configuration_is_inherited_without_modification(self):
        before = {path: path.read_bytes() for path in self.global_config.rglob("*") if path.is_file()}
        self.seed("omarchy")
        environment = self.read_environment()
        for key in ("TEST_GLOBAL_CONFIG", "TEST_GLOBAL_LOCAL"):
            self.assertEqual(environment[key], "preserved")
        for key in ("TEST_GLOBAL_TOOLS", "TEST_GLOBAL_PLATFORM"):
            self.assertEqual(environment[key], "inherited")
        self.assertEqual(environment["TEST_WORKSPACE_BASE"], "loaded")
        after = {path: path.read_bytes() for path in self.global_config.rglob("*") if path.is_file()}
        self.assertEqual(after, before)

    def test_workspace_default_is_inherited_from_subdirectories(self):
        self.seed("omarchy")
        child = self.checkout / "nested/project"
        child.mkdir(parents=True)
        self.assertEqual(self.read_environment(cwd=child)["TEST_WORKSPACE_PLATFORM"], "omarchy")

    def test_workspace_default_preserves_mise_tool_versions_discovery(self):
        self.seed("omarchy")
        (self.checkout / ".tool-versions").write_text("nodejs 24.0.0\n")
        result = self.run_mise("ls", "--current", "--json")
        self.assert_success(result)
        self.assertIn("node", json.loads(result.stdout))

    def test_global_default_selection_is_not_modified_by_workspace_deployment(self):
        global_default = self.global_config / "miserc.local.toml"
        global_default.write_text('env = ["baseline"]\n')
        (self.global_config / "config.baseline.toml").write_text('[env]\nTEST_GLOBAL_BASELINE = "loaded"\n')
        self.assertEqual(self.read_environment()["TEST_GLOBAL_BASELINE"], "loaded")
        self.seed("omarchy")
        environment = self.read_environment()
        self.assertEqual(environment["TEST_WORKSPACE_PLATFORM"], "omarchy")
        self.assertEqual(environment["TEST_GLOBAL_CONFIG"], "preserved")
        self.assertEqual(global_default.read_text(), 'env = ["baseline"]\n')

    def test_workspace_can_explicitly_include_global_environment_profiles(self):
        (self.global_config / "config.baseline.toml").write_text('[env]\nTEST_GLOBAL_BASELINE = "loaded"\n')
        self.target.write_text('env = ["baseline", "omarchy"]\n')
        self.seed("omarchy")
        environment = self.read_environment()
        self.assertEqual(environment["TEST_WORKSPACE_PLATFORM"], "omarchy")
        self.assertEqual(environment["TEST_GLOBAL_BASELINE"], "loaded")

    def test_workspace_default_does_not_leak_into_other_projects(self):
        self.seed("omarchy")
        environment = self.read_environment(cwd=self.outside)
        self.assertNotIn("TEST_WORKSPACE_PLATFORM", environment)
        self.assertNotIn("TEST_WORKSPACE_BASE", environment)
        self.assertEqual(environment["TEST_GLOBAL_CONFIG"], "preserved")
        self.assertEqual(environment["TEST_GLOBAL_TOOLS"], "inherited")

    def test_bash_uses_native_workspace_default_without_startup_files(self):
        self.seed("omarchy")
        result = subprocess.run(
            ["/bin/bash", "--noprofile", "--norc", "-c", f"exec {shlex.quote(MISE)} env --json"],
            cwd=self.checkout, env=self.env, capture_output=True, text=True, timeout=30,
        )
        self.assert_success(result)
        self.assertEqual(json.loads(result.stdout)["TEST_WORKSPACE_PLATFORM"], "omarchy")

    @unittest.skipUnless(ZSH, "zsh is required")
    def test_zsh_startup_respects_project_defaults_and_explicit_environment(self):
        shutil.copyfile(REPO_ROOT / "packages/zsh/.zshenv", self.home / ".zshenv")
        self.seed("macos")
        (self.outside / ".miserc.local.toml").write_text('env = ["dev"]\n')
        for profile in ("dev", "staging"):
            (self.outside / f"mise.{profile}.toml").write_text(
                f'[env]\nTEST_PROJECT_ENV = "{profile}"\n'
            )
        env = dict(self.env, MISE_TRUSTED_CONFIG_PATHS=str(self.home))
        cases = (
            (self.checkout, env, "TEST_WORKSPACE_PLATFORM", "macos"),
            (self.outside, env, "TEST_PROJECT_ENV", "dev"),
            (self.outside, dict(env, MISE_ENV="staging"), "TEST_PROJECT_ENV", "staging"),
        )
        for cwd, environment, key, expected in cases:
            with self.subTest(cwd=cwd, expected=expected):
                expected_env = shlex.quote(environment.get("MISE_ENV", "__unset__"))
                command = (f'[[ "${{MISE_ENV-__unset__}}" == {expected_env} ]] && '
                           f"exec {shlex.quote(MISE)} env --json")
                result = subprocess.run(
                    [ZSH, "-d", "-c", command],
                    cwd=cwd, env=environment, capture_output=True, text=True, timeout=30,
                )
                self.assert_success(result)
                resolved = json.loads(result.stdout)
                self.assertEqual(resolved[key], expected)
                self.assertEqual(result.stderr, "")

    @unittest.skipUnless(ZSH, "zsh is required")
    def test_zsh_uses_native_workspace_default_without_startup_files(self):
        self.seed("macos")
        result = subprocess.run(
            [ZSH, "-f", "-c", f"exec {shlex.quote(MISE)} env --json"],
            cwd=self.checkout, env=self.env, capture_output=True, text=True, timeout=30,
        )
        self.assert_success(result)
        self.assertEqual(json.loads(result.stdout)["TEST_WORKSPACE_PLATFORM"], "macos")


if __name__ == "__main__":
    unittest.main()
