function! textdecor#box#Box(first, last, qargs) range
  " Defaults
  let l:style_key = '-'
  let l:min_width = 20
  let l:align     = 'left'     " inner: left|right|center|centerblock(cblock|c1|c2)
  let l:outer     = 'none'     " box: none|left|center|right
  let l:screenw   = (&textwidth > 0 ? &textwidth : 0)
  let l:explicit_width = 0     " set to >0 when user passed a width

  " Parse <q-args>
  if !empty(a:qargs)
    for tok in split(a:qargs)
      if tok =~# '^\d\+$'
        let l:min_width = str2nr(tok)
        let l:explicit_width = l:min_width
      elseif tok =~# '^\%(w\|width\|min\)=\d\+$'
        let l:min_width = str2nr(matchstr(tok, '\d\+'))
        let l:explicit_width = l:min_width
      elseif tok =~# '^\%(s\|screen\|page\)=\d\+$'
        let l:screenw = str2nr(matchstr(tok, '\d\+'))
      elseif tok =~# '^@\d\+$'
        let l:screenw = str2nr(tok[1:])
      elseif index(['-','+','='], tok) >= 0
        let l:style_key = tok
      elseif tok =~? '^\(left\|right\|center\|centerblock\|cblock\|c1\|c2\)$'
        let l:align = tolower(tok)
      elseif tok =~? '^outer=\(left\|center\|right\)$'
        let l:outer = tolower(matchstr(tok, '=\zs.*'))
      elseif tok =~? '^o\(left\|center\|right\)$'
        let l:outer = tolower(matchstr(tok, '^o\zs.*'))
      endif
    endfor
  endif

  " Get lines and rtrim trailing spaces (keep leading indent)
  let l:raw   = getline(a:first, a:last)
  let l:lines = map(copy(l:raw), "substitute(v:val, '\\s\\+$', '', '')")

  " Measure original content width
  let l:maxw_orig = max(map(copy(l:lines), 'strdisplaywidth(v:val)'))

  " Decide target content width (inside the box, excluding side padding)
  " - explicit width: honor it
  " - else if screen cap and content would overflow: cap to screen
  " - else: old behavior (no wrapping): grow to longest line
  if l:explicit_width > 0
    let l:width = max([l:explicit_width, 1])
    let l:do_wrap = 1
  elseif l:screenw > 0 && (l:maxw_orig + 4) > l:screenw
    " 4 = 2 side spaces + 2 borders (approx; borders are 2 chars)
    let l:width = max([l:screenw - 4, 1])
    let l:do_wrap = 1
  else
    let l:width = max([l:maxw_orig, l:min_width])
    let l:do_wrap = 0
  endif

  " Word-wrap helper (soft wrap at spaces; hard-break very long words)
  function! s:Wrap(line, width) abort
    if a:width <= 0 | return [a:line] | endif
    let words = split(a:line, '\s\+')
    if empty(words) | return [''] | endif

    let out = []
    let cur = ''
    for w in words
      let wlen = strdisplaywidth(w)
      if cur ==# ''
        " start a new line; if word longer than width, hard-break it
        if wlen <= a:width
          let cur = w
        else
          let start = 0
          while start < strlen(w)
            " slice by bytes; display width approximation is acceptable for long tokens
            let chunk = strpart(w, start, a:width)
            call add(out, chunk)
            let start += strlen(chunk)
          endwhile
          let cur = ''
        endif
      else
        let newlen = strdisplaywidth(cur) + 1 + wlen
        if newlen <= a:width
          let cur .= ' ' . w
        else
          call add(out, cur)
          if wlen <= a:width
            let cur = w
          else
            let start = 0
            while start < strlen(w)
              let chunk = strpart(w, start, a:width)
              call add(out, chunk)
              let start += strlen(chunk)
            endwhile
            let cur = ''
          endif
        endif
      endif
    endfor
    if cur !=# '' | call add(out, cur) | endif
    return out
  endfunction

  " If wrapping, expand logical lines into wrapped lines
  if l:do_wrap
    let l:wrapped = []
    for L in l:lines
      let parts = s:Wrap(L, l:width)
      if empty(parts)
        call add(l:wrapped, '')
      else
        call extend(l:wrapped, parts)
      endif
    endfor
    let l:lines = l:wrapped
    " After wrapping, recompute max visible width (should be <= l:width)
    let l:maxw  = max(map(copy(l:lines), 'strdisplaywidth(v:val)'))
    let l:width = max([l:maxw, l:width])   " keep at least the chosen width
  else
    let l:maxw  = l:maxw_orig
  endif

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

  " Outer (box) alignment against screen width
  if l:outer !=# 'none' && l:screenw > 0
    let l:boxw = strdisplaywidth(l:boxed[0])
    let l:ml = 0
    if l:outer ==# 'center'
      let l:ml = float2nr((l:screenw - l:boxw) / 2)
    elseif l:outer ==# 'right'
      let l:ml = l:screenw - l:boxw
    endif
    if l:ml < 0 | let l:ml = 0 | endif
    let l:margin = repeat(' ', l:ml)
    let l:boxed  = map(l:boxed, 'l:margin . v:val')
  endif

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



