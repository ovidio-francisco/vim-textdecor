function! textdecor#box#Unbox(first, last) range abort
  let raw = getline(a:first, a:last)
  if empty(raw) | return | endif

  " 1) Remove top & bottom borders (ASCII + Unicode)
  let hz         = '─═-'
  let top_pat    = '^\s*['.'┌╔+'.']['.hz.']\+['.'┐╗+'.']\s*$'
  let bottom_pat = '^\s*['.'└╚+'.']['.hz.']\+['.'┘╝+'.']\s*$'

  let start = 0
  let endi  = len(raw) - 1
  if raw[0]  =~# top_pat    | let start += 1 | endif
  if raw[-1] =~# bottom_pat | let endi  -= 1 | endif

  let body = start <= endi ? raw[start : endi] : []
  if empty(body)
    call setline(a:first, [])
    if a:first <= a:last | call deletebufline('', a:first, a:last) | endif
    return
  endif

  " 2) Strip vertical borders with any left margin & inner padding (non-greedy)
  "    sides: │ ║ |
  let side_pat = '^\s*['.'│║|'.']\s*\(.\{-}\)\s*['.'│║|'.']\s*$'

  let inner = []
  for v in body
    if v =~# side_pat
      let line = substitute(v, side_pat, '\1', '')
    else
      let line = v
    endif
    " 3) Trim only non-blank lines
    if line =~# '^\s*$'
      call add(inner, '')
    else
      " use trim() if available, else fallback
      if exists('*trim')
        call add(inner, trim(line))
      else
        call add(inner, substitute(line, '^\s\+|\s\+$', '', 'g'))
      endif
    endif
  endfor

  " 4) Join consecutive non-blank lines into paragraphs
  " 5) Preserve blank lines
  let out = []
  let acc = []
  for L in inner
    if L ==# ''
      if !empty(acc)
        " collapse internal runs of spaces after joining
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

  " Replace selection safely
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


function! textdecor#box#UnboxAuto() range abort
  let first = a:firstline
  let last  = a:lastline

  " If user provided an explicit range (e.g. Visual), use it directly.
  " Heuristic: range spans multiple lines OR differs from the cursor line.
  if (first != last) || (first != line('.'))
    call textdecor#box#Unbox(first, last)
    return
  endif

  " --- border detection as you have ---
  let hz         = '─═-'
  let top_pat    = '^\s*['.'┌╔+'.']['.hz.']\+['.'┐╗+'.']\s*$'
  let bottom_pat = '^\s*['.'└╚+'.']['.hz.']\+['.'┘╝+'.']\s*$'

  let lnum = line('.')
  let top  = 0
  while lnum >= 1
    let L = getline(lnum)
    if L =~# top_pat
      let top = lnum | break
    endif
    let lnum -= 1
  endwhile

  if top > 0
    let cur = top + 1
    let bot = 0
    while cur <= line('$')
      let L = getline(cur)
      if L =~# bottom_pat
        let bot = cur | break
      endif
      let cur += 1
    endwhile
    if bot > 0
      call textdecor#box#Unbox(top, bot)
      return
    endif
  endif

  " --- paragraph fallback (no borders) ---
  let s = line('.')
  while s > 1 && getline(s - 1) !~# '^\s*$' | let s -= 1 | endwhile
  let e = line('.')
  while e < line('$') && getline(e + 1) !~# '^\s*$' | let e += 1 | endwhile

  if s > e || join(getline(s, e), '') =~# '^\s*$'
    echohl WarningMsg | echom 'Unbox: nothing to unbox here.' | echohl None
    return
  endif

  call textdecor#box#Unbox(s, e)
endfunction

