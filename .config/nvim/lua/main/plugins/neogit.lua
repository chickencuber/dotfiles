return {
    "NeogitOrg/neogit",
    dependencies = {
        "nvim-lua/plenary.nvim",         -- required
        "sindrets/diffview.nvim",        -- optional - Diff integration
        "nvim-telescope/telescope.nvim", -- optional
    },
    config = function()
        local neogit = require('neogit')

        vim.keymap.set("n", "<leader>gs", function()
            local buf_type = vim.bo.buftype
            local dir

            if buf_type == "terminal" then
                -- Terminal buffer: use its cwd
                local ok, term_cwd = pcall(vim.api.nvim_buf_get_var, 0, "terminal_cwd")
                dir = (ok and term_cwd) or vim.uv.cwd()
            else
                -- Normal buffer: use file's directory
                local buf_path = vim.api.nvim_buf_get_name(0)
                dir = (buf_path ~= "" and vim.fn.fnamemodify(buf_path, ":h")) or vim.uv.cwd()
            end

            -- Ensure we have a valid string
            dir = dir or ""

            -- Get git root if inside a repo
            local git_root = vim.fn.systemlist("git -C " .. vim.fn.shellescape(dir) .. " rev-parse --show-toplevel")[1]
            if not git_root or git_root == "" then
                git_root = dir
            end

            neogit.open({ kind = "split_above", cwd = git_root })
        end)
    end

}
