return {
    'nvim-telescope/telescope.nvim', tag = '0.1.8',
    dependencies = {
        'nvim-lua/plenary.nvim',
        'chickencuber/tasks.nvim',
    },
    config=function()
        local builtin = require('telescope.builtin')

        require('telescope').setup{
            defaults = {
                preview = {
                    treesitter = false,
                },
                vimgrep_arguments = {
                    'rg',
                    '--color=never',
                    '--no-heading',
                    '--with-filename',
                    '--line-number',
                    '--column',
                    '--smart-case'
                },
            }
        }

        vim.keymap.set('n', '<leader>pf', builtin.find_files, {})
        vim.keymap.set('n', '<C-p>', builtin.git_files, {})
        vim.keymap.set('n', '<leader>ps', function()
            builtin.grep_string({search = vim.fn.input("Grep > ")})
        end)
        vim.keymap.set('n', '<leader>pb', builtin.buffers, { desc = 'Fuzzy find buffers' })
        local task = require("tasks")
        vim.keymap.set('n', '<leader>ts', function()
            local comment = task.get_comment()
            if comment == nil then
                print("no TASK comment found")
                return
            end
            builtin.grep_string({search = comment})
        end)
    end
}
