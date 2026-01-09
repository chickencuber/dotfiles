return {
    "jake-stewart/multicursor.nvim",
    config = function()
        local mc = require("multicursor-nvim")
        mc.setup()

        vim.keymap.set({"n", "x"}, "<C-k>", function() mc.lineAddCursor(-1) end)
        vim.keymap.set({"n", "x"}, "<C-j>", function() mc.lineAddCursor(1) end)
        vim.keymap.set({"n", "x"}, "<leader><C-k>", function() mc.lineSkipCursor(-1) end)
        vim.keymap.set({"n", "x"}, "<leader><C-j>", function() mc.lineSkipCursor(1) end)

        vim.keymap.set({"n", "x"}, "<leader>*", function() mc.matchAddCursor(1) end)
        vim.keymap.set({"n", "x"}, "*", function() mc.matchAllAddCursors() end)

        vim.keymap.set("n", "<c-leftmouse>", mc.handleMouse)
        vim.keymap.set("n", "<c-leftdrag>", mc.handleMouseDrag)
        vim.keymap.set("n", "<c-leftrelease>", mc.handleMouseRelease)

        mc.addKeymapLayer(function(layerSet)

            layerSet({"n", "x"}, "<C-h>", mc.prevCursor)
            layerSet({"n", "x"}, "<C-l>", mc.nextCursor)

            layerSet({"n", "x"}, "<leader>x", mc.deleteCursor)

            layerSet("n", "<esc>", function()
                if not mc.cursorsEnabled() then
                    mc.enableCursors()
                else
                    mc.clearCursors()
                end
            end)
        end)

        -- Customize how cursors look.
        local hl = vim.api.nvim_set_hl
        hl(0, "MultiCursorCursor", { reverse = true })
        hl(0, "MultiCursorVisual", { link = "Visual" })
        hl(0, "MultiCursorSign", { link = "SignColumn"})
        hl(0, "MultiCursorMatchPreview", { link = "Search" })
        hl(0, "MultiCursorDisabledCursor", { reverse = true })
        hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
        hl(0, "MultiCursorDisabledSign", { link = "SignColumn"})
    end
}
