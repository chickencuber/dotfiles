return {
    "goolord/alpha-nvim",
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
        local alpha = require("alpha")
        local dashboard = require("alpha.themes.dashboard")
        dashboard.section.header.val = {
            "                                                     ",
            "  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ",
            "  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ",
            "  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ",
            "  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ",
            "  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ",
            "  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ",
            "                                                     ",
        }

        dashboard.section.buttons.val = {
            dashboard.button( "e", "  > New file" , ":ene <BAR> startinsert <CR>"),
            --TASK(20260423-221559-440-n6-782): add the prmn stuff
            dashboard.button( "p", " > Projects", ":Prmn <CR>"),
            dashboard.button( "l", " > Last Project", ":Prmn l <CR>"),
            dashboard.button( "f", " > Find Project", ":Prmn f <CR>"),
            dashboard.button( "u", "  > Update Plugins" , ":Lazy update <CR>"),
            dashboard.button( "c", "  > Config" , ":e $MYVIMRC | :cd %:p:h | split . | wincmd k | pwd<CR>"),
            dashboard.button( "q", "  > Quit NVIM", ":qa<CR>"),
        }

        alpha.setup(dashboard.opts)

        vim.cmd([[
        autocmd FileType alpha setlocal nofoldenable
        ]])
    end
}
