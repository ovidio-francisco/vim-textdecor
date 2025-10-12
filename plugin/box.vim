" =============== [ Box ] ================


function! BoxSelection(first, last, ...) range
  " Args: style key, min width, inner align, outer align, screen width
  let l:style_key = (a:0 >= 1 ? a:1 : '-')
  let l:min_width = (a:0 >= 2 ? str2nr(a:2) : 20)
  let l:align     = (a:0 >= 3 ? a:3 : 'left')     " inner text alignment
  let l:outer     = (a:0 >= 4 ? a:4 : 'none')     " box alignment: none|left|center|right
  let l:screenw   = (a:0 >= 5 ? str2nr(a:5) : (&textwidth > 0 ? &textwidth : 0))

  " Get lines and rtrim trailing spaces (keep leading indent)
  let l:raw   = getline(a:first, a:last)
  let l:lines = map(copy(l:raw), "substitute(v:val, '\\s\\+$', '', '')")

  " Measure content width (tabs/multibyte aware)
  let l:maxw  = max(map(copy(l:lines), 'strdisplaywidth(v:val)'))
  let l:width = max([l:maxw, l:min_width])

  " Styles (compact strings → split to chars)
  let l:styles = {
        \ '-': {'top': '┌─┐', 'vert': '││', 'bottom': '└─┘'},
        \ '=': {'top': '╔═╗', 'vert': '║║', 'bottom': '╚═╝'},
        \ '+': {'top': '+-+', 'vert': '||', 'bottom': '+-+'},
        \ }
  let l:style = has_key(l:styles, l:style_key) ? l:styles[l:style_key] : l:styles['-']
  let [l:tl, l:hz, l:tr]  = split(l:style.top, '\zs')
  let [l:bl, l:hz2, l:br] = split(l:style.bottom, '\zs')
  let [l:vl, l:vr]        = split(l:style.vert, '\zs')

  let l:top    = l:tl . repeat(l:hz, l:width + 2) . l:tr
  let l:bottom = l:bl . repeat(l:hz, l:width + 2) . l:br

  " Inner alignment helpers
  let l:block_left = float2nr((l:width - l:maxw) / 2)
  function! s:Align(line, width, align, block_left)
    let l:w = strdisplaywidth(a:line)
    let l:pad = a:width - l:w
    if l:pad < 0 | let l:pad = 0 | endif
    if a:align ==# 'center' || a:align ==# 'c1'
      let l:left  = float2nr(l:pad / 2)
      let l:right = l:pad - l:left
      return repeat(' ', l:left) . a:line . repeat(' ', l:right)
    elseif a:align ==# 'centerblock' || a:align ==# 'cblock' || a:align ==# 'c2'
      let l:left  = a:block_left
      let l:right = a:width - l:left - l:w
      if l:right < 0 | let l:right = 0 | endif
      return repeat(' ', l:left) . a:line . repeat(' ', l:right)
    elseif a:align ==# 'right'
      return repeat(' ', l:pad) . a:line
    else
      return a:line . repeat(' ', l:pad)
    endif
  endfunction

  " Build boxed lines (no outer margin yet)
  let l:boxed = [l:top]
  for l in l:lines
    let l:aligned = s:Align(l, l:width, l:align, l:block_left)
    call add(l:boxed, l:vl . ' ' . l:aligned . ' ' . l:vr)
  endfor
  call add(l:boxed, l:bottom)

  " ---- Outer (box) alignment against screen width ----
  if l:outer !=# 'none' && l:screenw > 0
    " visible width of the box line (same for top/bottom/body)
    let l:boxw = strdisplaywidth(l:boxed[0])
    let l:ml = 0
    if l:outer ==# 'center'
      let l:ml = float2nr((l:screenw - l:boxw) / 2)
    elseif l:outer ==# 'right'
      let l:ml = l:screenw - l:boxw
    else
      let l:ml = 0
    endif
    if l:ml < 0 | let l:ml = 0 | endif
    let l:margin = repeat(' ', l:ml)
    let l:boxed  = map(l:boxed, 'l:margin . v:val')
  endif
  " ---------------------------------------------------

  " Safe replace (no eating following lines)
  let l:sel_len = a:last - a:first + 1
  let l:box_len = len(l:boxed)
  if l:box_len <= l:sel_len
    call setline(a:first, l:boxed)
    if l:sel_len > l:box_len
      call deletebufline('', a:first + l:box_len, a:last)
    endif
  else
    call setline(a:first, l:boxed[0 : l:sel_len - 1])
    call append(a:first + l:sel_len - 1, l:boxed[l:sel_len :])
  endif
endfunction

" Wrapper parses args in any order:
"   style: '-', '=', '+'
"   width:  number or width=NN / w=NN / min=NN
"   inner alignment: left|right|center|centerblock|cblock|c1|c2
"   outer alignment: outer=left|center|right or oleft|ocenter|oright
"   screen width:    screen=NN / s=NN / page=NN
function! s:BoxCmd(line1, line2, qargs) range
  let l:style = '-'
  let l:minw  = 20
  let l:align = 'left'
  let l:outer = 'none'
  let l:screenw = (&textwidth > 0 ? &textwidth : 0)

  if !empty(a:qargs)
    for tok in split(a:qargs)
      if tok =~# '^\d\+$' | let l:minw = str2nr(tok)
      elseif tok =~# '^\%(w\|width\|min\)=\d\+$'   | let l:minw = str2nr(matchstr(tok, '\d\+'))
      elseif tok =~# '^\%(s\|screen\|page\)=\d\+$' | let l:screenw = str2nr(matchstr(tok, '\d\+'))
      elseif index(['-','+','='], tok) >= 0        | let l:style = tok
      elseif tok =~? '^\(left\|right\|center\|centerblock\|cblock\|c1\|c2\)$'
        let l:align = tolower(tok)
      elseif tok =~? '^outer=\(left\|center\|right\)$'
        let l:outer = tolower(matchstr(tok, '=\zs.*'))
      elseif tok =~? '^o\(left\|center\|right\)$'
        let l:outer = tolower(matchstr(tok, '^o\zs.*'))
      endif
    endfor
  endif

  call BoxSelection(a:line1, a:line2, l:style, l:minw, l:align, l:outer, l:screenw)
endfunction

" :Box [style] [minwidth or width=NN] [inner align] [outer align] [screen=NN]
command! -range -nargs=? Box <line1>,<line2>call <SID>BoxCmd(<line1>, <line2>, <q-args>)
