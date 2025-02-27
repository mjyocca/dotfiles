local util = require("lspconfig.util")
return {
	server_name = "glint",
	lspconfig = {
		cmd = { "glint-language-server" },
		on_new_config = function(config, new_root_dir)
			local project_root = vim.fs.find("node_modules", { path = new_root_dir, upward = true })[1]
			-- Glint should not be installed globally.
			local node_bin_path = util.path.join(project_root, "node_modules", ".bin")
			local path = node_bin_path .. util.path.path_separator .. vim.env.PATH
			if config.cmd_env then
				config.cmd_env.PATH = path
			else
				config.cmd_env = { PATH = path }
			end
		end,
		filetypes = {
			"html.handlebars",
			"handlebars",
			"typescript",
			"typescript.glimmer",
			"javascript",
			"javascript.glimmer",
		},
		root_dir = util.root_pattern(
			".glintrc.yml",
			".glintrc",
			".glintrc.json",
			".glintrc.js",
			"glint.config.js",
			"package.json"
		),
	},
}
