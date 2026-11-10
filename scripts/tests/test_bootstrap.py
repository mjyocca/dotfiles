"""Isolated lifecycle tests: python3 -m unittest discover -s scripts/tests -v.

All scripts run in a temporary checkout with fake provisioning commands.
No packages, dotfiles, repositories, or hooks on the host are modified.
"""

import os
from pathlib import Path
import shlex
import shutil
import subprocess
import tempfile
import unittest


REPO_ROOT = Path(__file__).resolve().parents[2]
MAKE = shutil.which("make")
GIT = shutil.which("git")
BASH = "/bin/bash"
BOOTSTRAP_STAGES = (
    "prerequisites", "packages", "repos", "link", "tools", "plugins", "config", "hooks"
)
SYNC_STAGES = ("packages", "repos", "link", "tools", "plugins")
TOOL_CONFIG_FILES = (
    "conf.d/10-dotfiles-tools.toml", "conf.d/20-dotfiles-platform.toml", "miserc.toml"
)


class CheckoutTestCase(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="dotfiles-bootstrap-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name).resolve() / "checkout with spaces"
        self.root.mkdir()
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.home = self.root / "home"
        self.home.mkdir()
        self.log = self.root / "commands.log"
        self.env = {
            key: value for key, value in os.environ.items()
            if not key.startswith(("MISE_", "MAKE", "MFLAGS", "DOTFILES_", "GIT_", "GITLEAKS_"))
            and key not in ("PROFILE", "BASH_ENV", "ENV", "SHELLOPTS", "BASHOPTS")
            and not key.startswith("BASH_FUNC_")
        }
        self.env.update(
            HOME=str(self.home),
            XDG_CONFIG_HOME=str(self.home / ".config"),
            PATH=f"{self.bin}:/usr/bin:/bin",
            PROFILE="macos",
            TEST_LOG=str(self.log),
            TEST_OS="Darwin",
            GIT_CONFIG_NOSYSTEM="1",
            GIT_CONFIG_GLOBAL=os.devnull,
        )
        shutil.copyfile(REPO_ROOT / "Makefile", self.root / "Makefile")
        for directory in ("shared", "linux", "macos", "omarchy"):
            shutil.copytree(REPO_ROOT / "scripts" / directory, self.root / "scripts" / directory)
        for profile in ("macos", "omarchy"):
            self.write_file(f".config/mise/config.{profile}.toml", "")
        self.write_command("uname", 'printf "%s\\n" "$TEST_OS"\n')

    def write_file(self, relative, body):
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(body)
        return path

    def write_command(self, name, body):
        path = self.write_file(f"bin/{name}", f"#!{BASH}\nset -eu\n{body}")
        path.chmod(0o755)

    def run_command(self, *arguments):
        return subprocess.run(
            arguments, cwd=self.root, env=self.env, capture_output=True, text=True, timeout=20
        )

    def assert_success(self, result):
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def events(self):
        return self.log.read_text().splitlines() if self.log.exists() else []


@unittest.skipUnless(MAKE, "make is required")
class MakeLifecycleTests(CheckoutTestCase):
    def setUp(self):
        super().setUp()
        for profile in ("macos", "omarchy"):
            for stage in (*BOOTSTRAP_STAGES, "aur"):
                self.write_stage(f"scripts/{profile}/{stage}.sh", stage)
        for stage in ("repos", "link", "tools"):
            self.write_stage(f"scripts/shared/{stage}.sh", stage)

    def write_stage(self, relative, stage):
        self.write_file(relative, (
            f"printf '%s\\n' '{stage}:start' >> \"$TEST_LOG\"\n"
            "sleep 0.01\n"
            f'if [ "${{FAIL_STAGE:-}}" = {stage} ]; then exit 17; fi\n'
            f"printf '%s\\n' '{stage}:end' >> \"$TEST_LOG\"\n"
        ))

    def expected_events(self, stages):
        return [f"{stage}:{event}" for stage in stages for event in ("start", "end")]

    def test_bare_make_shows_help_without_running_stages(self):
        self.env["PROFILE"] = "unknown"
        result = self.run_command(MAKE)
        self.assert_success(result)
        self.assertIn("Usage: make", result.stdout)
        self.assertEqual(self.events(), [])

    def test_bootstrap_is_ordered_even_with_parallel_make_on_both_profiles(self):
        for profile in ("macos", "omarchy"):
            with self.subTest(profile=profile):
                self.log.unlink(missing_ok=True)
                result = self.run_command(MAKE, "-j8", "bootstrap", f"PROFILE={profile}")
                self.assert_success(result)
                self.assertEqual(self.events(), self.expected_events(BOOTSTRAP_STAGES))

    def test_sync_is_ordered_and_omits_full_bootstrap_stages(self):
        result = self.run_command(MAKE, "-j8", "sync")
        self.assert_success(result)
        self.assertEqual(self.events(), self.expected_events(SYNC_STAGES))

    def test_sync_stops_after_failed_deployment(self):
        self.env["FAIL_STAGE"] = "link"
        result = self.run_command(MAKE, "-j8", "sync")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.events(), self.expected_events(("packages", "repos")) + ["link:start"])

    def test_platform_detection_defaults_to_macos_on_darwin(self):
        self.env.pop("PROFILE")
        self.assert_success(self.run_command(MAKE, "packages"))
        self.assertEqual(self.events(), self.expected_events(("packages",)))

    def test_bootstrap_stops_at_each_failed_stage(self):
        for index, stage in enumerate(BOOTSTRAP_STAGES):
            with self.subTest(stage=stage):
                self.log.unlink(missing_ok=True)
                self.env["FAIL_STAGE"] = stage
                result = self.run_command(MAKE, "-j8", "bootstrap")
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(
                    self.events(),
                    self.expected_events(BOOTSTRAP_STAGES[:index]) + [f"{stage}:start"],
                )

    def test_invalid_or_unconfigured_profiles_fail_before_any_stage(self):
        for profile in ("ubuntu", "unknown", "../macos", "macos,omarchy", ""):
            with self.subTest(profile=profile):
                result = self.run_command(MAKE, "bootstrap", f"PROFILE={profile}")
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(self.events(), [])

    def test_conflicting_mise_environment_fails_before_any_stage(self):
        result = self.run_command(MAKE, "bootstrap", "MISE_ENV=omarchy")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("conflicts", result.stderr)
        self.assertEqual(self.events(), [])

    def test_platform_inheritance_is_explicit_not_make_fallback(self):
        self.write_file(".config/mise/config.example.toml", "")
        self.write_stage("scripts/linux/packages.sh", "linux-packages")
        result = self.run_command(MAKE, "packages", "PROFILE=example")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Missing platform stage", result.stderr)
        self.assertEqual(self.events(), [])

    def test_new_distro_can_explicitly_source_linux_entrypoint(self):
        self.write_file(".config/mise/config.example.toml", "")
        self.write_file("scripts/linux/packages.sh", (
            "install_packages() { printf 'linux-packages\\n' >> \"$TEST_LOG\"; }\n"
            'if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then install_packages; fi\n'
        ))
        self.write_file("scripts/example/packages.sh", (
            'source "$(dirname "${BASH_SOURCE[0]}")/../linux/packages.sh"\n'
            "install_packages\n"
        ))
        result = self.run_command(MAKE, "packages", "PROFILE=example")
        self.assert_success(result)
        self.assertEqual(self.events(), ["linux-packages"])

    def test_platform_preferences_are_optional(self):
        (self.root / "scripts/macos/config.sh").unlink()
        result = self.run_command(MAKE, "config")
        self.assert_success(result)
        self.assertIn("No additional platform preferences", result.stdout)
        self.assertEqual(self.events(), [])

    def test_aur_requires_omarchy_profile(self):
        result = self.run_command(MAKE, "aur")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.events(), [])
        self.assert_success(self.run_command(MAKE, "aur", "PROFILE=omarchy"))
        self.assertEqual(self.events(), self.expected_events(("aur",)))

    def test_legacy_entrypoints_are_removed(self):
        for target in (
            "fresh-install", "pack", "plug", "apply_settings", "install_mise",
            "zellij-plugins", "bootstrap_macos", "bootstrap_omarchy", "bootstrap_linux",
            "bootstrap_osx", "bootstrap_linux_legacy", "mise_bootstrap", "mise_install",
        ):
            with self.subTest(target=target):
                self.assertNotEqual(self.run_command(MAKE, target).returncode, 0)
        self.assertEqual(self.events(), [])


