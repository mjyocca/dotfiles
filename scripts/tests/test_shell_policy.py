"""Mise deployment, project templates and actual startup files, isolated from the host.

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
ZSH = shutil.which("zsh")
BASH = shutil.which("bash")


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
        # Exercise the actual declarations, without loading the
        # host's provisioning/tool requests or deploying any shell groups.
        tables = []
        for header in ('dotfiles."~/.config/mise/miserc.toml"',):
            table = re.search(r"(?ms)^\[" + re.escape(header) + r"\]\n.*?(?=^\[|\Z)", text)
            self.assertIsNotNone(table)
            tables.append(table.group())
        self.declarations = "\n".join(tables)
        self.write(self.config / "config.toml", self.declarations)
        shutil.copytree(REPO / ".config/mise/global", self.config / "global")
        (self.checkout / "packages").symlink_to(REPO / "packages", target_is_directory=True)
        self.local = self.config / "config.local.toml"

    def mise(self, *arguments, cwd=None):
        return self.run_command([MISE, *arguments], cwd=cwd or self.checkout)

    def apply(self):
        self.assert_success(self.mise("dotfiles", "apply", str(self.guard)))

    def test_mise_discovers_tool_versions_and_explicit_toml_tools(self):
        project = self.home / "project"
        project.mkdir()
        self.write(project / ".tool-versions", "nodejs 24.0.0\n")
        self.apply()
        self.write(project / "mise.toml", '[tools]\npython = "3.13.0"\n')
        result = self.mise("ls", "--current", "--json", cwd=project)
        self.assert_success(result)
        self.assertEqual(set(json.loads(result.stdout)), {"node", "python"})
        self.assertFalse(self.policy.exists())

    def test_checkout_and_global_discovery_policies_agree(self):
        self.assertEqual(
            (REPO / ".config/mise/miserc.toml").read_text().splitlines()[-1],
            (REPO / ".config/mise/global/miserc.toml.tera").read_text().splitlines()[-1],
        )

    def test_tracked_runtime_requests_are_discovered_without_installation(self):
        source = (REPO / "packages/tool-versions/.tool-versions").read_text()
        self.write(self.home / ".tool-versions", source)
        self.apply()
        result = self.mise("ls", "--current", "--json", cwd=self.outside)
        self.assert_success(result)
        aliases = {"nodejs": "node", "golang": "go"}
        expected = {}
        for line in source.splitlines():
            name, version = line.split()
            expected[aliases.get(name, name)] = version
        tools = json.loads(result.stdout)
        self.assertEqual({name: versions[0]["requested_version"] for name, versions in tools.items()}, expected)
        self.assertFalse(any(version["installed"] for versions in tools.values() for version in versions))

    def test_discovery_replaces_a_previous_disabled_policy(self):
        project = self.home / "project"
        self.write(project / ".tool-versions", "nodejs 24.0.0\n")
        self.write(self.guard, "override_tool_versions_filenames = []\n")
        result = self.mise("ls", "--current", "--json", cwd=project)
        self.assert_success(result)
        self.assertNotIn("node", json.loads(result.stdout))
        self.apply()
        result = self.mise("ls", "--current", "--json", cwd=project)
        self.assert_success(result)
        self.assertIn("node", json.loads(result.stdout))

    def test_obsolete_local_preferences_do_not_change_mise_ownership(self):
        self.write(self.local, '[vars]\ndotfiles_runtime_manager = "asdf"\n'
                   'dotfiles_environment_loader = "direnv"\n')
        before = self.local.read_bytes()
        self.apply()
        self.assertEqual(self.local.read_bytes(), before)
        self.assertIn('[".tool-versions"]', self.guard.read_text())

    def test_dry_run_does_not_deploy_or_modify_existing_global_overrides(self):
        originals = {}
        for name in ("config.toml", "config.local.toml", "miserc.local.toml"):
            path = self.guard.parent / name
            originals[path] = self.write(path, "# machine-owned\n").read_bytes()
        self.assert_success(self.mise("dotfiles", "apply", "--dry-run", str(self.guard)))
        self.assertFalse(self.policy.exists())
        self.assertFalse(self.guard.exists())
        self.apply()
        for path, content in originals.items():
            self.assertEqual(path.read_bytes(), content)

    def test_complete_platform_declarations_preview_without_deployment(self):
        shutil.copyfile(REPO / ".config/mise/config.toml", self.config / "config.toml")
        for folder in ("workspace", "omarchy"):
            shutil.copytree(REPO / ".config/mise" / folder, self.config / folder)
        (self.config / "conf.d").mkdir()
        shutil.copyfile(REPO / ".config/mise/conf.d/workspace.toml.example",
                        self.config / "conf.d/workspace.toml.example")
        for profile in ("macos", "omarchy"):
            shutil.copyfile(REPO / f".config/mise/config.{profile}.toml",
                            self.config / f"config.{profile}.toml")
            shell_targets = [str(self.home / ".bashrc")]
            if profile == "macos":
                shell_targets += [str(self.home / ".zshenv"), str(self.home / ".zshrc")]
            result = self.mise("-E", profile, "dotfiles", "apply", "--dry-run",
                               str(self.guard), *shell_targets)
            self.assert_success(result)
            self.assertNotIn("unknown field", result.stderr)
            self.assertNotIn("ignoring group", result.stderr)
            self.assertIn("ln -sf", result.stdout)
            self.assertIn(" ~/.bashrc", result.stdout)
            self.assertNotIn("shell-policy.sh", result.stdout)
            self.assertLess(result.stdout.index(" ~/.config/mise/miserc.toml"),
                            result.stdout.index(" ~/.bashrc"))
            self.assertFalse(self.policy.exists())
            self.assertFalse(self.guard.exists())
            self.assertFalse((self.home / ".bashrc").exists())

    def test_runtime_path_helper_is_not_declared(self):
        self.assertNotIn("runtime-path.sh", (REPO / ".config/mise/config.toml").read_text())

    def test_managed_guard_symlink_migrates_without_editing_original_source(self):
        source = self.write(self.config / "old-guard.toml", "override_tool_versions_filenames = []\n")
        self.write(self.config / "config.toml", '[dotfiles."~/.config/mise/miserc.toml"]\n'
                   'source = "old-guard.toml"\nmode = "symlink"\n')
        self.assert_success(self.mise("dotfiles", "apply", str(self.guard)))
        self.assertTrue(self.guard.is_symlink())
        before = source.read_bytes()
        self.write(self.config / "config.toml", self.declarations)
        self.apply()
        self.assertFalse(self.guard.is_symlink())
        self.assertIn('[".tool-versions"]', self.guard.read_text())
        self.assertEqual(source.read_bytes(), before)


class ShellStartupTests(PolicyFixture):
    def setUp(self):
        super().setUp()
        for shell, names in (("bash", (".bashrc", ".bash_profile")),
                             ("zsh", (".zshrc", ".zshenv"))):
            for name in names:
                shutil.copyfile(REPO / "packages" / shell / name, self.home / name)
        self.write(self.bin / "mise", '#!/bin/sh\n'
                   'printf "mise %s\\n" "$*" >> "$TEST_LOG"\n'
                   'case "$*" in\n'
                   '  "activate bash"|"activate zsh") '
                   'printf \'export PATH="$HOME/runtime/bin:$PATH"\\n_mise_test_hook() { :; }\\n\' ;;\n'
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
        self.write(self.home / "runtime/bin/node", "#!/bin/sh\necho mise\n", True)
        self.write(self.home / ".asdf/plugins/golang/set-env.zsh",
                   'export ASDF_PLUGIN_LOADED=yes\n')

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

    def test_interactive_and_login_startup_activate_only_mise(self):
        for shell, available in (("bash", BASH), ("zsh", ZSH)):
            if not available:
                continue
            for login in (False, True):
                with self.subTest(shell=shell, login=login):
                    self.log.unlink(missing_ok=True)
                    result = self.startup(shell, 'node; printf "PLUGIN:%s\\n" "${ASDF_PLUGIN_LOADED:-no}"; '
                                          'printf "ASDF:%s:%s\\n" "${ASDF_DATA_DIR:-}" '
                                          '"${ASDF_GOLANG_MOD_VERSION_ENABLED:-}"', login=login)
                    self.assert_success(result)
                    self.assertEqual(result.stdout, "mise\nPLUGIN:no\nASDF::\n")
                    self.assertEqual(self.log.read_text().splitlines(), [f"mise activate {shell}"])

    def test_obsolete_policy_is_not_sourced(self):
        self.write(self.policy, 'echo obsolete-policy-loaded\n'
                   'DOTFILES_RUNTIME_MANAGER=asdf\nDOTFILES_ENVIRONMENT_LOADER=direnv\n')
        for shell, available in (("bash", BASH), ("zsh", ZSH)):
            if not available:
                continue
            with self.subTest(shell=shell):
                result = self.startup(shell, "node")
                self.assert_success(result)
                self.assertEqual(result.stdout.strip(), "mise")

    def test_noninteractive_startup_preserves_inherited_real_runtime_paths(self):
        self.env["PATH"] = str(self.home / "runtime/bin") + ":" + self.env["PATH"]
        for shell, available in (("bash", BASH), ("zsh", ZSH)):
            if not available:
                continue
            with self.subTest(shell=shell):
                result = self.startup(shell, "node", interactive=False)
                self.assert_success(result)
                self.assertEqual(result.stdout.strip(), "mise")

    @unittest.skipUnless(BASH, "bash is required")
    def test_omarchy_path_without_bootstrap_does_not_skip_standalone_activation(self):
        self.env["OMARCHY_PATH"] = str(self.root / "not-an-omarchy-installation")
        result = self.startup("bash", "node")
        self.assert_success(result)
        self.assertEqual(result.stdout.strip(), "mise")
        self.assertEqual(self.log.read_text().splitlines(),
                         ["mise activate bash"])

    def test_noninteractive_startup_does_not_activate_mise(self):
        self.env["PATH"] = str(self.home / "runtime/bin") + ":" + self.env["PATH"]
        for shell, available in (("bash", BASH), ("zsh", ZSH)):
            if not available:
                continue
            with self.subTest(shell=shell):
                self.log.unlink(missing_ok=True)
                result = self.startup(shell, "node", interactive=False)
                self.assert_success(result)
                self.assertEqual(result.stdout.strip(), "mise")
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

    def test_noninteractive_startup_preserves_inherited_runtime_path_order(self):
        shims = {"asdf": str(self.home / ".asdf/shims"),
                 "mise": str(self.home / ".local/share/mise/shims")}
        original_path = self.env["PATH"]
        for shell, available in (("bash", BASH), ("zsh", ZSH)):
            if not available:
                continue
            inherited = [str(self.home / "runtime/bin"), shims["asdf"], shims["mise"], "", *original_path.split(":")]
            with self.subTest(shell=shell):
                self.env["PATH"] = ":".join(inherited)
                entry = ".bashrc" if shell == "bash" else ".zshenv"
                command = f'source "$HOME/{entry}"; node; printf "__PATH__%s\\n" "$PATH"'
                result = self.startup(shell, command, interactive=False)
                self.assert_success(result)
                self.assertEqual(result.stdout.splitlines()[0], "mise")
                path = next(line[len("__PATH__"):] for line in result.stdout.splitlines()
                            if line.startswith("__PATH__")).split(":")
                self.assertEqual(path.count(shims["mise"]), 1)
                self.assertEqual(path[-len(inherited):], inherited)
                self.assertEqual(path.count(""), 1)

    def test_noninteractive_startup_does_not_inject_custom_shim_directories(self):
        original_path = self.env["PATH"]
        data = self.home / "mise [custom]"
        asdf_data = self.home / "asdf [custom]"
        self.write(data / "installs/node/24/bin/node", "#!/bin/sh\necho mise\n", True)
        self.env.update(MISE_DATA_DIR=str(data), ASDF_DATA_DIR=str(asdf_data))
        for shell, available in (("bash", BASH), ("zsh", ZSH)):
            if not available:
                continue
            with self.subTest(shell=shell):
                self.env["PATH"] = f"{data}/installs/node/24/bin:{original_path}"
                result = self.startup(shell, 'node; printf "__PATH__%s\\n" "$PATH"; '
                                      'printf "__ASDF__%s\\n" "$ASDF_DATA_DIR"', interactive=False)
                self.assert_success(result)
                self.assertEqual(result.stdout.splitlines()[0], "mise")
                path = result.stdout.split("__PATH__", 1)[1].splitlines()[0].split(":")
                self.assertNotIn(str(data / "shims"), path)
                self.assertNotIn(str(asdf_data / "shims"), path)
                self.assertIn("__ASDF__" + str(asdf_data), result.stdout)

    def test_activation_tool_paths_are_not_replaced_by_late_shim_priority(self):
        for shell, available in (("bash", BASH), ("zsh", ZSH)):
            if not available:
                continue
            with self.subTest(shell=shell):
                result = self.startup(shell, 'command -v node; '
                                      'set | grep "^_dotfiles_.*=" || true')
                self.assert_success(result)
                self.assertEqual(result.stdout.strip(), str(self.home / "runtime/bin/node"))

    def test_stale_runtime_helper_is_not_sourced(self):
        self.write(self.home / ".config/dotfiles/runtime-path.sh", 'echo obsolete-helper-loaded\n')
        for shell, available in (("bash", BASH), ("zsh", ZSH)):
            if not available:
                continue
            with self.subTest(shell=shell):
                result = self.startup(shell, "node")
                self.assert_success(result)
                self.assertEqual(result.stdout.strip(), "mise")

    def prepare_omarchy_defaults(self):
        omarchy = self.root / "omarchy"
        self.write(omarchy / "default/bash/env-bootstrap", "# upstream environment fixture\n")
        self.write(omarchy / "default/bash/rc",
                   'command -v mise >/dev/null && eval "$(mise activate bash)"\n'
                   'declare OMARCHY_DEFAULTS_LOADED=yes\n')
        return omarchy

    @unittest.skipUnless(BASH, "bash is required")
    def test_omarchy_upstream_activates_mise_once_without_an_adapter(self):
        omarchy = self.prepare_omarchy_defaults()
        self.env["OMARCHY_PATH"] = str(omarchy)
        result = self.startup("bash", 'node; printf "OMARCHY:%s\\n" "$OMARCHY_DEFAULTS_LOADED"; '
                              'declare -F mise; declare -p _dotfiles_previous_mise 2>/dev/null; true')
        self.assert_success(result)
        self.assertEqual(result.stdout, "mise\nOMARCHY:yes\n")
        self.assertEqual(self.log.read_text().splitlines(), ["mise activate bash"])

    def prepare_native_projects(self):
        (self.bin / "mise").unlink()
        (self.bin / "mise").symlink_to(MISE)
        (self.home / ".local/share/mise/shims/node").unlink()
        install = self.root / "synthetic-node"
        self.write(install / "bin/node", "#!/bin/sh\necho mise\n", True)
        self.assert_success(self.run_command([MISE, "link", "node@24.0.0", str(install)]))
        self.env.update(APP_MODE="original", MISE_NOT_FOUND_AUTO_INSTALL="0")
        shutil.copyfile(REPO / ".config/mise/global/miserc.toml.tera", self.guard)
        self.write(self.guard.parent / "config.toml", '[tools]\nnode = "24.0.0"\n'
                   '[settings]\nnot_found_auto_install = false\n')
        first, second = self.home / "project-a", self.home / "project-b"
        # .envrc must not be evaluated implicitly.
        for project, value in ((first, "a"), (second, "b")):
            self.write(project / ".envrc", "export APP_MODE=must-not-load\n")
            self.write(project / ".tool-versions", "nodejs 24.0.0\n")
            self.write(project / "mise.toml", f'[env]\nAPP_MODE = "{value}"\n')
        return first, second

    def assert_active_hooks(self, session, shell):
        mise_hook = "_mise_hook_precmd" if shell == "zsh" else "_mise_hook_prompt_command"
        output = session.command(
            'if typeset -f _direnv_hook >/dev/null; then echo __DIRENV__yes; '
            'else echo __DIRENV__no; fi; '
            f'if typeset -f {mise_hook} >/dev/null; then echo __MISE__yes; '
            'else echo __MISE__no; fi')
        self.assertIn("__DIRENV__no\r\n", output)
        self.assertIn("__MISE__yes\r\n", output)

    def assert_project_state(self, session, folder, value, runtime):
        session.command("cd " + shlex.quote(str(folder)))
        output = session.command('printf "__VALUE__%s\\n" "$APP_MODE"; '
                                 'printf "__RUNTIME__"; node')
        self.assertIn("__VALUE__" + value + "\r\n", output)
        self.assertIn("__RUNTIME__" + runtime + "\r\n", output)

    @unittest.skipUnless(MISE and BASH and ZSH, "native mise, Bash and Zsh are required")
    def test_native_mise_restores_shared_keys_across_sibling_and_nested_projects(self):
        # Real generators and prompt callbacks, actual repository startup files,
        # synthetic runtime binaries, and no host prompt/plugins or credentials.
        first, second = self.prepare_native_projects()
        child = first / "nested"
        self.write(child / "mise.toml", '[env]\nAPP_MODE = "child"\n')
        self.write(second / "mise.local.toml", '[env]\nAPP_MODE = "b-local"\n')
        omarchy = self.prepare_omarchy_defaults()
        for shell in ("bash", "zsh", "omarchy"):
            if shell == "omarchy":
                self.env["OMARCHY_PATH"] = str(omarchy)
            else:
                self.env.pop("OMARCHY_PATH", None)
            with self.subTest(shell=shell):
                arguments = ([BASH, "--noprofile", "--rcfile", str(self.home / ".bashrc"), "-i"]
                             if shell != "zsh" else [ZSH, "-d", "-i"])
                session = InteractiveSession(arguments, self.outside, self.env)
                try:
                    self.assert_active_hooks(session, shell)
                    for folder, expected in ((first, "a"), (child, "child"), (first, "a"),
                                             (second, "b-local"), (self.outside, "original"),
                                             (second, "b-local"), (self.outside, "original")):
                        self.assert_project_state(session, folder, expected, "mise")
                finally:
                    session.close()

    @unittest.skipUnless(MISE, "native mise is required")
    def test_explicit_exec_keeps_launching_project_tools_when_child_changes_directory(self):
        first, second = self.prepare_native_projects()
        alternate = self.root / "alternate-node"
        self.write(alternate / "bin/node", "#!/bin/sh\necho project-runtime\n", True)
        self.assert_success(self.run_command([MISE, "link", "node@25.0.0", str(alternate)]))
        self.write(first / ".tool-versions", "nodejs 25.0.0\n")
        for shell in ("/bin/sh", BASH, ZSH):
            if not shell:
                continue
            with self.subTest(shell=shell):
                result = self.run_command([MISE, "exec", "--", shell, "-c",
                                           'cd "$HOME/outside"; node'], cwd=first)
                self.assert_success(result)
                self.assertEqual(result.stdout.strip(), "project-runtime")
                self.assertEqual(result.stderr, "")


class ProjectTemplateTests(PolicyFixture):
    def setUp(self):
        super().setUp()
        self.templates = self.home / ".config/nvim/templates"
        shutil.copytree(REPO / "packages/nvim/.config/nvim/templates", self.templates)
        self.scaffolder = REPO / "packages/scripts/.local/bin/dotf.d/init"

    @unittest.skipUnless(shutil.which("git"), "git is required")
    def test_local_mise_overrides_are_ignored_without_hiding_shared_configs(self):
        self.assert_success(self.run_command(["git", "init", "-q"]))
        private = ["mise.local.toml", "mise.dev.local.toml",
                   ".mise.local.toml", ".mise.dev.local.toml"]
        private += ["nested/" + name for name in private]
        shared = ["mise.toml", "mise.dev.toml", ".mise.toml", ".mise.dev.toml",
                  "nested/mise.toml", "mise.toml.template"]
        sources = (REPO / ".gitignore",
                   REPO / "packages/gitconfig/.config/git/.gitignore_global")
        for source in sources:
            with self.subTest(source=source):
                # Check each policy independently, without host ignore settings.
                ignore = self.write(self.root / "ignore-rules", source.read_text())
                result = self.run_command([
                    "git", "-c", f"core.excludesFile={ignore}",
                    "check-ignore", "--no-index", *private, *shared,
                ])
                self.assert_success(result)
                self.assertEqual(result.stdout.splitlines(), private)

    @unittest.skipUnless(BASH, "bash is required")
    def test_scaffolder_generates_mise_not_envrc_without_running_trust_or_install(self):
        self.write(self.bin / "mise", '#!/bin/sh\nprintf "%s\\n" "$*" >> "$TEST_LOG"\nexit 91\n', True)
        result = self.run_command([BASH, str(self.scaffolder), "--all"])
        self.assert_success(result)
        self.assertTrue((self.outside / "mise.toml").is_file())
        self.assertFalse((self.outside / ".envrc").exists())
        self.assertIn("mise trust", result.stdout)
        self.assertIn("mise exec -- nvim", result.stdout)
        self.assertNotIn("direnv allow", result.stdout)
        self.assertFalse(self.log.exists())

    @unittest.skipUnless(BASH, "bash is required")
    def test_scaffolder_preserves_existing_project_files(self):
        originals = {"mise.toml": "# personal mise config\n", ".envrc": "# existing environment\n"}
        for name, text in originals.items():
            self.write(self.outside / name, text)
        result = self.run_command([BASH, str(self.scaffolder), "--all"])
        self.assert_success(result)
        for name, text in originals.items():
            self.assertEqual((self.outside / name).read_text(), text)
        self.assertNotIn("mise trust", result.stdout)
        self.assertNotIn("direnv allow", result.stdout)

    @unittest.skipUnless(BASH, "bash is required")
    def test_scaffolder_reads_symlinked_templates(self):
        template = self.templates / "mise.toml.template"
        source = self.root / "mise.template"
        template.rename(source)
        template.symlink_to(source)
        result = self.run_command([BASH, str(self.scaffolder), "--all"])
        self.assert_success(result)
        self.assertEqual((self.outside / "mise.toml").read_bytes(), source.read_bytes())

    @unittest.skipUnless(BASH, "bash is required")
    def test_scaffolder_preserves_dangling_symlinks(self):
        target = self.root / "missing-personal-config.toml"
        destination = self.outside / "mise.toml"
        destination.symlink_to(target)
        result = self.run_command([BASH, str(self.scaffolder), "--all"])
        self.assert_success(result)
        self.assertTrue(destination.is_symlink())
        self.assertFalse(target.exists())
        self.assertNotIn("mise trust", result.stdout)

    @unittest.skipUnless(MISE, "native mise is required")
    def test_neovim_template_loads_opt_in_settings_without_asdf_exports(self):
        text = (self.templates / "mise.toml.template").read_text()
        self.write(self.outside / "mise.toml", text)
        result = self.run_command([MISE, "env", "--json"])
        self.assert_success(result)
        environment = json.loads(result.stdout)
        self.assertNotIn("NVIM_DAP_ENABLED", environment)
        self.assertNotIn("NVIM_LOCAL_CONFIG", environment)
        text = text.replace('# NVIM_DAP_ENABLED =', 'NVIM_DAP_ENABLED =')
        text = text.replace('# NVIM_LOCAL_CONFIG =', 'NVIM_LOCAL_CONFIG =')
        self.write(self.outside / "mise.toml", text)
        result = self.run_command([MISE, "env", "--json"])
        self.assert_success(result)
        environment = json.loads(result.stdout)
        self.assertEqual(environment["NVIM_DAP_ENABLED"], "1")
        self.assertEqual(environment["NVIM_LOCAL_CONFIG"], str(self.outside / ".config/nvim.lua"))
        self.assertFalse(any(name.startswith("ASDF_") for name in environment))

    def test_asdf_and_direnv_dependencies_remain_without_asdf_deployment(self):
        self.assertIn('"github:asdf-vm/asdf" = "latest"',
                      (REPO / ".config/mise/global/tools.toml").read_text())
        for profile, dependency in (("macos", "brew:direnv"), ("omarchy", "pacman:direnv")):
            text = (REPO / f".config/mise/config.{profile}.toml").read_text()
            self.assertIn(f'"{dependency}"', text)
            self.assertNotIn('"asdf",', text)
        self.assertNotIn("[dotfile_groups.asdf]", (REPO / ".config/mise/config.toml").read_text())


if __name__ == "__main__":
    unittest.main()
