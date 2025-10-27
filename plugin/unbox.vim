if exists('g:loaded_textdecor_unbox_cmd') | finish | endif
let g:loaded_textdecor_unbox_cmd = 1

command! -range -nargs=0 Unbox     call textdecor#box#unboxauto()
command! -range -nargs=0 UnboxAuto call textdecor#box#unboxauto()
command! -range -nargs=0 UnboxExact <line1>,<line2>call textdecor#box#unbox(<line1>, <line2>)


