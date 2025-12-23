return {
    "nvim-treesitter/nvim-treesitter",
    lazy = false, build = ":TSUpdate",
    branch="main",
    dependencies={
        'nvim-treesitter/nvim-treesitter-context',
        'ron-rs/ron.vim'
    },
    config=function()
        vim.api.nvim_create_autocmd('FileType', {
            callback = function(args)
                local lang = vim.treesitter.language.get_lang(args.match) or args.match
                local installed = require('nvim-treesitter').get_installed('parsers')
                if vim.tbl_contains(installed, lang) then
                    vim.treesitter.start(args.buf)
                end
            end,
        })
    end
}
