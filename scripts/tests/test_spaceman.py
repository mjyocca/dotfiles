"""Spaceman declarations and isolated deployment; never starts the window manager."""

import re
import shutil
import unittest

from mise_test_support import MISE, REPO, MiseFixture


TARGET = "Library/Application Support/Spaceman/config.toml"
GIT = shutil.which("git")


class SpacemanDeclarationTests(unittest.TestCase):
    def test_macos_declares_the_official_homebrew_cask(self):
        config = (REPO / ".config/mise/config.macos.toml").read_text()
        self.assertIn('"brew-cask:anomalyco/tap/spaceman" = "latest"', config)

    def test_only_macos_selects_spaceman(self):
        for profile in ("macos", "omarchy"):
            config = (REPO / f".config/mise/config.{profile}.toml").read_text()
            selection = re.search(
                r"(?s)\[bootstrap\]\s*dotfile_groups\s*=\s*\[(.*?)\]", config,
            )
            self.assertIsNotNone(selection)
            self.assertEqual(
                "spaceman" in re.findall(r'"([^"]+)"', selection.group(1)),
                profile == "macos",
            )

    def test_config_uses_supported_settings_without_shortcut_overrides(self):
        config = (REPO / "packages/spaceman" / TARGET).read_text()
        settings = [line.strip() for line in config.splitlines()
                    if line.strip() and not line.lstrip().startswith("#")]
        self.assertEqual(settings, [
            "version = 1", "[settings]", "hud = true",
            'hud_style = "icons"', 'update_channel = "dev"',
            'mouse_follows_focus = "window"', "[settings.gaps]",
            "inner = 6", "top = 6", "bottom = 6", "left = 6", "right = 6",
        ])


@unittest.skipUnless(MISE and GIT, "mise and git are required")
class SpacemanDeploymentTests(MiseFixture):
    def setUp(self):
        super().setUp()
        base = (REPO / ".config/mise/config.toml").read_text()
        group = re.search(
            r"(?ms)^\[dotfile_groups\.spaceman\]\n.*?(?=^\[dotfile_groups\.ssh\])",
            base,
        )
        self.assertIsNotNone(group)
        self.write(self.config / "config.toml", (
            '[settings.dotfiles]\nroot = "../../packages"\n'
            'default_mode = "symlink-each"\n\n'
            + group.group()
            + '\n[bootstrap]\ndotfile_groups = ["spaceman"]\n'
        ))
        self.source = self.write(
            self.checkout / "packages/spaceman" / TARGET,
            (REPO / "packages/spaceman" / TARGET).read_text(),
        )
        self.target = self.home / TARGET
        self.assert_success(self.run_command([GIT, "init", "-q"], cwd=self.checkout))
        self.assert_success(self.run_command(
            [GIT, "add", "packages/spaceman"], cwd=self.checkout,
        ))

    def apply(self, dry_run=False, scoped=True):
        arguments = [MISE, "dotfiles", "apply"]
        if dry_run:
            arguments.append("--dry-run")
        if scoped:
            arguments.append(str(self.target))
        result = self.run_command(arguments, cwd=self.checkout)
        self.assert_success(result)

    def test_scoped_deployment_copies_only_config_and_is_repeatable(self):
        recovery = self.write(self.target.parent / "parked-windows.json", "fixture recovery\n")
        untracked = self.write(
            self.source.parent / "agent.log", "fixture log, not deployment input\n",
        )
        self.apply(dry_run=True, scoped=False)
        self.assertFalse(self.target.exists())
        self.apply(scoped=False)
        self.assertFalse(self.target.is_symlink())
        self.assertEqual(self.target.read_bytes(), self.source.read_bytes())
        self.assertEqual(recovery.read_text(), "fixture recovery\n")
        self.assertFalse((self.target.parent / untracked.name).exists())
        self.apply()
        self.assertEqual(self.target.read_bytes(), self.source.read_bytes())

    def test_gui_edits_do_not_change_source_or_get_overwritten_by_preview(self):
        self.apply()
        original = self.source.read_bytes()
        edited = 'version = 1\n[settings]\nhud = false\n'
        replacement = self.target.with_suffix(".tmp")
        replacement.write_text(edited)
        replacement.replace(self.target)
        self.assertEqual(self.source.read_bytes(), original)
        self.apply(dry_run=True)
        self.assertEqual(self.target.read_text(), edited)
        self.assertEqual(self.source.read_bytes(), original)


if __name__ == "__main__":
    unittest.main()
