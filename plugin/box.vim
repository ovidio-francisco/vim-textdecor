if exists('g:loaded_textdecor_box') | finish | endif
let g:loaded_textdecor_box = 1

" :Box → wizard (if no args) or direct (if args provided)
" command! -range -nargs=* Box <line1>,<line2>call textdecor#box#Invoke(<line1>, <line2>, <q-args>, <range>)


" plugin/textdecor_box.vim
command! -range -nargs=* Box <line1>,<line2>call textdecor#box#Invoke(<line1>, <line2>, <q-args>, <range>)


command! -nargs=0 Unbox call textdecor#box#UnboxAuto()


" :Box [style] [minwidth or width=NN] [inner align] [outer align] [screen=NN or @NN]
" style: '-', '=', '+'
" inner align: left | right | center | centerblock(cblock|c1|c2)
" outer align: outer=left|center|right OR oleft|ocenter|oright
