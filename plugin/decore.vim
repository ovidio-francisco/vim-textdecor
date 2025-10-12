
if exists('g:loaded_textdecor_decore') | finish | endif
let g:loaded_textdecor_decore = 1

" :Decore [total] [filler] [enclosers]
" :DecoreSmart [filler] [countlen]
command! -nargs=* Decore      call textdecor#decore#Decore(<f-args>)
command! -nargs=* DecoreSmart call textdecor#decore#DecoreSmart(<f-args>)










