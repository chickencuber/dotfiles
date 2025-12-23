return { 'kevinhwang91/nvim-ufo', dependencies = 'kevinhwang91/promise-async', config=function()
    require('ufo').setup({
        open_fold_hl_timeout = 150,
        provider_selector = function()
            return {'treesitter', 'indent'}
        end
    })

    vim.o.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]
    vim.o.foldcolumn = '0'
    vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
    vim.o.foldlevelstart = 99
    vim.o.foldenable = true

    -- Using ufo provider need remap `zR` and `zM`. If Neovim is 0.6.1, remap yourself
    vim.keymap.set('n', 'to', require('ufo').openAllFolds)
    vim.keymap.set('n', 'tp', require('ufo').closeAllFolds)
    vim.keymap.set('n', "tt", "za", { noremap = true, silent = true })
end}
