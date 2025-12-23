return {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
        -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
        "MunifTanjim/nui.nvim",
    },
    config=function()
        require("noice").setup({
            presets = {
                command_palette = true, -- position the cmdline and popupmenu together
            },
        })
    end
}
