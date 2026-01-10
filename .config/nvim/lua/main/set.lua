vim.opt.nu = true
vim.opt.relativenumber = true
vim.opt.cursorline = true;

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50

vim.opt.colorcolumn = "80"

vim.o.shell = "/usr/bin/fish"

vim.api.nvim_create_user_command('Lib', function(args)
    print(vim.fn.system("prmn lib " .. args.args))
end, {nargs = "?"})
vim.cmd [[
set mouse=
]]

vim.filetype.add({
    extension = {
        jspp="jspp",
    },
})
local augroup = vim.api.nvim_create_augroup("numbertoggle", {})

vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained", "CmdlineLeave", "WinEnter" }, {
    pattern = "*",
    group = augroup,
    callback = function()
        if vim.o.nu and vim.api.nvim_get_mode().mode ~= "i" then
            vim.opt.relativenumber = true
            vim.opt.cursorline = true;
        end
    end,
})


vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost", "CmdlineEnter", "WinLeave" }, {
    pattern = "*",
    group = augroup,
    callback = function()
        if vim.o.nu then
            vim.opt.relativenumber = false
            vim.opt.cursorline = false;
            if not vim.tbl_contains({"@", "-"}, vim.v.event.cmdtype) then
                vim.cmd "redraw"
            end
        end
    end,
})

-- for notes
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "org", "norg", "gitcommit" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.breakindent = true

    vim.opt_local.spell = true
  end,
})

