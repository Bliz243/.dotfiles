-- Options are automatically loaded before lazy.nvim startup.
-- LazyVim sets sensible defaults (leader=space, number/relativenumber, expandtab,
-- shiftwidth=2, clipboard=unnamedplus, ...). Only deltas live here.

local opt = vim.opt

opt.scrolloff = 8
opt.sidescrolloff = 8
opt.swapfile = false

-- WSL clipboard via win32yank (no-op on native Linux).
-- Requires win32yank.exe on PATH (installed by scripts/install.sh).
if vim.fn.has("wsl") == 1 then
  vim.g.clipboard = {
    name = "win32yank",
    copy = {
      ["+"] = "win32yank.exe -i --crlf",
      ["*"] = "win32yank.exe -i --crlf",
    },
    paste = {
      ["+"] = "win32yank.exe -o --lf",
      ["*"] = "win32yank.exe -o --lf",
    },
    cache_enabled = 0,
  }
end
