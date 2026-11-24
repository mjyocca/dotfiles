"""Declarations for Anomaly's Hex and Browse tools."""

import json
from pathlib import Path
import unittest


REPO = Path(__file__).resolve().parents[2]


class AnomalyToolDeclarationTests(unittest.TestCase):
    def test_hex_uses_platform_package_owners(self):
        macos = (REPO / ".config/mise/config.macos.toml").read_text()
        omarchy = (REPO / ".config/mise/config.omarchy.toml").read_text()
        aur_packages = {
            line.split("#", 1)[0].strip()
            for line in (REPO / "packages/aur/packages.txt").read_text().splitlines()
        }

        self.assertIn('"brew-cask:anomalyco/tap/hex" = "latest"', macos)
        self.assertIn("hex-bin", aur_packages)
        self.assertNotIn(
            '"brew-cask:anomalyco/tap/hex"',
            omarchy,
        )
        self.assertIn('"pacman:wtype" = "latest"', omarchy)

    def test_browse_is_shared_and_keeps_agent_browser(self):
        tools = (REPO / ".config/mise/global/tools.toml").read_text()

        self.assertIn('"npm:@opencode/browse" = "latest"', tools)
        self.assertIn('"aqua:vercel-labs/agent-browser" = "latest"', tools)

    def test_browse_mcp_example_uses_managed_updates(self):
        config = json.loads(
            (
                REPO
                / "packages/opencode/.config/opencode/opencode.jsonc.example"
            ).read_text()
        )
        browse = config["mcp"]["servers"]["browse"]

        self.assertEqual(browse["type"], "local")
        self.assertEqual(browse["command"], ["browse", "mcp"])
        self.assertEqual(
            browse["environment"]["OPENCODE_BROWSER_AUTO_UPDATE"],
            "off",
        )


if __name__ == "__main__":
    unittest.main()
