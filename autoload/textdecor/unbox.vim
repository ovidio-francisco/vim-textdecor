function! textdecor#unbox#Unbox(first, last) range abort
  let raw = getline(a:first, a:last)
  if empty(raw) | return | endif

  " Known box-drawing top/bottom
  let hz         = '─═-'
  let top_pat    = '^\s*['.'┌╔+'.']['.hz.']\+['.'┐╗+'.']\s*$'
  let bottom_pat = '^\s*['.'└╚+'.']['.hz.']\+['.'┘╝+'.']\s*$'

  " Generic "solid line of a single char" (e.g., *****, =====, #####)
  let solid_pat  = '^\s*\(\S\)\1\{2,}\s*$'

  " 1) Remove top & bottom borders (supports both families)
  let start = 0
  let endi  = len(raw) - 1

  if raw[0]  =~# top_pat  || raw[0]  =~# solid_pat | let start += 1 | endif
  if raw[-1] =~# bottom_pat || raw[-1] =~# solid_pat | let endi  -= 1 | endif

  let body = start <= endi ? raw[start : endi] : []
  if empty(body)
    call setline(a:first, [])
    if a:first <= a:last | call deletebufline('', a:first, a:last) | endif
    return
  endif

  " Try to infer a single-char border for sides (e.g., '* ... *')
  " Only if BOTH top and bottom are solid lines with THE SAME char.
  let bc = ''
  let mtop = matchlist(raw[0], solid_pat)
  let mbot = matchlist(raw[-1], solid_pat)
  if !empty(mtop) && !empty(mbot) && mtop[1] ==# mbot[1]
    let bc = mtop[1]
  endif

  " Build side pattern:
  " - If bc is known, strip that exact char from both sides.
  " - Else, fall back to Unicode/ASCII sides as before.
  if bc !=# ''
    " Escape regex specials for a char class
    let esc = escape(bc, '^$.*~[]\')
    " allow any left margin, optional inner padding, then same border on the right
    let side_pat = '^\s*['.esc.']\s*\(.\{-}\)\s*['.esc.']\s*$'
  else
    let side_pat = '^\s*['.'│║|'.']\s*\(.\{-}\)\s*['.'│║|'.']\s*$'
  endif

  " 2) Strip vertical borders & trim (preserve blank lines)
  let inner = []
  for v in body
    if v =~# side_pat
      let line = substitute(v, side_pat, '\1', '')
    else
      let line = v
    endif
    if line =~# '^\s*$'
      call add(inner, '')
    else
      if exists('*trim')
        call add(inner, trim(line))
      else
        call add(inner, substitute(line, '^\s\+|\s\+$', '', 'g'))
      endif
    endif
  endfor

  " 3) Join consecutive non-blank lines into paragraphs, preserving blank lines
  let out = []
  let acc = []
  for L in inner
    if L ==# ''
      if !empty(acc)
        let para = join(acc, ' ')
        let para = substitute(para, '\s\{2,}', ' ', 'g')
        call add(out, para)
        let acc = []
      endif
      call add(out, '')
    else
      call add(acc, L)
    endif
  endfor
  if !empty(acc)
    let para = join(acc, ' ')
    let para = substitute(para, '\s\{2,}', ' ', 'g')
    call add(out, para)
  endif

  " 4) Replace selection safely
  let sel_len = a:last - a:first + 1
  if len(out) <= sel_len
    call setline(a:first, out)
    if sel_len > len(out)
      call deletebufline('', a:first + len(out), a:last)
    endif
  else
    call setline(a:first, out[0 : sel_len - 1])
    call append(a:first + sel_len - 1, out[sel_len :])
  endif
endfunction


function! textdecor#unbox#UnboxAuto() range abort
  " Visual selection: unbox that exact range
  if a:firstline != a:lastline
    call textdecor#unbox#Unbox(a:firstline, a:lastline)
    return
  endif

  " Blank line → do nothing
  if getline('.') =~# '^\s*$'
    return
  endif

  " Known box-drawing + generic solid lines
  let hz         = '─═-'
  let top_pat    = '^\s*['.'┌╔+'.']['.hz.']\+['.'┐╗+'.']\s*$'
  let bottom_pat = '^\s*['.'└╚+'.']['.hz.']\+['.'┘╝+'.']\s*$'
  let solid_pat  = '^\s*\(\S\)\1\{2,}\s*$'

  " Look up until blank line for top border (either known or generic solid)
  let lnum = line('.')
  let top  = 0
  while lnum >= 1 && getline(lnum) !~# '^\s*$'
    let L = getline(lnum)
    if L =~# top_pat || L =~# solid_pat
      let top = lnum
      break
    endif
    let lnum -= 1
  endwhile

  " If top found, search down until blank line for bottom border
  if top > 0
    let cur = top + 1
    let bot = 0
    while cur <= line('$') && getline(cur) !~# '^\s*$'
      let L = getline(cur)
      if L =~# bottom_pat || L =~# solid_pat
        let bot = cur
        break
      endif
      let cur += 1
    endwhile
    if bot > 0
      call textdecor#unbox#Unbox(top, bot)
      return
    endif
  endif

  " Borderless heuristic (your original)
  let s = line('.')
  while s > 1 && getline(s - 1) !~# '^\s*$' | let s -= 1 | endwhile
  let e = line('.')
  while e < line('$') && getline(e + 1) !~# '^\s*$' | let e += 1 | endwhile
  let lines = getline(s, e)

  if len(filter(copy(lines), 'v:val !~# "^\s*$"')) < 2
    return
  endif

  for L in lines
    if L =~# top_pat || L =~# bottom_pat || L =~# solid_pat
      return
    endif
  endfor

  let min_indent = -1
  let widths = {}
  for L in lines
    if L =~# '^\s*$' | continue | endif
    let li = len(matchstr(L, '^\s*'))
    let min_indent = (min_indent < 0 ? li : (li < min_indent ? li : min_indent))
    let widths[len(L)] = 1
  endfor

  if min_indent > 0 || len(keys(widths)) == 1
    call textdecor#unbox#Unbox(s, e)
  endif
endfunction
