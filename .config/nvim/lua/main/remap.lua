vim.g.mapleader = " "

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", {silent=true})
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", {silent=true})

vim.keymap.set({"n", "v", "o"}, "j", function()
    return vim.v.count == 0 and "gj" or "j"
end, { expr = true, noremap = true })

vim.keymap.set({"n", "v", "o"}, "k", function()
    return vim.v.count == 0 and "gk" or "k"
end, { expr = true, noremap = true })


vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

vim.o.clipboard = "unnamedplus"

vim.keymap.set("n", "Q", "<nop>")

vim.keymap.set("n", "<leader>f", "mzggVG=`z")
vim.keymap.set("n", "<leader>y", "mzggVGy`z")
vim.keymap.set("n", "<leader>d", "mzggVGd`z")
vim.keymap.set('n', '<leader>pp', 'ggVG"_dp')
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })
vim.keymap.set("n", "<leader>%", "ggVG")

vim.keymap.set("n", "<leader><leader>", function()
    vim.cmd("so")
end)

vim.keymap.set("n", '<leader>tm', vim.cmd.term)
vim.keymap.set("t", "<S-Tab>", "<C-\\><C-n>")
vim.keymap.set("n", "<leader>cb", vim.cmd.bd)


vim.keymap.set("n", "tf", vim.cmd.TaskFromTodo)
vim.keymap.set("n", "gt", vim.cmd.TaskGoto)
vim.keymap.set("n", "tk", vim.cmd.TaskMenu)
vim.keymap.set("n", "tg", vim.cmd.TaskGenerateMarkdown)
vim.keymap.set("n", "tl", function()
    vim.cmd.TaskMenu("show_closed")
end)


vim.keymap.set("n", "ty", vim.cmd.TaskYank)

vim.keymap.set("n", "<leader>tt", function()
    local ft = vim.bo.filetype
    if ft == "markdown" or ft == "norg" then
        require('toggle-checkbox').toggle()
    end
end)
