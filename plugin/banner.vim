if exists('g:loaded_textdecor_banner') | finish | endif
let g:loaded_textdecor_banner = 1

" :Banner (works on current line or a range)
command! -range=% Banner call textdecor#banner#Run(<line1>, <line2>)

" Your existing mappings (unchanged)
nnoremap <silent> <leader>af :<C-u>call textdecor#banner#Run(line('.'), line('.'))<CR>
xnoremap <silent> <leader>af :<C-u>call textdecor#banner#Run(line("'<"), line("'>"))<CR>



