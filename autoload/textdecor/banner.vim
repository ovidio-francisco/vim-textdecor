" =======================
" Figlet ASCII Banner
" =======================

" User options with defaults (same names you used)
let g:figlet_font    = get(g:, 'figlet_font', 'standard')
let g:figlet_width   = get(g:, 'figlet_width', 80)
let g:figlet_center  = get(g:, 'figlet_center', 1)  " center blocks, not individual lines
let g:figlet_replace = get(g:, 'figlet_replace', 1)

function! s:FigletAvailable() abort
  if !executable('figlet')
    echohl ErrorMsg | echom "figlet not found in $PATH" | echohl None
    return 0
  endif
  return 1
endfunction

" Center a WHOLE block using integer math only (no floats)
function! s:CenterBlock(lines, target_width) abort
  if empty(a:lines) | return a:lines | endif

  " find max visual width
  let maxlen = 0
  for l in a:lines
    let w = strwidth(l)
    if w > maxlen | let maxlen = w | endif
  endfor

  let target = a:target_width
  if type(target) != v:t_number | let target = str2nr(target) | endif
  if target <= 0 | let target = maxlen | endif

  let gap = target - maxlen
  if gap <= 0 | return a:lines | endif
  let leftpad = gap >> 1    " floor(gap/2) using integer shift

  let pad = repeat(' ', leftpad)
  return map(copy(a:lines), {_, v -> pad . v})
endfunction

" Run figlet for ONE input line -> list of lines (no centering here)
function! s:FigletOne(text, font, width) abort
  if !s:FigletAvailable()
    return []
  endif
  let font  = empty(a:font) ? g:figlet_font : a:font
  let width = a:width > 0 ? a:width : g:figlet_width

  " We avoid figlet -c so we control padding ourselves.
  let cmd   = 'figlet -f ' . shellescape(font) . ' -w ' . string(width)
  " Soft-wrap and trim trailing spaces (keep leading spaces).
  let pipe  = ' | fold -s -w ' . string(width) . ' | sed "s/[ \t]\\+$//"'
  return systemlist(cmd . pipe, a:text)
endfunction

" PUBLIC ENTRY: processes each input line as one block
function! textdecor#banner#Run(start, end) abort
  let start = a:start > 0 ? a:start : line('.')
  let end   = a:end   > 0 ? a:end   : start
  let lines = getline(start, end)
  if empty(lines)
    echohl WarningMsg | echom "No text to figlet" | echohl None
    return
  endif

  " Ask for font (same prompt as your version)
  let font = input("Figlet font [" . g:figlet_font . "]: ")
  if empty(font)
    let font = g:figlet_font
  endif

  " Generate blocks per input line
  let blocks = []
  for l in lines
    if empty(l)
      call add(blocks, [''])    " preserve empty line as spacer
    else
      call add(blocks, s:FigletOne(l, font, g:figlet_width))
    endif
  endfor

  " Center each block uniformly to target width if requested
  let target = &textwidth > 0 ? &textwidth : g:figlet_width
  let art = []
  for b in blocks
    let blk = g:figlet_center ? s:CenterBlock(b, target) : b
    call extend(art, blk)
    " add a blank line between non-empty blocks (nice separation)
    if !empty(filter(copy(blk), 'v:val !=# ""'))
      call add(art, '')
    endif
  endfor
  " Trim trailing blank lines
  while !empty(art) && art[-1] ==# ''
    call remove(art, -1)
  endwhile

  if empty(art)
    echohl WarningMsg | echom "No output from figlet" | echohl None
    return
  endif

  " Replace selection or append, per your g:figlet_replace
  if g:figlet_replace
    call setline(start, art[0])
    if end > start
      execute (start+1) . ',' . end . 'delete _'
    endif
    if len(art) > 1
      call append(start, art[1:])
    endif
  else
    call append(end, art)
  endif
endfunction
