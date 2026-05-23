vim.opt.nu = true
vim.opt.relativenumber = true
vim.opt.cursorline = true;

vim.env.PATH = vim.fn.trim(vim.fn.system('fish -c "printf %s \\"$PATH\\""'))

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

local prmn = nil
vim.api.nvim_create_user_command("Prmn", function(opts)
    if prmn ~= nil then
        vim.fn.jobstop(prmn)
        prmn = nil
    end
    local args = opts.args
    local cmd = { "prmn", "-o" }
    for _, v in ipairs(vim.split(args, " ")) do
        if v == "" then
            goto continue
        end
        table.insert(cmd, v)
        ::continue::
    end

    local buf = vim.api.nvim_create_buf(false, true)

    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.8)

    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = math.floor((vim.o.lines - height) / 2),
        col = math.floor((vim.o.columns - width) / 2),
        style = "minimal",
        border = "rounded",
    })

    prmn = vim.fn.jobstart(cmd, {
        term = true,
        on_exit = function()
            local s = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
            vim.api.nvim_win_close(win, true);
            prmn = nil
            if s ~= "" then
                vim.cmd.cd(s)
                vim.cmd.lcd(s)
                vim.cmd.tcd(s)
                vim.cmd.edit(s)
            end
        end
    })
    vim.api.nvim_create_autocmd("BufLeave", {
        buffer = buf,
        once = true,
        callback = function()
            vim.fn.jobstop(prmn)
        end,
    })
    vim.api.nvim_create_autocmd("TermLeave", {
        buffer = buf,
        callback = function()
            vim.fn.jobstop(prmn)
        end,
    })
    vim.cmd("startinsert")
end, { nargs = '*' })

vim.filetype.add({
    extension = {
        jspp = "jspp",
        h    = "c",
        hpp  = "cpp",
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
            if not vim.tbl_contains({ "@", "-" }, vim.v.event.cmdtype) then
                vim.cmd "redraw"
            end
        end
    end,
})

-- for notes
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "markdown", "org", "norg", "gitcommit", "text" },
    callback = function()
        vim.opt_local.wrap = true
        vim.opt_local.linebreak = true
        vim.opt_local.breakindent = true

        vim.opt_local.spell = true
    end,
})
