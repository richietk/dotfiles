return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  keys = {
    { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Toggle Neo-tree" },
    { "<leader>f", "<cmd>Neotree reveal<cr>", desc = "Reveal file in Neo-tree" },
  },
  opts = {
    filesystem = {
      filtered_items = {
        hide_dotfiles = false,
      },
    },
  },
}
