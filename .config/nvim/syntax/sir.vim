if exists('b:current_syntax')
    finish
endif
" Vim syntax for SimpleIR (.sir)

" COMMENT
setlocal commentstring=;\ %s
syntax match sirComment ";.*$"
highlight link sirComment Comment

" INSTRUCTIONS
syntax keyword sirInstr jmp call ret 
highlight link sirInstr Keyword

" REGISTERS (like r1, r2)
syntax match sirRegister "r[0-9]\+"
highlight link sirRegister Identifier

" FUNCTION LABELS (func name:)
syntax match sirFuncLabel "^\s*func\s\+\w\+:"
highlight link sirFuncLabel Function

" NORMAL LABELS (like loop:)
syntax match sirLabel "^\s*\w\+:"
highlight link sirLabel Label

" NUMBERS
syntax match sirNumber "\d\+"
highlight link sirNumber Number



let b:current_syntax = 'sir'
