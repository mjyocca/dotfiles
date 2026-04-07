---@type vim.lsp.Config
return {
	cmd = { "ember-language-server", "--stdio" },
	filetypes = { "handlebars", "typescript", "javascript", "typescript.glimmer", "javascript.glimmer" },
	root_markers = { "ember-cli-build.js" },
}
