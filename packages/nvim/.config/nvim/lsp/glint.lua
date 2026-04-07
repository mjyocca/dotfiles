---@type vim.lsp.Config
return {
  -- cmd = function(dispatchers, config)
  --   ---@diagnostic disable-next-line: undefined-field
  --   local cmd = (config.init_options.glint.useGlobal or not config.root_dir) and { 'glint-language-server', '--stdio' }
  --     or { config.root_dir .. '/node_modules/.bin/glint-language-server', '--stdio'}
  --   return vim.lsp.rpc.start(cmd, dispatchers)
  -- end,
  cmd = { "glint-language-server --stdio" },
  on_new_config = function(config, new_root_dir)
    local project_root = vim.fs.dirname(vim.fs.find('node_modules', { path = new_root_dir, upward = true })[1])
    -- Glint should not be installed globally.
    local node_bin_path = project_root .. '/node_modules/.bin'
    local path = node_bin_path .. (vim.fn.has('win32') == 1 and ';' or ':') .. vim.env.PATH
    if config.cmd_env then
      config.cmd_env.PATH = path
    else
      config.cmd_env = { PATH = path, ARGS = { '--stdio' } }
    end
  end,
  init_options = {
    glint = {
      useGlobal = false,
    },
  },
  filetypes = {
    'html.handlebars',
    'handlebars',
    'typescript',
    'typescript.glimmer',
    'javascript',
    'javascript.glimmer',
  },
  root_markers = {
    '.glintrc.yml',
    '.glintrc',
    '.glintrc.json',
    '.glintrc.js',
    'glint.config.js',
    'ember-cli-build.js',
    'package.json',
  },
  workspace_required = true,
}
