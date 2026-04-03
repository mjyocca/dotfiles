local typescript = {
	server_name = "ts_ls",
	lspconfig = {
		filetypes = {
      'javascript',
      'javascriptreact',
      'javascript.jsx',
      'typescript',
      'typescriptreact',
      'typescript.tsx',
		},
	},
  -- root_dir = require('lspconfig.util').root_pattern(
  --   'tsconfig.json',
  --   'jsconfig.json',
  --   'package.json',
  --   '.git'
  -- ),
}

return typescript
