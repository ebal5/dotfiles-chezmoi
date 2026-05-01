-- LuaSnip 拡張: プロジェクトローカルの VS Code 形式スニペットをロード
-- LazyVim の luasnip extra で friendly-snippets と ~/.config/nvim/snippets/ は既にロード済み
return {
  {
    "L3MON4D3/LuaSnip",
    dependencies = {
      {
        "rafamadriz/friendly-snippets",
        config = function()
          local loader = require("luasnip.loaders.from_vscode")
          loader.lazy_load()
          loader.lazy_load({ paths = { vim.fn.stdpath("config") .. "/snippets" } })
          loader.lazy_load({ paths = { "./.vscode" } })
        end,
      },
    },
  },
}
