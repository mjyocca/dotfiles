local M = {}

-- require('config.utils').print_table(vim.tbl_keys(vim.lsp._enabled_configs))

local language_files = {
	"lua",
	"c",
	"rust",
	"golang",
	"ruby",
	"sorbet",
	"terraform",
	"bash",
	"markdown",
  "mdx",
}

local server_mappings = {}

for _, lang in ipairs(language_files) do
	local ok, conf = pcall(require, "lang." .. lang)
	if not ok then
		vim.notify("Failed to load Language configuration for " .. lang, vim.log.levels.WARN)
	else
		server_mappings[conf.server_name] = conf.lspconfig
	end
end

M.lsp_servers = server_mappings

return M