class ScriptCompositionTests(CheckoutTestCase):
    def setUp(self):
        super().setUp()
        self.write_command("mise", (
            'if [ "${1:-}" = -C ]; then\n'
            f"  [ \"$2\" = {shlex.quote(str(self.root))} ] || exit 90\n"
            "  shift 2\n"
            "fi\n"
            "printf 'mise %s\\n' \"$*\" >> \"$TEST_LOG\"\n"
        ))
        for name in ("sudo", "curl", "git", "yay", "brew", "xcode-select", "apt-get", "dnf", "pacman"):
            self.write_command(name, f'printf "{name} %s\\n" "$*" >> "$TEST_LOG"\n')

    def test_sourcing_all_entrypoints_and_shared_implementations_runs_no_stage(self):
        files = [
            *sorted((self.root / "scripts/macos").glob("*.sh")),
            *sorted((self.root / "scripts/linux").glob("*.sh")),
            *sorted((self.root / "scripts/omarchy").glob("*.sh")),
            *(self.root / "scripts/shared" / f"{name}.sh" for name in (
                "packages", "repos", "link", "tools", "plugins", "hooks", "install-mise"
            )),
        ]
        body = "\n".join(f"source {shlex.quote(str(file))}" for file in files)
        self.assert_success(self.run_command(BASH, "-c", body))
        self.assertEqual(self.events(), [])

    def test_macos_packages_are_scoped_without_deployment_or_tools(self):
        self.assert_success(self.run_command(BASH, "scripts/macos/packages.sh"))
        self.assertEqual(self.events(), ["mise bootstrap --only packages"])

    def test_linux_packages_are_scoped_without_deployment_or_tools(self):
        self.env.update(PROFILE="example", TEST_OS="Linux")
        self.assert_success(self.run_command(BASH, "scripts/linux/packages.sh"))
        self.assertEqual(self.events(), ["mise bootstrap --only packages"])

    def test_omarchy_extends_packages_with_interactive_aur(self):
        self.env.update(PROFILE="omarchy", TEST_OS="Linux")
        self.write_file("packages/aur/packages.txt", "# Comment\n example-package # Inline\nsecond-package")
        self.assert_success(self.run_command(BASH, "scripts/omarchy/packages.sh"))
        self.assertEqual(self.events(), [
            "mise bootstrap --only packages",
            "yay -S --needed --confirm --diffmenu --editmenu --noanswerdiff --noansweredit -- example-package",
            "yay -S --needed --confirm --diffmenu --editmenu --noanswerdiff --noansweredit -- second-package",
        ])

    def test_aur_failure_stops_remaining_packages(self):
        self.env.update(PROFILE="omarchy", TEST_OS="Linux")
        self.write_file("packages/aur/packages.txt", "first\nsecond\n")
        self.write_command("yay", 'printf "yay\\n" >> "$TEST_LOG"\nexit 7\n')
        result = self.run_command(BASH, "scripts/omarchy/packages.sh")
        self.assertEqual(result.returncode, 7, result.stdout + result.stderr)
        self.assertEqual(self.events(), ["mise bootstrap --only packages", "yay"])

    def test_omarchy_rejects_native_flags_before_any_package_installation(self):
        self.env.update(PROFILE="omarchy", TEST_OS="Linux")
        result = self.run_command(BASH, "scripts/omarchy/packages.sh", "--dry-run")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("accepts no arguments", result.stderr)
        self.assertEqual(self.events(), [])

    def test_inherited_function_can_be_replaced_before_stage_execution(self):
        self.env["TEST_OS"] = "Linux"
        body = (
            'source scripts/linux/packages.sh\n'
            'install_system_packages() { printf "custom-packages\\n" >> "$TEST_LOG"; }\n'
            'install_packages\n'
        )
        self.assert_success(self.run_command(BASH, "-c", body))
        self.assertEqual(self.events(), ["custom-packages"])

    def test_repos_only_applies_declared_checkouts(self):
        self.assert_success(self.run_command(BASH, "scripts/shared/repos.sh"))
        self.assertEqual(self.events(), ["mise bootstrap repos apply"])

    def test_link_forwards_scoped_arguments(self):
        self.assert_success(self.run_command(BASH, "scripts/shared/link.sh", "--dry-run", "~/.bashrc"))
        self.assertEqual(self.events(), ["mise dotfiles apply --dry-run ~/.bashrc"])

    def test_tools_require_all_deployed_fragments(self):
        config = self.home / ".config/mise"
        for file in TOOL_CONFIG_FILES:
            result = self.run_command(BASH, "scripts/shared/tools.sh")
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("make link first", result.stderr)
            self.assertEqual(self.events(), [])
            target = config / file
            target.parent.mkdir(parents=True, exist_ok=True)
            target.touch()
        self.assert_success(self.run_command(BASH, "scripts/shared/tools.sh", "--dry-run"))
        self.assertEqual(self.events(), ["mise install --dry-run"])

    def test_macos_config_applies_only_defaults(self):
        self.assert_success(self.run_command(BASH, "scripts/macos/config.sh", "--dry-run"))
        self.assertEqual(self.events(), ["mise -E macos bootstrap macos defaults apply --dry-run"])

    def test_existing_mise_provider_is_reused_without_installation(self):
        self.assert_success(self.run_command(BASH, "scripts/shared/install-mise.sh"))
        self.assertEqual(self.events(), [
            "mise --version", "mise bootstrap --help", "mise dotfiles apply --help"
        ])

    def test_macos_prerequisites_use_existing_mise_and_brew(self):
        self.assert_success(self.run_command(BASH, "scripts/macos/prerequisites.sh"))
        self.assertEqual(self.events(), [
            "xcode-select -p", "mise --version", "mise bootstrap --help", "mise dotfiles apply --help"
        ])

    def test_omarchy_prerequisites_explicitly_inherit_linux(self):
        self.env.update(PROFILE="omarchy", TEST_OS="Linux")
        self.assert_success(self.run_command(BASH, "scripts/omarchy/prerequisites.sh"))
        self.assertEqual(self.events(), [
            "sudo pacman -S --needed --noconfirm git curl make base-devel",
            "mise --version", "mise bootstrap --help", "mise dotfiles apply --help",
        ])

    @unittest.skipUnless(MAKE, "make is required")
    def test_make_link_passes_scoped_arguments_to_real_interface(self):
        self.assert_success(self.run_command(MAKE, "link", "DOTFILES_ARGS=--dry-run ~/.bashrc"))
        self.assertEqual(self.events(), [f"mise dotfiles apply --dry-run {self.home}/.bashrc"])

    def prepare_plugin_test(self):
        self.write_command("gh", (
            'printf "gh %s\\n" "$*" >> "$TEST_LOG"\n'
            'printf "dlvhdr/gh-dash\\n"\n'
        ))
        self.write_command("asdf", (
            'printf "asdf %s\\n" "$*" >> "$TEST_LOG"\n'
            'printf "%s\\n" nodejs deno ruby golang java rust zig bun\n'
        ))
        self.write_command("mise", (
            'printf "mise %s\\n" "${*:3}" >> "$TEST_LOG"\n'
            'case "$*" in\n'
            '  *"vars dotfiles_runtime_manager") printf "%s\\n" "${TEST_RUNTIME_MANAGER:-asdf}";;\n'
            f'  *"which gh --tool gh") printf "%s\\n" {shlex.quote(str(self.bin / "gh"))};;\n'
            f'  *"which asdf --tool github:asdf-vm/asdf") printf "%s\\n" {shlex.quote(str(self.bin / "asdf"))};;\n'
            '  *) exit 91;;\n'
            'esac\n'
        ))
        (self.home / ".tmux/plugins/tpm").mkdir(parents=True)
        plugin = self.home / ".config/zellij/plugins/zellij-autolock.wasm"
        plugin.parent.mkdir(parents=True)
        plugin.write_bytes(b"\x00asm\x01\x00\x00\x00")

    def test_plugins_reuse_existing_installations(self):
        self.prepare_plugin_test()
        for profile in ("macos", "omarchy"):
            with self.subTest(profile=profile):
                self.log.unlink(missing_ok=True)
                self.assert_success(self.run_command(BASH, f"scripts/{profile}/plugins.sh"))
                self.assertEqual(self.events(), [
                    "mise vars dotfiles_runtime_manager",
                    "mise which gh --tool gh",
                    "mise which asdf --tool github:asdf-vm/asdf",
                    "asdf plugin list",
                    "gh extension list",
                ])

    def test_mise_runtime_mode_skips_asdf_plugin_provisioning(self):
        self.prepare_plugin_test()
        self.env["TEST_RUNTIME_MANAGER"] = "mise"
        for profile in ("macos", "omarchy"):
            with self.subTest(profile=profile):
                self.log.unlink(missing_ok=True)
                self.assert_success(self.run_command(BASH, f"scripts/{profile}/plugins.sh"))
                self.assertEqual(self.events(), [
                    "mise vars dotfiles_runtime_manager", "mise which gh --tool gh", "gh extension list",
                ])

    def test_invalid_runtime_mode_stops_plugin_provisioning(self):
        self.prepare_plugin_test()
        self.env["TEST_RUNTIME_MANAGER"] = "invalid"
        for profile in ("macos", "omarchy"):
            with self.subTest(profile=profile):
                self.log.unlink(missing_ok=True)
                result = self.run_command(BASH, f"scripts/{profile}/plugins.sh")
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(self.events(), ["mise vars dotfiles_runtime_manager"])

    def prepare_git_hook_test(self):
        self.write_command("git", f'exec {shlex.quote(GIT)} "$@"\n')
        self.write_command("gitleaks", "exit 0\n")
        source = self.write_file(".githooks/pre-commit", "#!/bin/sh\nexit 0\n")
        source.chmod(0o755)
        self.assert_success(self.run_command(GIT, "init", "--quiet"))
        return source

    @unittest.skipUnless(GIT, "git is required")
    def test_hooks_install_idempotently_through_both_platform_interfaces(self):
        source = self.prepare_git_hook_test()
        for profile in ("macos", "omarchy"):
            self.assert_success(self.run_command(BASH, f"scripts/{profile}/hooks.sh"))
        target = self.root / ".git/hooks/pre-commit"
        self.assertTrue(target.is_symlink())
        self.assertEqual(target.resolve(), source)

    @unittest.skipUnless(GIT, "git is required")
    def test_hooks_preserve_an_existing_unrelated_hook(self):
        self.prepare_git_hook_test()
        target = self.write_file(".git/hooks/pre-commit", "existing user hook\n")
        result = self.run_command(BASH, "scripts/macos/hooks.sh")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("left untouched", result.stderr)
        self.assertEqual(target.read_text(), "existing user hook\n")

    @unittest.skipUnless(GIT, "git is required")
    def test_hooks_respect_custom_git_hooks_path(self):
        source = self.prepare_git_hook_test()
        self.assert_success(self.run_command(GIT, "config", "core.hooksPath", "custom-hooks"))
        self.assert_success(self.run_command(BASH, "scripts/macos/hooks.sh"))
        target = self.root / "custom-hooks/pre-commit"
        self.assertTrue(target.is_symlink())
        self.assertEqual(target.resolve(), source)


if __name__ == "__main__":
    unittest.main()
