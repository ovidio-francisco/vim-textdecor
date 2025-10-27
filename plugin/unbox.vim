if exists('g:loaded_textdecor_unbox_cmd') | finish | endif
let g:loaded_textdecor_unbox_cmd = 1

" Expose :Unbox, implemented in autoload/textdecor/box.vim
command! -nargs=0 Unbox call textdecor#box#UnboxAuto()
