"""Terminal Browser's shared tool and Omarchy runtime dependencies."""

from pathlib import Path
import unittest


REPO = Path(__file__).resolve().parents[2]


class TerminalBrowserDeclarationTests(unittest.TestCase):
    def test_terminal_browser_uses_shared_platform_release_asset(self):
        tools = (REPO / ".config/mise/global/tools.toml").read_text()

        self.assertIn('"github:zenbu-labs/terminal-browser"', tools)
        self.assertIn(
            'asset_pattern = \'terminal-browser-{{ os(macos="darwin") }}-{{ arch() }}.tar.gz\'',
            tools,
        )

    def test_omarchy_declares_linux_runtime_dependencies(self):
        packages = (REPO / ".config/mise/config.omarchy.toml").read_text()

        for package in ("alsa-lib", "gtk3", "mesa", "nss"):
            self.assertIn(f'"pacman:{package}" = "latest"', packages)


if __name__ == "__main__":
    unittest.main()
