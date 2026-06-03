return {
  -- ─────────────────────────────────────────────
  -- Colorscheme
  -- ─────────────────────────────────────────────
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    config = function()
      require("catppuccin").setup({ flavour = "mocha" })
      vim.cmd.colorscheme("catppuccin")
    end,
  },

  -- ─────────────────────────────────────────────
  -- Treesitter (syntax highlighting)
  -- main branch requires explicit start via FileType autocmd
  -- ─────────────────────────────────────────────
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local parsers = {
        "lua", "vim", "vimdoc", "bash",
        "typescript", "javascript", "tsx", "html", "css",
        "python", "go", "yaml", "json", "dockerfile", "terraform",
        "markdown", "markdown_inline",
      }
      require("nvim-treesitter").install(parsers)
      vim.treesitter.language.register("bash", "zsh")

      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          pcall(vim.treesitter.start, args.buf)
          vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
          vim.wo.foldmethod = "expr"
          vim.wo.foldlevel = 99
        end,
      })
    end,
  },

  -- ─────────────────────────────────────────────
  -- LSP
  -- ─────────────────────────────────────────────
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      require("config.lsp")
    end,
  },

  -- ─────────────────────────────────────────────
  -- Completion (with autopairs integration)
  -- ─────────────────────────────────────────────
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "windwp/nvim-autopairs",
    },
    config = function()
      require("nvim-autopairs").setup()

      local cmp = require("cmp")
      local luasnip = require("luasnip")
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")

      cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = {
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        },
      })
    end,
  },

  -- ─────────────────────────────────────────────
  -- Telescope (fuzzy finder)
  -- ─────────────────────────────────────────────
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>",                    desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>",                     desc = "Live grep" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>",                       desc = "Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>",                     desc = "Help" },
      { "<leader>fr", "<cmd>Telescope resume<cr>",                        desc = "Resume last picker" },
      { "<leader>fo", "<cmd>Telescope oldfiles<cr>",                      desc = "Recent files" },
      { "<leader>fs", "<cmd>Telescope lsp_document_symbols<cr>",          desc = "Doc symbols" },
      { "<leader>fS", "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>", desc = "Workspace symbols" },
      { "<leader>fd", "<cmd>Telescope diagnostics<cr>",                   desc = "Diagnostics" },
      { "<leader>/",  "<cmd>Telescope current_buffer_fuzzy_find<cr>",     desc = "Search in buffer" },
      { "<C-p>",      "<cmd>Telescope find_files<cr>",                    desc = "Find files" },
    },
  },

  -- ─────────────────────────────────────────────
  -- File explorer
  -- ─────────────────────────────────────────────
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "-", "<cmd>Oil<cr>", desc = "Open file explorer" },
    },
    config = function()
      require("oil").setup({
        view_options = {
          show_hidden = true,
        },
      })
    end,
  },

  -- ─────────────────────────────────────────────
  -- Text objects (treesitter-aware): daf, vac, cia, etc.
  -- ─────────────────────────────────────────────
  {
    "echasnovski/mini.ai",
    event = "VeryLazy",
    config = function()
      local ai = require("mini.ai")
      ai.setup({
        n_lines = 500,
        custom_textobjects = {
          f = ai.gen_spec.treesitter({ a = "@function.outer",  i = "@function.inner" }),
          c = ai.gen_spec.treesitter({ a = "@class.outer",     i = "@class.inner" }),
          a = ai.gen_spec.treesitter({ a = "@parameter.outer", i = "@parameter.inner" }),
        },
      })
    end,
  },

  -- ─────────────────────────────────────────────
  -- Surround: cs"' / ds( / ysiw)
  -- ─────────────────────────────────────────────
  {
    "echasnovski/mini.surround",
    event = "VeryLazy",
    opts = {},
  },

  -- ─────────────────────────────────────────────
  -- Harpoon: bookmarked file rotation
  -- ─────────────────────────────────────────────
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = function()
      local h = require("harpoon")
      return {
        { "<leader>ma", function() h:list():add() end,                   desc = "Harpoon: add file" },
        { "<leader>mm", function() h.ui:toggle_quick_menu(h:list()) end, desc = "Harpoon: menu" },
        { "<leader>1",  function() h:list():select(1) end,               desc = "Harpoon 1" },
        { "<leader>2",  function() h:list():select(2) end,               desc = "Harpoon 2" },
        { "<leader>3",  function() h:list():select(3) end,               desc = "Harpoon 3" },
        { "<leader>4",  function() h:list():select(4) end,               desc = "Harpoon 4" },
      }
    end,
    config = function()
      require("harpoon"):setup()
    end,
  },

  -- ─────────────────────────────────────────────
  -- Flash: jump anywhere on screen in 2 keys
  -- s/S overridden in n/x/o modes
  -- ─────────────────────────────────────────────
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "s", function() require("flash").jump() end,       mode = { "n", "x", "o" }, desc = "Flash" },
      { "S", function() require("flash").treesitter() end, mode = { "n", "x", "o" }, desc = "Flash treesitter" },
    },
  },

  -- ─────────────────────────────────────────────
  -- Git: fugitive (:G blame, :G diff, etc.)
  -- ─────────────────────────────────────────────
  {
    "tpope/vim-fugitive",
    cmd = { "G", "Git", "Gdiffsplit", "Gread", "Gwrite", "Ggrep", "GMove", "GDelete", "GBrowse", "Gclog" },
    keys = {
      { "<leader>gs", "<cmd>G<cr>",          desc = "Git status" },
      { "<leader>gb", "<cmd>G blame<cr>",    desc = "Git blame" },
      { "<leader>gd", "<cmd>Gdiffsplit<cr>", desc = "Git diff" },
      { "<leader>gl", "<cmd>Gclog<cr>",      desc = "Git log → quickfix" },
    },
  },

  -- ─────────────────────────────────────────────
  -- Git signs (gutter hunks + per-buffer keymaps)
  -- ─────────────────────────────────────────────
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        local map = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end

        map("n", "]c", function()
          if vim.wo.diff then return "]c" end
          vim.schedule(function() gs.next_hunk() end)
          return "<Ignore>"
        end, "Next hunk")

        map("n", "[c", function()
          if vim.wo.diff then return "[c" end
          vim.schedule(function() gs.prev_hunk() end)
          return "<Ignore>"
        end, "Prev hunk")

        map({ "n", "v" }, "<leader>hs", ":Gitsigns stage_hunk<CR>", "Stage hunk")
        map({ "n", "v" }, "<leader>hr", ":Gitsigns reset_hunk<CR>", "Reset hunk")
        map("n", "<leader>hp", gs.preview_hunk,                     "Preview hunk")
        map("n", "<leader>hb", function() gs.blame_line({ full = true }) end, "Blame line")
      end,
    },
  },

  -- ─────────────────────────────────────────────
  -- Which-key (keybind help)
  -- ─────────────────────────────────────────────
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {},
  },

  -- ─────────────────────────────────────────────
  -- Status line
  -- ─────────────────────────────────────────────
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons", "catppuccin/nvim" },
    opts = {
      options = { theme = "catppuccin-mocha" },
    },
  },

  -- ─────────────────────────────────────────────
  -- Formatting (handles trailing whitespace via formatters)
  -- ─────────────────────────────────────────────
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = { "ConformInfo" },
    keys = {
      { "<leader>cf", function() require("conform").format({ async = true }) end, desc = "Format buffer" },
    },
    opts = {
      formatters_by_ft = {
        javascript = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        javascriptreact = { "prettier" },
        css = { "prettier" },
        html = { "prettier" },
        json = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        python = { "black" },
        go = { "gofmt" },
        terraform = { "terraform_fmt" },
        lua = { "stylua" },
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_fallback = true,
      },
    },
  },
}
