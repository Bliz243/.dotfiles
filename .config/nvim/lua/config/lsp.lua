-- LSP Configuration

-- Setup Mason (LSP installer)
require("mason").setup()

-- LSP capabilities (for completion)
local capabilities = require("cmp_nvim_lsp").default_capabilities()

-- Setup mason-lspconfig with handlers
require("mason-lspconfig").setup({
  ensure_installed = {
    "lua_ls",       -- Lua
    "ts_ls",        -- TypeScript/JavaScript
    "tailwindcss",  -- Tailwind CSS
    "html",         -- HTML
    "cssls",        -- CSS
    "pyright",      -- Python
    "bashls",       -- Bash
    "yamlls",       -- YAML
    "dockerls",     -- Docker
    "terraformls",  -- Terraform
    "gopls",        -- Go
  },
  handlers = {
    -- Default handler for all servers
    function(server_name)
      require("lspconfig")[server_name].setup({
        capabilities = capabilities,
      })
    end,
    -- Custom handler for lua_ls
    ["lua_ls"] = function()
      require("lspconfig").lua_ls.setup({
        capabilities = capabilities,
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
          },
        },
      })
    end,
  },
})

-- LSP keymaps (on attach)
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local map = function(keys, func, desc)
      vim.keymap.set("n", keys, func, { buffer = args.buf, desc = desc })
    end

    map("gd", vim.lsp.buf.definition, "Go to definition")
    map("gD", vim.lsp.buf.declaration, "Go to declaration")
    map("gr", vim.lsp.buf.references, "References")
    map("gi", vim.lsp.buf.implementation, "Implementation")
    map("K", vim.lsp.buf.hover, "Hover")
    map("<leader>rn", vim.lsp.buf.rename, "Rename")
    map("<leader>ca", vim.lsp.buf.code_action, "Code action")
    map("[d", vim.diagnostic.goto_prev, "Prev diagnostic")
    map("]d", vim.diagnostic.goto_next, "Next diagnostic")
    map("<leader>e", vim.diagnostic.open_float, "Show diagnostic")
  end,
})

-- Diagnostic signs
vim.diagnostic.config({
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "✘",
      [vim.diagnostic.severity.WARN] = "▲",
      [vim.diagnostic.severity.HINT] = "⚑",
      [vim.diagnostic.severity.INFO] = "»",
    },
  },
  virtual_text = { prefix = "●" },
  update_in_insert = false,
  float = { border = "rounded" },
})
