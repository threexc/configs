-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git", "clone", "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- Load plugins
require("lazy").setup("plugins")

-- Appearance
vim.cmd("colorscheme desert")
vim.opt.number         = true
vim.opt.ruler          = true
vim.opt.visualbell     = true
vim.opt.colorcolumn    = "81"

-- Editing behaviour
vim.opt.autoindent     = true
vim.opt.textwidth      = 80
vim.opt.scrolloff      = 5
vim.opt.hidden         = true
vim.opt.mouse          = ""

-- Search
vim.opt.hlsearch       = true
vim.opt.incsearch      = true
vim.opt.ignorecase     = true
vim.opt.smartcase      = true
vim.opt.wildmenu       = true

-- Performance
vim.opt.updatetime     = 100

-- Filetype-specific indentation
vim.api.nvim_create_augroup("FileTypeIndent", { clear = true })

-- Use Esc to exit terminal mode
vim.api.nvim_set_keymap('t', '<Esc>', '<C-\\><C-n>', {noremap = true})

local function set_indent(pattern, opts)
    vim.api.nvim_create_autocmd("FileType", {
        group = "FileTypeIndent",
        pattern = pattern,
        callback = function()
            vim.opt_local.tabstop     = opts.tabstop
            vim.opt_local.shiftwidth  = opts.shiftwidth
            vim.opt_local.softtabstop = opts.softtabstop
            vim.opt_local.expandtab   = opts.expandtab
        end,
    })
end

set_indent("make",   { tabstop=8, shiftwidth=8, softtabstop=0, expandtab=false })
set_indent("c",      { tabstop=8, shiftwidth=8, softtabstop=8, expandtab=false })
set_indent("python", { tabstop=4, shiftwidth=4, softtabstop=4, expandtab=true  })
set_indent("rust",   { tabstop=4, shiftwidth=4, softtabstop=4, expandtab=true  })
set_indent("yaml",   { tabstop=2, shiftwidth=2, softtabstop=2, expandtab=true  })

-- Verilog files (.v, .vs)
vim.api.nvim_create_autocmd({"BufNewFile", "BufRead"}, {
    group = "FileTypeIndent",
    pattern = {"*.v", "*.vs"},
    callback = function()
        vim.opt_local.tabstop     = 4
        vim.opt_local.shiftwidth  = 4
        vim.opt_local.softtabstop = 4
        vim.opt_local.expandtab   = true
    end,
})
