" vim-textdecor: Box command (shim that lazy-loads autoload code)
if exists('g:loaded_textdecor_box') | finish | endif
let g:loaded_textdecor_box = 1

" :Box [style] [minwidth or width=NN] [inner align] [outer align] [screen=NN or @NN]
" style: '-', '=', '+'
" inner align: left | right | center | centerblock(cblock|c1|c2)
" outer align: outer=left|center|right OR oleft|ocenter|oright
command! -range -nargs=? Box <line1>,<line2>call textdecor#box#Selection(<line1>, <line2>, <q-args>)


" plugin/textdecor_box.vim (append this near :Box)
" command! -range -nargs=0 Unbox <line1>,<line2>call textdecor#box#Unbox(<line1>, <line2>)

" plugin/textdecor_box.vim
" command! -range -nargs=0 Unbox call textdecor#box#UnboxCmd(<range>)

" plugin/textdecor_box.vim
" command! -nargs=0 Unbox call textdecor#box#UnboxAuto()

" plugin/textdecor_box.vim
command! -nargs=0 Unbox call textdecor#box#UnboxAuto()
