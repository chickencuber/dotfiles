if exists('b:current_syntax')
  finish
endif

" =====================
" SimpleIR (.sir) syntax
" =====================

setlocal commentstring=;\ %s

syntax clear

" -----------------
" COMMENTS
syntax match sirComment ";.*$"
highlight link sirComment Comment

" -----------------
" KEYWORDS / INSTRS
syntax keyword sirKeyword global extern jmp call ret
highlight link sirKeyword Keyword

" -----------------
" REGISTERS (r0, r1)
syntax match sirRegister "\<r[0-9]\+\>"
highlight link sirRegister Identifier

" -----------------
" FUNCTION HEADER
" func name arg1 arg2:
syntax region sirFuncHeader
  \ start="^\s*\(export\s\+\)\?func\>"
  \ end=":"
  \ keepend
  \ contains=sirFuncKeyword,sirFuncName,sirFuncArg

syntax keyword sirFuncKeyword func contained
highlight link sirFuncKeyword Keyword

syntax match sirFuncName "\<[a-zA-Z_][a-zA-Z0-9_]*\>"
  \ contained
  \ nextgroup=sirFuncArg
  \ skipwhite
highlight link sirFuncName Function

syntax match sirFuncArg "\<[a-zA-Z_][a-zA-Z0-9_]*\>"
  \ contained
  \ nextgroup=sirFuncArg
  \ skipwhite
highlight link sirFuncArg Identifier

" -----------------
" LABELS (non-func)
syntax match sirLabel "^\s*[a-zA-Z_][a-zA-Z0-9_]*:"
  \ contains=NONE
highlight link sirLabel Label

" -----------------
" NUMBERS
syntax match sirNumber "\<[0-9]\+\>"
highlight link sirNumber Number

" -----------------
" STRINGS
syntax match sirString +".\{-}"+
highlight link sirString String

let b:current_syntax = 'sir'
