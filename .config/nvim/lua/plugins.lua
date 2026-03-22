return {
    -- Statusline
    {
        "vim-airline/vim-airline",
        dependencies = { "vim-airline/vim-airline-themes" },
        config = function()
            vim.g.airline_powerline_fonts = 1
        end,
    },

    -- Git
    { "tpope/vim-fugitive" },
    {
        "lewis6991/gitsigns.nvim",  -- gitgutter equivalent, native neovim plugin
        config = function()
            require("gitsigns").setup()
        end,
    },

    -- tpope essentials
    { "tpope/vim-surround" },
    { "tpope/vim-commentary" },
    { "tpope/vim-repeat" },
    { "tpope/vim-sleuth" },
}
