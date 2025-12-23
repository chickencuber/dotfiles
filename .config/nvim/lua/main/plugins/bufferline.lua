return {'akinsho/bufferline.nvim', version = "*", dependencies = 'nvim-tree/nvim-web-devicons', config=function()
    require("bufferline").setup {
        options = {
            mode = "buffers",
            numbers = "none",
            separator_style = "slant", -- "slant", "padded_slant", "thick", or "thin"
            always_show_bufferline = true,
            show_buffer_close_icons = false,
            show_close_icon = false,
            color_icons = true,
            diagnostics = "nvim_lsp",
            diagnostics_indicator = function(count, level)
                local icon = level:match("error") and " " or " "
                return " " .. icon .. count
            end,
            offsets = {
                {
                    filetype = "NvimTree",
                    text = "File Explorer",
                    text_align = "center",
                    highlight = "Directory",
                    separator = true,
                },
            },
        },
        highlights = require("catppuccin.special.bufferline").get_theme()
    }


    vim.keymap.set("n", "<Tab>", vim.cmd.BufferLineCycleNext)
    vim.keymap.set("n", "<S-Tab>", vim.cmd.BufferLineCyclePrev)
    vim.keymap.set("n", "<leader>bp", vim.cmd.BufferLinePick)
end}
