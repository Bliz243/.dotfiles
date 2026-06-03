-- Oil: edit the filesystem like a buffer. Not a LazyVim extra, so added here.
return {
  "stevearc/oil.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  lazy = false,
  opts = {
    view_options = { show_hidden = true },
  },
  keys = {
    { "-", "<cmd>Oil<cr>", desc = "Open parent directory (oil)" },
  },
}
