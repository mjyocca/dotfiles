"""Upgrade interfaces tested with stub commands; no host upgrades are run."""

import errno
from concurrent.futures import ThreadPoolExecutor
import os
import pty
import subprocess
import unittest

from test_bootstrap import BASH, MAKE, CheckoutTestCase


@unittest.skipUnless(MAKE, "make is required")
class UpgradeTests(CheckoutTestCase):
    def setUp(self):
        super().setUp()
        self.write_command("mise", (
            '[[ "$1" == -C && "$2" == "$PWD" ]] || exit 91\n'
            'shift 2\n'
            'printf "mise %s\\n" "$*" >> "$TEST_LOG"\n'
            'exit "${UPGRADE_EXIT:-0}"\n'
        ))
        self.write_command("omarchy-update", (
            'printf "omarchy-update:%s\\n" "$*" >> "$TEST_LOG"\n'
            'exit "${UPGRADE_EXIT:-0}"\n'
        ))
        for command in ("pacman", "yay", "brew"):
            self.write_command(command, 'echo forbidden-direct-upgrade >> "$TEST_LOG"; exit 91\n')

    def select_omarchy(self):
        self.env.update(PROFILE="omarchy", TEST_OS="Linux")

    def run_in_terminal(self, *arguments, answer="y\n"):
        master, slave = pty.openpty()

        def read_output():
            output = bytearray()
            while True:
                try:
                    chunk = os.read(master, 65536)
                except OSError as error:
                    if error.errno == errno.EIO:
                        break
                    raise
                if not chunk:
                    break
                output.extend(chunk)
            return output.decode()

        try:
            # Drain while the child runs: macOS may discard unread PTY output
            # once the last slave descriptor closes.
            with ThreadPoolExecutor(max_workers=1) as executor:
                output = executor.submit(read_output)
                try:
                    with subprocess.Popen(
                        arguments, cwd=self.root, env=self.env,
                        stdin=slave, stdout=slave, stderr=slave,
                    ) as process:
                        os.write(master, answer.encode())
                        try:
                            process.wait(timeout=20)
                        except subprocess.TimeoutExpired:
                            process.kill()
                            process.wait()
                            raise
                finally:
                    os.close(slave)
                    slave = None
                return subprocess.CompletedProcess(arguments, process.returncode, output.result(timeout=5), "")
        finally:
            if slave is not None:
                os.close(slave)
            os.close(master)

    def test_make_upgrade_runs_only_mise_tools_on_both_profiles(self):
        for profile in ("macos", "omarchy"):
            with self.subTest(profile=profile):
                self.log.unlink(missing_ok=True)
                self.assert_success(self.run_command(MAKE, "upgrade", f"PROFILE={profile}"))
                self.assertEqual(self.events(), ["mise upgrade --no-prune"])

    def test_macos_system_upgrade_uses_effective_mise_packages_only(self):
        self.assert_success(self.run_command(MAKE, "upgrade-system"))
        self.assertEqual(self.events(), ["mise bootstrap packages upgrade"])

    def test_omarchy_confirmation_preserves_upstream_prompts_and_scope(self):
        self.select_omarchy()
        result = self.run_in_terminal(MAKE, "upgrade-system")
        self.assert_success(result)
        self.assertIn("whole Omarchy system", result.stdout)
        self.assertIn("may prompt for a reboot", result.stdout)
        self.assertEqual(self.events(), ["omarchy-update:"])

    def test_omarchy_decline_or_eof_does_not_update(self):
        self.select_omarchy()
        for answer in ("n\n", "\n", "\x04"):
            with self.subTest(answer=repr(answer)):
                result = self.run_in_terminal(MAKE, "upgrade-system", answer=answer)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("cancelled", result.stdout)
                self.assertEqual(self.events(), [])

    def test_omarchy_rejects_noninteractive_execution(self):
        self.select_omarchy()
        result = self.run_command(MAKE, "upgrade-system")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("interactive terminal", result.stderr)
        self.assertEqual(self.events(), [])

    def test_missing_dependencies_fail_without_fallback(self):
        for script, function, message in (
            ("shared/upgrade.sh", "upgrade_tools", "mise is not installed"),
            ("macos/upgrade-system.sh", "upgrade_system", "mise is not installed"),
            ("omarchy/upgrade-system.sh", "upgrade_system", "no Pacman fallback"),
        ):
            with self.subTest(script=script):
                if script.startswith("omarchy/"):
                    self.select_omarchy()
                result = self.run_command(BASH, "-c", (
                    f'source scripts/{script}\n'
                    'command_exists() { return 1; }\n'
                    f'{function}\n'
                ))
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(message, result.stderr)
                self.assertEqual(self.events(), [])

    def test_upgrade_failures_propagate(self):
        self.env["UPGRADE_EXIT"] = "17"
        for target in ("upgrade", "upgrade-system"):
            with self.subTest(target=target):
                self.log.unlink(missing_ok=True)
                self.assertNotEqual(self.run_command(MAKE, target).returncode, 0)
                self.assertEqual(len(self.events()), 1)
        self.select_omarchy()
        self.log.unlink(missing_ok=True)
        result = self.run_in_terminal(BASH, "scripts/omarchy/upgrade-system.sh")
        self.assertEqual(result.returncode, 17)
        self.assertEqual(self.events(), ["omarchy-update:"])

    def test_sourcing_upgrade_interfaces_does_not_upgrade(self):
        for script in ("shared/upgrade.sh", "macos/upgrade-system.sh", "omarchy/upgrade-system.sh"):
            with self.subTest(script=script):
                self.assert_success(self.run_command(BASH, "-c", f"source scripts/{script}"))
                self.assertEqual(self.events(), [])

    def test_script_arguments_cannot_bypass_upgrade_policy(self):
        for script in ("shared/upgrade.sh", "macos/upgrade-system.sh", "omarchy/upgrade-system.sh"):
            with self.subTest(script=script):
                if script.startswith("omarchy/"):
                    self.select_omarchy()
                result = self.run_command(BASH, f"scripts/{script}", "--yes")
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("accept no arguments", result.stderr)
                self.assertEqual(self.events(), [])

    def test_platform_entrypoints_reject_wrong_os(self):
        self.env["TEST_OS"] = "Linux"
        result = self.run_command(BASH, "scripts/macos/upgrade-system.sh")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("macOS only", result.stderr)
        self.env["TEST_OS"] = "Darwin"
        result = self.run_command(BASH, "scripts/omarchy/upgrade-system.sh")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Linux only", result.stderr)
        self.env.update(TEST_OS="Linux", PROFILE="arch")
        result = self.run_command(BASH, "scripts/omarchy/upgrade-system.sh")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Omarchy only", result.stderr)
        self.assertEqual(self.events(), [])

    def test_make_validates_profiles_before_either_upgrade(self):
        for target in ("upgrade", "upgrade-system"):
            for assignment in ("PROFILE=unknown", "MISE_ENV=staging"):
                with self.subTest(target=target, assignment=assignment):
                    result = self.run_command(MAKE, target, assignment)
                    self.assertNotEqual(result.returncode, 0)
                    self.assertEqual(self.events(), [])

    def test_new_profile_requires_explicit_system_upgrade_entrypoint(self):
        self.write_file(".config/mise/config.example.toml", "")
        result = self.run_command(MAKE, "upgrade-system", "PROFILE=example")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Missing platform stage", result.stderr)
        self.assertEqual(self.events(), [])


if __name__ == "__main__":
    unittest.main()
