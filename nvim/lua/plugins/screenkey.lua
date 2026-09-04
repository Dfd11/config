return {
  "nstefan002/screenkey.nvim",
  cmd = "Screenkey",
  opts = {
    win_opts = {
      row = vim.o.lines - 3, -- Places it near the bottom statusline
      col = vim.o.columns - 40,
    },
  },
}
