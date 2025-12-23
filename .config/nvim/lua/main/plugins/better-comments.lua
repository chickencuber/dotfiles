return {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
        keywords = {
            TODO = {
                alt={"TASK"}
            },
        },
        highlight = {
            pattern = [[.*<(KEYWORDS).]],
            keyword="fg"
        },
        search = {
            pattern = [[\b(KEYWORDS).]],
        },
    }
}
