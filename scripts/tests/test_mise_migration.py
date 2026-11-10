"""Native make-link migration tests in disposable homes, never real provisioning.

The platform fixtures retain the actual shell/editor deployment declarations but
exclude desktop customization and package installation. All tool downloads are
disabled. Git-filtered package sources are read from the checkout without edits.
"""

import os
import re
import shutil
import unittest

from test_shell_policy import BASH, MISE, REPO, ZSH, PolicyFixture


MAKE = shutil.which("make")
STARSHIP = shutil.which("starship")
ZOXIDE = shutil.which("zoxide")


@unittest.skipUnless(MISE and MAKE and BASH, "mise, make and bash are required")
class MiseMigrationTests(PolicyFixture):
    def setUp(self):
        super().setUp()
        sources = (
            "Makefile", "scripts/shared/link.sh", "scripts/shared/utils.sh",
            "scripts/shared/environment.sh", "scripts/shared/detect-os.sh",
            ".config/mise/config.toml", ".config/mise/miserc.toml",
            ".config/mise/global/tools.toml", ".config/mise/global/platform.toml",
            ".config/mise/global/platform.omarchy.toml",
            ".config/mise/global/miserc.toml.tera",
            ".config/mise/conf.d/workspace.toml.example",
            ".config/mise/workspace/opencode.jsonc.example",
            ".config/mise/workspace/miserc.macos.toml",
            ".config/mise/workspace/miserc.omarchy.toml",
        )
        for name in sources:
            self.write(self.checkout / name, (REPO / name).read_text())
        (self.checkout / "packages").symlink_to(REPO / "packages", target_is_directory=True)
        (self.bin / "mise").symlink_to(MISE)
        (self.bin / "bash").symlink_to(BASH)
        self.current_config = (self.config / "config.toml").read_text()

    def table(self, text, header):
        match = re.search(r"(?ms)^\[" + re.escape(header) + r"\]\n.*?(?=^\[|\Z)", text)
        self.assertIsNotNone(match, header)
        return match.group()

    def select_profile(self, profile):
        text = (REPO / f".config/mise/config.{profile}.toml").read_text()
        # Real platform-specific seed and editor target; only relevant groups.
        tables = [self.table(text, "dotfiles.workspace-mise-env")]
        if profile == "omarchy":
            tables += [self.table(text, 'dotfiles."~/.config/mise/conf.d/20-dotfiles-platform.toml"'),
                       self.table(text, "dotfile_groups.nvim")]
        groups = ["bash", "nvim", "scripts", "starship", "tool-versions"]
        if profile == "macos":
            groups.append("zsh")
        tables.append("[bootstrap]\ndotfile_groups = [" +
                      ", ".join(f'"{group}"' for group in groups) + "]\n")
        self.write(self.config / f"config.{profile}.toml", "\n".join(tables))

    def link(self, profile, dry_run=False):
        arguments = [MAKE, "--no-print-directory", "link", f"PROFILE={profile}"]
        if dry_run:
            arguments.append("DOTFILES_ARGS=--dry-run")
        result = self.run_command(arguments, cwd=self.checkout)
        self.assert_success(result)
        return result

    def startup_paths(self, profile):
        names = [".bashrc", ".bash_profile"]
        if profile == "macos":
            names += [".zshenv", ".zshrc"]
        return [self.home / name for name in names]

    def assert_deployed(self, profile):
        for target in self.startup_paths(profile):
            shell = "bash" if target.name.startswith(".bash") else "zsh"
            self.assertTrue(target.is_symlink(), str(target))
            self.assertEqual(target.resolve(), REPO / "packages" / shell / target.name)
        self.assertIn('[".tool-versions"]', self.guard.read_text())
        self.assertTrue((self.home / ".tool-versions").is_symlink())
        editor = "nvim-dotfiles" if profile == "omarchy" else "nvim"
        template = self.home / f".config/{editor}/templates/mise.toml.template"
        self.assertTrue(template.is_file())
        self.assertEqual(template.read_bytes(),
                         (REPO / "packages/nvim/.config/nvim/templates/mise.toml.template").read_bytes())
        self.assertTrue((self.home / ".local/bin/dotf.d/init").is_file())
        self.assertNotIn("$direnv", (self.home / ".config/starship.toml").read_text())

    def exercise_repeatable_deployment(self, profile):
        self.select_profile(profile)
        upstream = self.home / ".config/nvim/init.lua"
        if profile == "omarchy":
            self.write(upstream, "-- upstream config, preserve\n")
        self.link(profile, dry_run=True)
        self.assertFalse(self.guard.exists())
        for target in self.startup_paths(profile):
            self.assertFalse(target.exists())
        self.link(profile)
        self.assert_deployed(profile)
        originals = {path: (os.readlink(path), path.lstat().st_ino)
                     for path in self.startup_paths(profile)}
        self.link(profile)
        self.assert_deployed(profile)
        for path, (link, inode) in originals.items():
            self.assertEqual(os.readlink(path), link)
            self.assertEqual(path.lstat().st_ino, inode)
        # Model the reported missing startup files, then repair through unscoped link.
        for target in self.startup_paths(profile):
            target.unlink()
        self.link(profile)
        self.assert_deployed(profile)
        if profile == "omarchy":
            self.assertEqual(upstream.read_text(), "-- upstream config, preserve\n")

    def test_macos_full_link_is_repeatable_and_repairs_missing_startup_files(self):
        self.exercise_repeatable_deployment("macos")

    def test_omarchy_full_link_preserves_upstream_editor_and_repairs_bash_startup(self):
        self.exercise_repeatable_deployment("omarchy")

    def deploy_legacy_configuration(self, profile):
        # Representative asdf/direnv predecessor: disabled discovery, managed
        # shell-policy file, and an asdf dotfile group. No legacy hooks are run.
        self.write(self.config / "legacy-miserc.tera", "override_tool_versions_filenames = []\n")
        self.write(self.config / "legacy-policy.tera",
                   "DOTFILES_RUNTIME_MANAGER=asdf\nDOTFILES_ENVIRONMENT_LOADER=direnv\n")
        self.write(self.config / "miserc.toml", "override_tool_versions_filenames = []\n")
        tables = [
            '[settings.dotfiles]\nroot = "../../packages"\ndefault_mode = "symlink-each"\n',
            '[dotfiles."~/.config/mise/miserc.toml"]\nsource = "legacy-miserc.tera"\nmode = "template"\n',
            '[dotfiles."~/.config/dotfiles/shell-policy.sh"]\n'
            'source = "legacy-policy.tera"\nmode = "template"\n',
            '[dotfile_groups.asdf]\nroot = "asdf"\nmanifest = "git"\n',
        ]
        groups = ["asdf", "bash"] + (["zsh"] if profile == "macos" else [])
        for group in groups[1:]:
            tables.append(self.table(self.current_config, f"dotfile_groups.{group}"))
            # Old startup links used the same paths, before helper dependencies.
            entries = self.table(self.current_config, f"dotfile_groups.{group}.entries")
            tables.append(re.sub(r', depends = \[[^\]]*\]', "", entries))
        tables.append("[bootstrap]\ndotfile_groups = [" +
                      ", ".join(f'"{group}"' for group in groups) + "]\n")
        self.write(self.config / "config.toml", "\n".join(tables))
        result = self.run_command([MISE, "dotfiles", "apply"], cwd=self.checkout)
        self.assert_success(result)
        self.assertIn("= []", self.guard.read_text())
        self.assertTrue(self.policy.is_file())
        self.assertTrue((self.home / ".asdf-direnv.sh").is_file())

    def exercise_legacy_migration(self, profile):
        self.deploy_legacy_configuration(profile)
        preserved = {
            self.policy: self.policy.read_bytes(),
            self.home / ".asdfrc": (self.home / ".asdfrc").read_bytes(),
            self.home / ".asdf-direnv.sh": (self.home / ".asdf-direnv.sh").read_bytes(),
        }
        for path, content in (
            (self.home / ".asdf/installs/nodejs/legacy/bin/node", "# retained runtime\n"),
            (self.home / ".zshrc.local", "# personal startup\n"),
            (self.home / ".bashrc.local", "# personal startup\n"),
            (self.outside / ".envrc", "export APP_MODE=legacy\n"),
            (self.guard.parent / "config.local.toml", "# personal mise settings\n"),
            (self.config / "config.local.toml", '[vars]\ndotfiles_runtime_manager = "asdf"\n'),
        ):
            preserved[path] = self.write(path, content).read_bytes()
        self.write(self.config / "config.toml", self.current_config)
        self.write(self.config / "miserc.toml", (REPO / ".config/mise/miserc.toml").read_text())
        self.select_profile(profile)
        self.link(profile)
        self.assert_deployed(profile)
        self.link(profile)
        self.assert_deployed(profile)
        for path, content in preserved.items():
            self.assertEqual(path.read_bytes(), content, str(path))

    def test_legacy_macos_migration_preserves_runtime_data_and_local_settings(self):
        self.exercise_legacy_migration("macos")

    def test_legacy_omarchy_migration_preserves_runtime_data_and_local_settings(self):
        self.exercise_legacy_migration("omarchy")

    def test_full_link_does_not_overwrite_a_conflicting_personal_zshrc(self):
        self.select_profile("macos")
        startup = self.write(self.home / ".zshrc", "# personal, not managed\n")
        result = self.run_command([MAKE, "link", "PROFILE=macos"], cwd=self.checkout)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(startup.is_symlink())
        self.assertEqual(startup.read_text(), "# personal, not managed\n")

    def test_scaffolder_consumes_native_deployed_editor_templates(self):
        self.select_profile("macos")
        self.link("macos")
        script = self.home / ".local/bin/dotf.d/init"
        result = self.run_command([BASH, str(script), "--all"])
        self.assert_success(result)
        self.assertTrue((self.outside / "mise.toml").is_file())
        self.assertFalse((self.outside / ".envrc").exists())
        self.assertIn("mise trust", result.stdout)

    @unittest.skipUnless(ZSH and STARSHIP and ZOXIDE, "zsh, starship and zoxide are required")
    def test_deployed_zsh_initializes_native_mise_starship_and_zoxide(self):
        self.select_profile("macos")
        self.link("macos")
        for name, binary in (("starship", STARSHIP), ("zoxide", ZOXIDE)):
            (self.bin / name).symlink_to(binary)
        self.write(self.bin / "fzf", "#!/bin/sh\nexit 0\n", True)
        self.write(self.bin / "brew", '#!/bin/sh\nprintf "%s\\n" "$HOME/brew"\n', True)
        self.write(self.home / "brew/share/zsh-autosuggestions/zsh-autosuggestions.zsh", "# fixture\n")
        # Exercise installed hook generators, not language installation. Runtime
        # selection has separate synthetic-runtime coverage in test_shell_policy.
        self.write(self.guard.parent / "config.toml", "[settings]\nenable_tools = []\n")
        self.env["TERM"] = "xterm-256color"
        result = self.run_command([
            ZSH, "-d", "-i", "-c",
            '[[ "$STARSHIP_SHELL" == zsh ]] && print __STARSHIP__yes; '
            '(( $+functions[z] )) && print __ZOXIDE__yes; '
            '(( $+functions[_mise_hook_precmd] )) && print __MISE__yes',
        ])
        self.assert_success(result)
        self.assertEqual(result.stdout.splitlines(), ["__STARSHIP__yes", "__ZOXIDE__yes", "__MISE__yes"])
        self.assertEqual(result.stderr, "")


if __name__ == "__main__":
    unittest.main()
