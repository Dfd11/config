return {
  "sindrets/diffview.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  -- This tells LazyVim to only load the plugin when you actually use these commands
  cmd = { 
    "DiffviewOpen", 
    "DiffviewClose", 
    "DiffviewToggleFiles", 
    "DiffviewFocusFiles", 
    "DiffviewFileHistory" 
  },
  -- Custom shortcuts to open it instantly
  keys = {
    { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diffview Open (Current State)" },
    { "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview File History" },
  },
}
