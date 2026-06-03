-- Keymaps are automatically loaded on the VeryLazy event.
-- LazyVim provides save/window-nav/move-lines/indent-stay/buffer nav by default.
-- Only personal additions live here.

local map = vim.keymap.set

-- Quickfix
map("n", "<leader>xq", "<cmd>copen<cr>", { desc = "Open quickfix" })
map("n", "<leader>xc", "<cmd>cclose<cr>", { desc = "Close quickfix" })
map("n", "<leader>xd", vim.diagnostic.setqflist, { desc = "Diagnostics → quickfix" })

-- Center cursor on half-page scroll
map("n", "<C-d>", "<C-d>zz", { desc = "Half page down (centered)" })
map("n", "<C-u>", "<C-u>zz", { desc = "Half page up (centered)" })

-- Buffer cycling with Tab (LazyVim default is [b / ]b and S-h / S-l)
map("n", "<Tab>", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "<S-Tab>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
