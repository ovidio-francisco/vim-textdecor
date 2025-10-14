" vim-textdecor: Lorem (lazy)
if exists('g:loaded_textdecor_lorem') | finish | endif
let g:loaded_textdecor_lorem = 1

" :Lorem             -> 1 paragraph, 5 sentences
" :Lorem 4           -> 1 paragraph, 4 sentences
" :Lorem 3 7         -> 3 paragraphs, 7 sentences
command! -nargs=* Lorem call textdecor#lorem#Run(<f-args>)
