-- Extra harpoon keymaps to match prior muscle memory.
-- The editor.harpoon2 extra already binds <leader>H (add), <leader>h (menu),
-- and <leader>1-9 (select). These add the previous <leader>ma / <leader>mm aliases.
return {
  "ThePrimeagen/harpoon",
  keys = {
    {
      "<leader>ma",
      function()
        require("harpoon"):list():add()
      end,
      desc = "Harpoon File",
    },
    {
      "<leader>mm",
      function()
        local harpoon = require("harpoon")
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end,
      desc = "Harpoon Quick Menu",
    },
  },
}
