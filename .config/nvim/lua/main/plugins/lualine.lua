return {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config=function()
        require('lualine').setup{
            sections = {
                lualine_a = {'mode'},
                lualine_b = {'branch', 'diff', 'diagnostics'},
                lualine_c = {
                    {
                        'lsp_status'
                    },
                },
                lualine_x = {
                    {
                        'filename',
                        symbols = {
                            modified = '●',
                            readonly = '',
                        }
                    }
                },
                lualine_y = {"filetype"},
                lualine_z = {"%l:%c"}
            },
        }
    end
}
