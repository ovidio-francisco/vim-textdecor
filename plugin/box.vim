if exists('g:loaded_textdecor_box') | finish | endif
let g:loaded_textdecor_box = 1

" :Box → wizard (if no args) or direct (if args provided)
command! -range -nargs=* Box <line1>,<line2>call textdecor#box#Invoke(<line1>, <line2>, <q-args>, <range>)

command! -nargs=0 Unbox call textdecor#box#UnboxAuto()


