if exists('g:loaded_textdecor_unbox_cmd') | finish | endif
let g:loaded_textdecor_unbox_cmd = 1

" Unbox (auto): works with or without a visual range.
" - With a visual/explicit range: passes <line1>,<line2> to UnboxAuto()
" - Without range: UnboxAuto() detects borders; if none, falls back to paragraph
command! -range -nargs=0 Unbox <line1>,<line2>call textdecor#box#UnboxAuto(<line1>, <line2>)

" Explicit Auto command (same behavior as :Unbox; kept for clarity/compat)
command! -range -nargs=0 UnboxAuto <line1>,<line2>call textdecor#box#UnboxAuto(<line1>, <line2>)

" Optional: a strict range version that always treats the given range as the box
" (useful if you want to bypass auto-detection entirely)
command! -range -nargs=0 UnboxExact <line1>,<line2>call textdecor#box#Unbox(<line1>, <line2>)
