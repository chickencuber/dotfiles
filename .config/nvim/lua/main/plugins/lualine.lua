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
                lualine_x = {},
                lualine_y = {
                    {
                        'filename',
                        symbols = {
                            modified = '●',
                            readonly = '',
                        }
                    },
                    "filetype",
                },
                lualine_z = {"%l:%c"}
            },
        }
    end
}
