return {
    'nvim-orgmode/orgmode',
    event = 'VeryLazy',
    ft = { 'org' },
    config = function()
        require('orgmode').setup({
            org_agenda_files = '~/orgfiles/**/*',
            org_startup_indented = true,
            org_default_notes_file = '~/orgfiles/refile.org',
            org_startup_folded = "inherit",
            mappings = {
                org = {
                    org_cycle=false,
                    org_global_cycle=false,
                    org_toggle_checkbox="<leader>tt"
                },
            },
        })
    end,
}
