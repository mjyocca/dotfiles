"""Machine policy deployment and actual startup files, isolated from the host.

Native mise tests never install tools or use the real HOME. Startup tests stub
optional commands and simulate Omarchy's upstream mise initialization.
"""

import errno
import fcntl
import json
import os
from pathlib import Path
import pty
import re
import select
import shlex
import shutil
import subprocess
import tempfile
import termios
import time
import unittest


REPO = Path(__file__).resolve().parents[2]
MISE = shutil.which("mise")
DIRENV = shutil.which("direnv")
ZSH = shutil.which("zsh")
BASH = shutil.which("bash")
MODES = (("asdf", "direnv"), ("mise", "direnv"), ("mise", "mise"))


class InteractiveSession:
    """Wait for an acknowledged command and its subsequent interactive prompt."""

    def __init__(self, arguments, cwd, env):
        self.master, slave = pty.openpty()
        attributes = termios.tcgetattr(slave)
        attributes[3] &= ~termios.ECHO
        termios.tcsetattr(slave, termios.TCSANOW, attributes)

        def child_setup():
            os.setsid()
            fcntl.ioctl(0, termios.TIOCSCTTY, 0)

        self.process = subprocess.Popen(arguments, cwd=cwd, env=env, stdin=slave,
                                        stdout=slave, stderr=slave, preexec_fn=child_setup)
        os.close(slave)
        self.sequence = 0
        try:
            self.command("PS1='__POLICY_PROMPT__ '; PS2=''; PROMPT_EOL_MARK=''")
        except Exception:
            self.close()
            raise

    def command(self, text):
        self.sequence += 1
        acknowledgement = f"__POLICY_ACK_{self.sequence}__".encode()
        os.write(self.master, (text + "; printf '%s\\n' " +
                              shlex.quote(acknowledgement.decode()) + "\n").encode())
        deadline = time.monotonic() + 15
        output = bytearray()
        while time.monotonic() < deadline:
            if not select.select([self.master], [], [], max(0, deadline - time.monotonic()))[0]:
                break
            try:
                chunk = os.read(self.master, 65536)
            except OSError as error:
                if error.errno != errno.EIO:
                    raise
                chunk = b""
            if not chunk:
                raise RuntimeError("Fixture shell exited: " + output.decode(errors="replace"))
            output.extend(chunk)
            clean = re.sub(rb"\x1b\[[0-?]*[ -/]*[@-~]", b"", bytes(output))
            acknowledged = acknowledgement + b"\n" in clean or acknowledgement + b"\r\n" in clean
            if acknowledged and clean.endswith(b"__POLICY_PROMPT__ "):
                return clean.decode(errors="replace")
        raise RuntimeError("Fixture prompt timeout: " + output.decode(errors="replace"))

    def close(self):
        os.close(self.master)
        if self.process.poll() is None:
            self.process.kill()
        self.process.wait(timeout=5)


