return {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    lazy = false,
    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },
    config = function()
        vim.keymap.set("n", "<leader>pv", vim.cmd.NvimTreeToggle)
        print(vim.keymap.set)
        vim.g.loaded_netrw = 1
        vim.g.loaded_netrwPlugin = 1

        -- optionally enable 24-bit colour
        vim.opt.termguicolors = true

        -- empty setup using defaults
        require("nvim-tree").setup({
            hijack_unnamed_buffer_when_opening = true,
            sort = {
                sorter = "case_sensitive",
            },
            view = {
                width = 30,
            },
            renderer = {
                group_empty = true,
            },
            filters = {
                dotfiles = true,
            },
        })

        vim.api.nvim_create_autocmd("BufEnter", {
            callback = function(args)
                local buf_type = vim.bo[args.buf].buftype
                local buf_name = vim.api.nvim_buf_get_name(args.buf)
                if(buf_type == "terminal") then
                    vim.cmd('NvimTreeClose')
                    return
                end

                -- Ensure we are not in a terminal buffer or a modified buffer
                if buf_type == '' and buf_name ~= 'NvimTree' then
                    vim.cmd('NvimTreeClose')
                end
                if buf_name == "" and buf_type == '' and not vim.bo[args.buf].modified then
                    -- Delay the execution to ensure it's done in a proper context
                    vim.defer_fn(function()
                        if vim.fn.bufname() == "" then
                            vim.cmd('NvimTreeOpen')
                        end
                    end, 50)
                end
            end,
        })
    end,
}