function! textdecor#box#UnboxAuto() abort
  " Regex for our three styles (ASCII + Unicode thin/thick)
  let hz         = '─═-'
  let top_pat    = '^\s*['.'┌╔+'.']['.hz.']\+['.'┐╗+'.']\s*$'
  let bottom_pat = '^\s*['.'└╚+'.']['.hz.']\+['.'┘╝+'.']\s*$'

  " 1) Find the nearest top border at/above the cursor
  let lnum = line('.')
  let top  = 0
  while lnum >= 1
    let L = getline(lnum)
    if L =~# top_pat
      let top = lnum
      break
    endif
    let lnum -= 1
  endwhile
  if top == 0
    echohl WarningMsg | echom 'Unbox: no top border found above cursor.' | echohl None
    return
  endif

  " 2) From the top border, find the bottom border below
  let cur = top + 1
  let bot = 0
  while cur <= line('$')
    let L = getline(cur)
    if L =~# bottom_pat
      let bot = cur
      break
    endif
    let cur += 1
  endwhile
  if bot == 0
    echohl WarningMsg | echom 'Unbox: no bottom border found below top.' | echohl None
    return
  endif

  " 3) Unbox exactly that range
  call textdecor#box#Unbox(top, bot)
endfunction




" Invoke: if no qargs, run wizard; else pass through
function! textdecor#box#Invoke(first, last, qargs, has_range) range abort
  if a:qargs ==# ''
    let spec = textdecor#box#Wizard()
    if empty(spec)
      " user cancelled
      return
    endif
    let qargs = spec
  else
    let qargs = a:qargs
  endif

  " If no range was supplied, be helpful: select paragraph (vip)
  if !a:has_range
    let view = winsaveview()
    silent! normal! vip
    let l1 = getpos("'<")[1]
    let l2 = getpos("'>")[1]
    call winrestview(view)
  else
    let l1 = a:first
    let l2 = a:last
  endif

  " Call your existing box function (rename Selection→Box if you did that)
  return textdecor#box#Box(l1, l2, qargs)
endfunction

" Wizard: ask for parameters, return a single qargs string compatible with parser
function! textdecor#box#Wizard() abort
  " Defaults (match your current defaults)
  let style_default  = get(g:, 'textdecor_box_style_default', '-')
  let width_default  = get(g:, 'textdecor_box_minwidth_default', 40)
  let align_default  = get(g:, 'textdecor_box_align_default', 'center')
  let outer_default  = get(g:, 'textdecor_box_outer_default', 'center')
  let screen_default = get(g:, 'textdecor_box_screen_default', (&textwidth > 0 ? &textwidth : 80))

  " Prompts (empty = keep default)
  let style  = input('Style [-/=/+] ['.style_default.']: ')
  let width  = input('Box width ['.width_default.']: ')
  let align  = input('Text align [left/right/center/cblock] ['.align_default.']: ')
  let outer  = input('Box align [left/center/right/none] ['.outer_default.']: ')
  let screen = input('Screen width (number or @NN) ['.screen_default.']: ')

  " Apply defaults if empty
  let style  = (style ==# ''  ? style_default  : style)
  let width  = (width ==# ''  ? width_default  : width)
  let align  = (align ==# ''  ? align_default  : align)
  let outer  = (outer ==# ''  ? outer_default  : outer)
  let screen = (screen ==# '' ? screen_default : screen)

  " Tiny fixes/validation
  let style = index(['-','=','+'], style) >= 0 ? style : '-'
  let align = tolower(align)
  if index(['left','right','center','centerblock','cblock','c1','c2'], align) < 0
    let align = 'center'
  endif
  let outer = tolower(outer)
  if index(['left','center','right','none','oleft','ocenter','oright'], outer) < 0
    let outer = 'center'
  endif

  " width: accept plain number → use as min/width
  if screen =~# '^@\d\+$'
    " ok as-is
  elseif screen =~# '^\d\+$'
    " allow numeric screen too
  else
    " fallback to default number
    let screen = screen_default
  endif

  if width !~# '^\d\+$'
    let width = width_default
  endif

  " Build qargs string compatible with your parser:
  " tokens can be: style, width/min=NN, align, outer=..., screen=NN or @NN
  let parts = []
  call add(parts, style)
  call add(parts, width . '')           " number
  call add(parts, align)
  if outer !=# 'none'
    call add(parts, 'outer=' . (outer =~# '^o' ? outer[1:] : outer))
  else
    " keep as none by omitting
  endif
  " screen can be numeric or @NN
  if type(screen) == v:t_string && screen =~# '^@'
    call add(parts, screen)
  else
    call add(parts, 'screen=' . screen)
  endif

  return join(parts, ' ')
endfunction