class PolicyFixture(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="dotfiles-shell-policy-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name).resolve()
        self.home = self.root / "home with spaces"
        self.home.mkdir()
        self.checkout = self.home / "checkout"
        self.config = self.checkout / ".config/mise"
        self.config.mkdir(parents=True)
        self.policy = self.home / ".config/dotfiles/shell-policy.sh"
        self.runtime_helper = self.home / ".config/dotfiles/runtime-path.sh"
        self.guard = self.home / ".config/mise/miserc.toml"
        self.guard.parent.mkdir(parents=True)
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
            "MISE_CONFIG_DIR": str(self.guard.parent),
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


@unittest.skipUnless(MISE, "mise is required")
class PolicyDeploymentTests(PolicyFixture):
    def setUp(self):
        super().setUp()
        text = (REPO / ".config/mise/config.toml").read_text()
        # Exercise the actual declarations and templates, without loading the
        # host's provisioning/tool requests or deploying any shell groups.
        tables = []
        for header in ('vars', 'dotfiles."~/.config/dotfiles/shell-policy.sh"',
                       'dotfiles."~/.config/mise/miserc.toml"'):
            table = re.search(r"(?ms)^\[" + re.escape(header) + r"\]\n.*?(?=^\[|\Z)", text)
            self.assertIsNotNone(table)
            tables.append(table.group())
        self.declarations = "\n".join(tables)
        self.write(self.config / "config.toml", self.declarations)
        shutil.copytree(REPO / ".config/mise/global", self.config / "global")
        self.local = self.config / "config.local.toml"

    def mise(self, *arguments, cwd=None):
        return self.run_command([MISE, *arguments], cwd=cwd or self.checkout)

    def select(self, runtime, loader):
        self.write(self.local, '[vars]\n'
                   f'dotfiles_runtime_manager = "{runtime}"\n'
                   f'dotfiles_environment_loader = "{loader}"\n')

    def apply(self):
        # Native depends orders selected entries; it does not expand target scope.
        self.assert_success(self.mise("dotfiles", "apply", str(self.policy), str(self.guard)))

    def test_modes_render_consistent_policy_and_discovery_then_restore_defaults(self):
        project = self.home / "project"
        project.mkdir()
        self.write(project / ".tool-versions", "nodejs 24.0.0\n")
        for runtime, loader in MODES:
            with self.subTest(runtime=runtime, loader=loader):
                self.select(runtime, loader)
                result = self.mise("vars", "dotfiles_runtime_manager")
                self.assert_success(result)
                self.assertEqual(result.stdout.strip(), runtime)
                before = self.local.read_bytes()
                self.apply()
                self.assertEqual(self.local.read_bytes(), before)
                result = self.run_command(["/bin/sh", "-c",
                    '. "$HOME/.config/dotfiles/shell-policy.sh"; '
                    'printf "%s %s" "$DOTFILES_RUNTIME_MANAGER" "$DOTFILES_ENVIRONMENT_LOADER"'])
                self.assert_success(result)
                self.assertEqual(result.stdout, f"{runtime} {loader}")
                self.assertEqual(self.policy.stat().st_mode & 0o777, 0o600)
                result = self.mise("ls", "--current", "--json", cwd=project)
                self.assert_success(result)
                self.assertEqual("node" in json.loads(result.stdout), runtime == "mise")
                # Explicit TOML tools remain discoverable in every mode.
                self.write(project / "mise.toml", '[tools]\npython = "3.13.0"\n')
                result = self.mise("ls", "--current", "--json", cwd=project)
                self.assert_success(result)
                self.assertIn("python", json.loads(result.stdout))
                (project / "mise.toml").unlink()
        self.local.unlink()
        self.apply()
        self.assertIn("DOTFILES_RUNTIME_MANAGER=asdf", self.policy.read_text().replace("'", ""))
        self.assertIn("DOTFILES_ENVIRONMENT_LOADER=direnv", self.policy.read_text().replace("'", ""))
        self.assertIn("= []", self.guard.read_text())

    def test_runtime_only_override_preserves_default_environment_loader(self):
        self.write(self.local, '[vars]\ndotfiles_runtime_manager = "mise"\n')
        self.apply()
        result = self.run_command(["/bin/sh", "-c",
            '. "$HOME/.config/dotfiles/shell-policy.sh"; '
            'printf "%s %s" "$DOTFILES_RUNTIME_MANAGER" "$DOTFILES_ENVIRONMENT_LOADER"'])
        self.assert_success(result)
        self.assertEqual(result.stdout, "mise direnv")
        self.assertIn('[".tool-versions"]', self.guard.read_text())
        result = self.mise("vars", "dotfiles_environment_loader")
        self.assert_success(result)
        self.assertEqual(result.stdout.strip(), "direnv")

    def test_invalid_modes_fail_rendering_before_writing_targets(self):
        for runtime, loader in (("typo", "direnv"), ("mise", "legacy"), ("asdf", "mise"),
                                ("mise", "$(touch unexpected)")):
            with self.subTest(runtime=runtime, loader=loader):
                self.select(runtime, loader)
                for target in (self.policy, self.guard):
                    result = self.mise("dotfiles", "apply", str(target))
                    self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertFalse(self.policy.exists())
                self.assertFalse(self.guard.exists())

    def test_invalid_selection_does_not_change_previously_deployed_policy(self):
        self.select("mise", "direnv")
        self.apply()
        before = {path: path.read_bytes() for path in (self.policy, self.guard)}
        self.select("asdf", "mise")
        result = self.mise("dotfiles", "apply", str(self.policy), str(self.guard))
        self.assertNotEqual(result.returncode, 0)
        for path, content in before.items():
            self.assertEqual(path.read_bytes(), content)

    def test_dry_run_does_not_deploy_or_modify_existing_global_overrides(self):
        originals = {}
        for name in ("config.toml", "config.local.toml", "miserc.local.toml"):
            path = self.guard.parent / name
            originals[path] = self.write(path, "# machine-owned\n").read_bytes()
        self.select("mise", "mise")
        self.assert_success(self.mise("dotfiles", "apply", "--dry-run", str(self.guard)))
        self.assertFalse(self.policy.exists())
        self.assertFalse(self.guard.exists())
        self.apply()
        for path, content in originals.items():
            self.assertEqual(path.read_bytes(), content)

    def test_complete_platform_declarations_preview_policy_without_deployment(self):
        shutil.copyfile(REPO / ".config/mise/config.toml", self.config / "config.toml")
        (self.checkout / "packages").symlink_to(REPO / "packages", target_is_directory=True)
        for folder in ("workspace", "omarchy"):
            shutil.copytree(REPO / ".config/mise" / folder, self.config / folder)
        (self.config / "conf.d").mkdir()
        shutil.copyfile(REPO / ".config/mise/conf.d/workspace.toml.example",
                        self.config / "conf.d/workspace.toml.example")
        for profile in ("macos", "omarchy"):
            shutil.copyfile(REPO / f".config/mise/config.{profile}.toml",
                            self.config / f"config.{profile}.toml")
            self.select("mise", "mise")
            shell_targets = [str(self.home / ".bashrc")]
            if profile == "macos":
                shell_targets += [str(self.home / ".zshenv"), str(self.home / ".zshrc")]
            result = self.mise("-E", profile, "dotfiles", "apply", "--dry-run",
                               str(self.policy), str(self.guard), str(self.runtime_helper), *shell_targets)
            self.assert_success(result)
            self.assertNotIn("unknown field", result.stderr)
            self.assertNotIn("ignoring group", result.stderr)
            self.assertIn("ln -sf", result.stdout)
            self.assertIn(" ~/.bashrc", result.stdout)
            self.assertLess(result.stdout.index("shell-policy.sh (if changed)"),
                            result.stdout.index(" ~/.bashrc"))
            self.assertLess(result.stdout.index(" ~/.config/dotfiles/runtime-path.sh"),
                            result.stdout.index(" ~/.bashrc"))
            self.assertFalse(self.policy.exists())
            self.assertFalse(self.guard.exists())
            self.assertFalse(self.runtime_helper.exists())
            self.assertFalse((self.home / ".bashrc").exists())

    def test_runtime_helper_is_deployed_as_a_symlink_after_policy_outputs(self):
        text = (REPO / ".config/mise/config.toml").read_text()
        declaration = re.search(
            r'(?ms)^\[dotfiles\."~/.config/dotfiles/runtime-path.sh"\]\n.*?(?=^\[|\Z)', text
        )
        self.assertIsNotNone(declaration)
        self.write(self.config / "config.toml", self.declarations + "\n" + declaration.group())
        source = self.checkout / "packages/shell/.config/dotfiles/runtime-path.sh"
        self.write(source, (REPO / "packages/shell/.config/dotfiles/runtime-path.sh").read_text())
        self.select("mise", "direnv")
        result = self.mise("dotfiles", "apply", str(self.runtime_helper), str(self.policy), str(self.guard))
        self.assert_success(result)
        self.assertTrue(self.runtime_helper.is_symlink())
        self.assertEqual(self.runtime_helper.resolve(), source)
        self.assertTrue(self.policy.exists())
        self.assertTrue(self.guard.exists())

    def test_managed_guard_symlink_migrates_without_editing_original_source(self):
        source = self.write(self.config / "old-guard.toml", "override_tool_versions_filenames = []\n")
        self.write(self.config / "config.toml", '[dotfiles."~/.config/mise/miserc.toml"]\n'
                   'source = "old-guard.toml"\nmode = "symlink"\n')
        self.assert_success(self.mise("dotfiles", "apply", str(self.guard)))
        self.assertTrue(self.guard.is_symlink())
        before = source.read_bytes()
        self.write(self.config / "config.toml", self.declarations)
        self.select("mise", "direnv")
        self.apply()
        self.assertFalse(self.guard.is_symlink())
        self.assertIn('[".tool-versions"]', self.guard.read_text())
        self.assertEqual(source.read_bytes(), before)


class ShellStartupTests(PolicyFixture):
    def setUp(self):
        super().setUp()
        self.write(self.runtime_helper, (REPO / "packages/shell/.config/dotfiles/runtime-path.sh").read_text())
        for shell, names in (("bash", (".bashrc", ".bash_profile")),
                             ("zsh", (".zshrc", ".zshenv"))):
            for name in names:
                shutil.copyfile(REPO / "packages" / shell / name, self.home / name)
        self.write(self.bin / "mise", '#!/bin/sh\n'
                   'printf "mise %s\\n" "$*" >> "$TEST_LOG"\n'
                   'case "$*" in\n'
                   '  "activate bash"|"activate zsh") printf "_mise_test_hook() { :; }\\n" ;;\n'
                   '  "activate bash --shims"|"activate zsh --shims") '
                   'printf \'case "$PATH:" in "%s/shims:"*) ;; *) '
                   'export PATH="%s/shims:$PATH" ;; esac\\n\' "$MISE_DATA_DIR" "$MISE_DATA_DIR" ;;\n'
                   '  *) exit 91 ;;\nesac\n', True)
        self.write(self.bin / "direnv", '#!/bin/sh\n'
                   'printf "direnv %s\\n" "$*" >> "$TEST_LOG"\n'
                   'printf "_direnv_test_hook() { :; }\\n"\n', True)
        for name in ("starship", "fzf", "zoxide"):
            self.write(self.bin / name, "#!/bin/sh\nexit 0\n", True)
        self.write(self.bin / "brew", '#!/bin/sh\nprintf "%s\\n" "$HOME/brew"\n', True)
        self.write(self.home / "brew/share/zsh-autosuggestions/zsh-autosuggestions.zsh", "# stub\n")
        for runtime, folder in (("asdf", ".asdf/shims"), ("mise", ".local/share/mise/shims")):
            self.write(self.home / folder / "node", f"#!/bin/sh\necho {runtime}\n", True)
        self.write(self.home / ".asdf/plugins/golang/set-env.zsh",
                   'export ASDF_PLUGIN_LOADED=yes\n')

    def select(self, runtime, loader):
        self.write(self.policy, f"DOTFILES_RUNTIME_MANAGER={runtime}\nDOTFILES_ENVIRONMENT_LOADER={loader}\n")

    def startup(self, shell, command, interactive=True, login=False):
        if shell == "bash":
            arguments = [BASH, "--noprofile", "--norc"]
            if interactive:
                arguments.append("-i")
            # Explicitly source the real login entrypoint to avoid host /etc/profile.
            entry = ".bash_profile" if login else ".bashrc"
            arguments += ["-c", f'source "$HOME/{entry}"; ' + command]
        else:
            arguments = [ZSH, "-d"]
            if interactive:
                arguments.append("-i")
            if login:
                arguments.append("-l")
            arguments += ["-c", command]
        result = self.run_command(arguments)
        # Interactive Bash without a PTY emits these two expected diagnostics.
        # Every other startup diagnostic is a failure, even if a later command
        # succeeds and masks the source error in the process exit status.
        expected_bash_warning = re.compile(
            r"bash: (cannot set terminal process group \(-?\d+\): "
            r"Inappropriate ioctl for device|no job control in this shell)"
        )
        unexpected = [line for line in result.stderr.splitlines()
                      if shell != "bash" or not expected_bash_warning.fullmatch(line)]
        self.assertEqual(unexpected, [], result.stderr)
        return result

    def test_interactive_and_login_startup_register_only_selected_loader(self):
        for shell, available in (("bash", BASH), ("zsh", ZSH)):
            if not available:
                continue
            for runtime, loader in MODES:
                for login in (False, True):
                    with self.subTest(shell=shell, runtime=runtime, loader=loader, login=login):
                        self.select(runtime, loader)
                        self.log.unlink(missing_ok=True)
                        result = self.startup(shell, 'node; printf "PLUGIN:%s\\n" "${ASDF_PLUGIN_LOADED:-no}"', login=login)
                        self.assert_success(result)
                        self.assertIn(runtime + "\n", result.stdout)
                        events = self.log.read_text().splitlines()
                        activation = f"mise activate {shell}" + (" --shims" if loader == "direnv" else "")
                        self.assertEqual(events, [activation] + ([f"direnv hook {shell}"] if loader == "direnv" else []))
                        if shell == "zsh":
                            self.assertIn("PLUGIN:" + ("yes" if runtime == "asdf" else "no"), result.stdout)

    def test_missing_policy_falls_back_to_asdf_and_direnv(self):
        for shell, available in (("bash", BASH), ("zsh", ZSH)):
            if not available:
                continue
            with self.subTest(shell=shell):
                result = self.startup(shell, "node")
                self.assert_success(result)
                self.assertEqual(result.stdout.strip(), "asdf")

    def test_missing_helper_preserves_inherited_runtime_path_without_source_errors(self):
        self.runtime_helper.unlink()
        self.env["PATH"] = str(self.home / ".asdf/shims") + ":" + self.env["PATH"]
        for shell, available in (("bash", BASH), ("zsh", ZSH)):
            if not available:
                continue
            with self.subTest(shell=shell):
                result = self.startup(shell, "node", interactive=False)
                self.assert_success(result)
                self.assertEqual(result.stdout.strip(), "asdf")

    @unittest.skipUnless(BASH, "bash is required")
    def test_omarchy_path_without_bootstrap_does_not_skip_standalone_activation(self):
        self.env["OMARCHY_PATH"] = str(self.root / "not-an-omarchy-installation")
        self.select("mise", "direnv")
        result = self.startup("bash", "node")
        self.assert_success(result)
        self.assertEqual(result.stdout.strip(), "mise")
        self.assertEqual(self.log.read_text().splitlines(),
                         ["mise activate bash --shims", "direnv hook bash"])

    def test_noninteractive_startup_has_runtime_shims_but_no_hooks(self):
        for shell, available in (("bash", BASH), ("zsh", ZSH)):
            if not available:
                continue
            for runtime, loader in MODES:
                with self.subTest(shell=shell, runtime=runtime, loader=loader):
                    self.select(runtime, loader)
                    self.log.unlink(missing_ok=True)
                    result = self.startup(shell, "node", interactive=False)
                    self.assert_success(result)
                    self.assertEqual(result.stdout.strip(), runtime)
                    self.assertFalse(self.log.exists())

    def test_late_shell_local_overrides_remain_last(self):
        for shell, available in (("bash", BASH), ("zsh", ZSH)):
            if not available:
                continue
            self.write(self.home / f".{shell}rc.local", 'export PATH="$HOME/custom:$PATH"\n')
            self.write(self.home / "custom/node", "#!/bin/sh\necho local\n", True)
            result = self.startup(shell, "node")
            self.assert_success(result)
            self.assertEqual(result.stdout.strip(), "local")

    def test_inherited_runtime_paths_are_reordered_without_adding_duplicates(self):
        shims = {"asdf": str(self.home / ".asdf/shims"),
                 "mise": str(self.home / ".local/share/mise/shims")}
        original_path = self.env["PATH"]
        for shell, available in (("bash", BASH), ("zsh", ZSH)):
            if not available:
                continue
            for runtime, loader in MODES:
                other = "asdf" if runtime == "mise" else "mise"
                inherited = [shims[other], shims[runtime], "", shims[runtime], *original_path.split(":")]
                for interactive in (False, True):
                    with self.subTest(shell=shell, runtime=runtime, loader=loader, interactive=interactive):
                        self.select(runtime, loader)
                        self.env["PATH"] = ":".join(inherited)
                        # Re-read the early file too: repeated initialization
                        # must not accumulate selected-runtime shim entries.
                        entry = ".bashrc" if shell == "bash" else ".zshenv"
                        command = f'source "$HOME/{entry}"; node; printf "__PATH__%s\\n" "$PATH"'
                        result = self.startup(shell, command, interactive=interactive)
                        self.assert_success(result)
                        self.assertEqual(result.stdout.splitlines()[0], runtime)
                        path = next(line[len("__PATH__"):] for line in result.stdout.splitlines()
                                    if line.startswith("__PATH__")).split(":")
                        self.assertEqual(path.count(shims[runtime]), 1)
                        self.assertLess(path.index(shims[runtime]), path.index(shims[other]))
                        self.assertEqual(path.count(""), 1)

    def test_runtime_shim_directory_names_are_matched_literally(self):
        original_path = self.env["PATH"]
        for runtime, variable in (("asdf", "ASDF_DATA_DIR"), ("mise", "MISE_DATA_DIR")):
            data = self.home / f"{runtime} [custom]"
            self.write(data / "shims/node", f"#!/bin/sh\necho {runtime}\n", True)
            self.env[variable] = str(data)
            self.select(runtime, "direnv")
            for shell, available in (("bash", BASH), ("zsh", ZSH)):
                if not available:
                    continue
                with self.subTest(runtime=runtime, shell=shell):
                    self.env["PATH"] = f"{original_path}:{data}/shims:{data}/shims"
                    result = self.startup(shell, 'node; printf "__PATH__%s\\n" "$PATH"')
                    self.assert_success(result)
                    self.assertEqual(result.stdout.splitlines()[0], runtime)
                    path = result.stdout.split("__PATH__", 1)[1].strip().split(":")
                    self.assertEqual(path.count(str(data / "shims")), 1)

    def prepare_omarchy_defaults(self):
        omarchy = self.root / "omarchy"
        self.write(omarchy / "default/bash/env-bootstrap", "# upstream environment fixture\n")
        self.write(omarchy / "default/bash/rc",
                   'command -v mise >/dev/null && eval "$(mise activate bash)"\n'
                   'declare OMARCHY_DEFAULTS_LOADED=yes\n')
        return omarchy

    @unittest.skipUnless(BASH, "bash is required")
    def test_omarchy_upstream_activation_obeys_policy_without_leaking_wrapper(self):
        omarchy = self.prepare_omarchy_defaults()
        self.env["OMARCHY_PATH"] = str(omarchy)
        for runtime, loader in MODES:
            with self.subTest(runtime=runtime, loader=loader):
                self.select(runtime, loader)
                self.log.unlink(missing_ok=True)
                result = self.startup("bash", 'node; printf "OMARCHY:%s\\n" "$OMARCHY_DEFAULTS_LOADED"; '
                                      'declare -F mise; declare -p _dotfiles_previous_mise 2>/dev/null; true')
                self.assert_success(result)
                self.assertEqual(result.stdout, runtime + "\nOMARCHY:yes\n")
                activation = "mise activate bash" + (" --shims" if loader == "direnv" else "")
                self.assertEqual(self.log.read_text().splitlines(), [activation] +
                                 (["direnv hook bash"] if loader == "direnv" else []))

    def prepare_native_projects(self):
        for name, binary in (("mise", MISE), ("direnv", DIRENV)):
            (self.bin / name).unlink()
            (self.bin / name).symlink_to(binary)
        (self.home / ".local/share/mise/shims/node").unlink()
        install = self.root / "synthetic-node"
        self.write(install / "bin/node", "#!/bin/sh\necho mise\n", True)
        self.assert_success(self.run_command([MISE, "link", "node@24.0.0", str(install)]))
        self.env.update(APP_MODE="original", DIRENV_LOG_FORMAT="", MISE_NOT_FOUND_AUTO_INSTALL="0")
        first, second = self.home / "project-a", self.home / "project-b"
        # These files must be ignored in mise-only mode, even though approved.
        for project, value in ((first, "a"), (second, "b")):
            self.write(project / ".envrc", f"export APP_MODE={value}\n")
            self.write(project / ".tool-versions", "nodejs 24.0.0\n")
            self.assert_success(self.run_command([DIRENV, "allow", str(project)]))
        return first, second

    def configure_native_mode(self, runtime, loader, projects):
        self.select(runtime, loader)
        self.write(self.guard, "override_tool_versions_filenames = " +
                   ('[".tool-versions"]\n' if runtime == "mise" else "[]\n"))
        global_tools = '[tools]\nnode = "24.0.0"\n' if runtime == "mise" else ""
        self.write(self.guard.parent / "config.toml", global_tools +
                   "[settings]\nnot_found_auto_install = false\n")
        for project, value in zip(projects, ("a", "b")):
            # In direnv mode these [env] keys must not reach the shell.
            mise_value = value if loader == "mise" else "must-not-load"
            self.write(project / "mise.toml", f'[env]\nAPP_MODE = "{mise_value}"\n')

    def assert_active_hooks(self, session, shell, loader):
        mise_hook = "_mise_hook_precmd" if shell == "zsh" else "_mise_hook_prompt_command"
        output = session.command(
            'if typeset -f _direnv_hook >/dev/null; then echo __DIRENV__yes; '
            'else echo __DIRENV__no; fi; '
            f'if typeset -f {mise_hook} >/dev/null; then echo __MISE__yes; '
            'else echo __MISE__no; fi')
        self.assertIn("__DIRENV__" + ("yes" if loader == "direnv" else "no") + "\r\n", output)
        self.assertIn("__MISE__" + ("yes" if loader == "mise" else "no") + "\r\n", output)

    def assert_project_state(self, session, folder, value, runtime):
        session.command("cd " + shlex.quote(str(folder)))
        output = session.command('printf "__VALUE__%s\\n" "$APP_MODE"; '
                                 'printf "__RUNTIME__"; node')
        self.assertIn("__VALUE__" + value + "\r\n", output)
        self.assertIn("__RUNTIME__" + runtime + "\r\n", output)

    @unittest.skipUnless(MISE and DIRENV and BASH and ZSH, "native mise, direnv, Bash and Zsh are required")
    def test_native_single_loader_restores_shared_keys_across_sibling_projects(self):
        # Real generators and prompt callbacks, actual repository startup files,
        # synthetic runtime binaries, and no host prompt/plugins or credentials.
        first, second = self.prepare_native_projects()
        omarchy = self.prepare_omarchy_defaults()
        for shell in ("bash", "zsh", "omarchy"):
            if shell == "omarchy":
                self.env["OMARCHY_PATH"] = str(omarchy)
            else:
                self.env.pop("OMARCHY_PATH", None)
            for runtime, loader in MODES:
                with self.subTest(shell=shell, runtime=runtime, loader=loader):
                    self.configure_native_mode(runtime, loader, (first, second))
                    arguments = ([BASH, "--noprofile", "--rcfile", str(self.home / ".bashrc"), "-i"]
                                 if shell != "zsh" else [ZSH, "-d", "-i"])
                    session = InteractiveSession(arguments, self.outside, self.env)
                    try:
                        self.assert_active_hooks(session, shell, loader)
                        for folder, expected in ((first, "a"), (second, "b"), (first, "a"),
                                                 (self.outside, "original"), (second, "b"),
                                                 (self.outside, "original")):
                            self.assert_project_state(session, folder, expected, runtime)
                    finally:
                        session.close()


if __name__ == "__main__":
    unittest.main()
