" Defaults (global, user may override in vimrc)
let g:textdecor_box_innerpad_default = get(g:, 'textdecor_box_innerpad_default', 1)
let g:textdecor_box_pad_ratio        = get(g:, 'textdecor_box_pad_ratio', 1.5)


function! textdecor#box#Box(first, last, qargs) range
  " Defaults
  let l:style_key      = '-'
  let l:min_width      = 20
  let l:align          = 'left'
  let l:outer          = 'none'
  let l:screenw        = (&textwidth > 0 ? &textwidth : 0)
  let l:explicit_width = 0
  let l:do_wrap        = 0
  let l:width          = 0

  let l:inner_pad  = get(g:, 'textdecor_box_innerpad_default', 1)
  let l:pad_ratio  = get(g:, 'textdecor_box_pad_ratio', 1.5)
  " l:inner_vpad will be computed from inner_pad and pad_ratio (bordered only)
  let l:inner_vpad = 0


  " --- Parse <q-args> (also accept n|none|plain and custom symbol) ----------
  if !empty(a:qargs)
	  for tok in split(a:qargs)
		  if tok =~# '^\%(w\|width\|min\)=\d\+$'
			  let l:min_width = str2nr(matchstr(tok, '\d\+'))
			  let l:explicit_width = l:min_width

		  elseif tok =~# '^\d\+$'
			  let l:min_width = str2nr(tok)
			  let l:explicit_width = l:min_width

		  elseif tok =~# '^\%(s\|screen\|page\)=\d\+$'
			  let l:screenw = str2nr(matchstr(tok, '\d\+'))

		  elseif tok =~# '^@\d\+$'
			  let l:screenw = str2nr(tok[1:])

			  " ----- style -----
		  elseif tolower(tok) =~# '^\%(n\|none\|plain\)$'
			  let l:style_key = 'n'
		  elseif tok =~# '^[-=+]$'
			  let l:style_key = tok
		  elseif tok =~# '^\S$' && tok !~# '[[:alnum:]]'
			  " any single printable non-alphanumeric (e.g. *, #, ~)
			  let l:style_key = tok

			  " ----- inner text align -----
		  elseif tok =~? '^\(left\|right\|center\|centerblock\|cblock\|c1\|c2\|justify\|j\)$'
			  let l:align = tolower(tok)

			  " ----- outer align -----
		  elseif tok =~? '^outer=\(left\|center\|right\)$'
			  let l:outer = tolower(matchstr(tok, '=\zs.*'))
		  elseif tok =~? '^o\(left\|center\|right\)$'
			  let l:outer = tolower(matchstr(tok, '^o\zs.*'))

			  " ----- padding -----
		  elseif tok =~# '^\%(p\|pad\|ip\)=\d\+$'
			  let l:inner_pad = str2nr(matchstr(tok, '\d\+'))
		  endif
	  endfor

	  " Derive vertical padding (lines) from horizontal padding and ratio.
	  if l:style_key !=# 'n' && l:inner_pad > 1
		  let l:inner_vpad = float2nr(floor(l:inner_pad / (l:pad_ratio > 0 ? l:pad_ratio : 1.0)))
	  endif

	" Derive vertical padding (lines) from horizontal padding and ratio.
	if l:style_key !=# 'n' && l:inner_pad > 1
		let l:inner_vpad = float2nr(floor(l:inner_pad / (l:pad_ratio > 0 ? l:pad_ratio : 1.0)))
	endif

  endif

  " Read lines and rtrim (keep indent)
  let l:raw   = getline(a:first, a:last)
  let l:lines = map(copy(l:raw), "substitute(v:val, '\\s\\+$', '', '')")

  " Measure original content width
  let l:maxw_orig = empty(l:lines) ? 0 : max(map(copy(l:lines), 'strdisplaywidth(v:val)'))

  " Decide target content width (inner width, excluding side padding)
  if l:explicit_width > 0
    let l:width   = max([l:explicit_width, 1])
    let l:do_wrap = 1
  elseif l:screenw > 0 && (l:maxw_orig + (2*l:inner_pad) + 2) > l:screenw
	  let l:width   = max([l:screenw - ((2*l:inner_pad) + 2), 1])
	  let l:do_wrap = 1
  else
    let l:width   = max([l:maxw_orig, l:min_width])
    let l:do_wrap = 0
  endif

  " Word-wrap helper
  function! s:Wrap(line, width) abort
    if a:width <= 0 | return [a:line] | endif
    let words = split(a:line, '\s\+')
    if empty(words) | return [''] | endif
    let out = [] | let cur = ''
    for w in words
      let wlen = strdisplaywidth(w)
      if cur ==# ''
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

  " Apply wrapping if needed
  if l:do_wrap
    let l:wrapped = []
    for L in l:lines
      call extend(l:wrapped, s:Wrap(L, l:width))
    endfor
    let l:lines = l:wrapped
    let l:maxw  = empty(l:lines) ? 0 : max(map(copy(l:lines), 'strdisplaywidth(v:val)'))
    let l:width = max([l:maxw, l:width])
  else
    let l:maxw  = l:maxw_orig
  endif

  " Inner alignment helper
  let l:block_left = float2nr((l:width - l:maxw) / 2)
  function! s:Align(line, width, align, block_left, is_last) abort
	  let l:w = strdisplaywidth(a:line)
	  let l:pad = a:width - l:w
	  if l:pad < 0 | let l:pad = 0 | endif

	  if a:align ==# 'justify' || a:align ==# 'j'
		  " Don’t justify the last line of a paragraph or blank/single-word lines
		  if a:is_last || a:line =~# '^\s*$' || len(split(a:line, '\s\+')) <= 1
			  return a:line . repeat(' ', l:pad)
		  endif
		  return s:Justify(a:line, a:width)
	  elseif a:align ==# 'center' || a:align ==# 'c1'
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



  function! s:Justify(line, width) abort
	  " Don’t justify empty or single-word lines
	  if a:line =~# '^\s*$' | return a:line | endif
	  let words = split(a:line, '\s\+')
	  if len(words) <= 1
		  " pad right to width
		  let w = strdisplaywidth(a:line)
		  return a:line . repeat(' ', max([a:width - w, 0]))
	  endif

	  " Compute space budget to hit exactly a:width
	  let total_chars = 0
	  for w in words
		  let total_chars += strdisplaywidth(w)
	  endfor
	  let gaps = len(words) - 1
	  let spaces_needed = a:width - total_chars
	  if spaces_needed <= gaps
		  " At least 1 space per gap; any deficit -> still 1 per gap (will be shorter)
		  let base = 1
		  let extra = max([spaces_needed - gaps, 0])
	  else
		  let base = float2nr(floor(spaces_needed / gaps))
		  let extra = spaces_needed - base * gaps
	  endif

	  let out = []
	  for i in range(0, gaps - 1)
		  call add(out, words[i])
		  " distribute extras from the left
		  let addl = base + (i < extra ? 1 : 0)
		  call add(out, repeat(' ', max([addl, 1])))
	  endfor
	  call add(out, words[-1])

	  return join(out, '')
  endfunction





  " Build aligned content lines (no outer margin yet)
  let l:content_lines = []
  let lcount = len(l:lines)
  for i in range(0, lcount - 1)
	  let L = l:lines[i]
	  let is_last = (i == lcount - 1)
	  call add(l:content_lines, s:Align(L, l:width, l:align, l:block_left, is_last))
  endfor




  " ---- If style is borderless ('n'), we output just the aligned lines ----
  if l:style_key ==# 'n'
	  " Borderless: no inner side padding added here.
	  let l:boxed = copy(l:content_lines)
  else
	  " ---- Bordered styles ----
	  let l:styles = {
				  \ '-': {'top': '┌─┐', 'vert': '││', 'bottom': '└─┘'},
				  \ '=': {'top': '╔═╗', 'vert': '║║', 'bottom': '╚═╝'},
				  \ '+': {'top': '+-+', 'vert': '||', 'bottom': '+-+'},
				  \ }

	  if has_key(l:styles, l:style_key)
		  let l:style = l:styles[l:style_key]
	  elseif l:style_key =~# '^\S$' && l:style_key !~# '[[:alnum:]]'
		  " custom one-char style → use it everywhere
		  let ch = l:style_key
		  let l:style = {'top': ch.ch.ch, 'vert': ch.ch, 'bottom': ch.ch.ch}
	  else
		  let l:style = l:styles['-']
	  endif
	  let [l:tl, l:hz, l:tr]  = split(l:style.top, '\zs')
	  let [l:bl, l:hz2, l:br] = split(l:style.bottom, '\zs')
	  let [l:vl, l:vr]        = split(l:style.vert, '\zs')

	  " Top/bottom widths include 2*inner_pad
	  let l:top    = l:tl . repeat(l:hz, l:width + (2*l:inner_pad)) . l:tr
	  let l:bottom = l:bl . repeat(l:hz, l:width + (2*l:inner_pad)) . l:br

	  let l:boxed = [l:top]

	  " ⬆️ TOP vertical padding (blank inner rows)
	  if exists('l:inner_vpad') && l:inner_vpad > 0
		  let l:empty_inner = l:vl . repeat(' ', l:inner_pad) . repeat(' ', l:width) . repeat(' ', l:inner_pad) . l:vr
		  for _ in range(1, l:inner_vpad)
			  call add(l:boxed, l:empty_inner)
		  endfor
	  endif

	  " Content lines
	  for L in l:content_lines
		  call add(l:boxed, l:vl . repeat(' ', l:inner_pad) . L . repeat(' ', l:inner_pad) . l:vr)
	  endfor

	  " ⬇️ BOTTOM vertical padding (must be BEFORE the bottom border)
	  if exists('l:inner_vpad') && l:inner_vpad > 0
		  " reuse l:empty_inner (recompute if you prefer)
		  for _ in range(1, l:inner_vpad)
			  call add(l:boxed, l:empty_inner)
		  endfor
	  endif

	  " Bottom border LAST
	  call add(l:boxed, l:bottom)

  endif

  " Outer alignment against screen width (works for both bordered & borderless)
  if l:outer !=# 'none' && l:screenw > 0 && !empty(l:boxed)
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

  " Safe replace
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




" Invoke: if no qargs, run wizard; else pass through
function! textdecor#box#Invoke(first, last, qargs, has_range) range abort
  let qargs = a:qargs
  if qargs ==# ''
    let spec = textdecor#box#Wizard()
    if empty(spec) | return | endif
    let qargs = spec
  endif

  if a:has_range
    let [l1, l2] = [a:first, a:last]
  else
    let [l1, l2] = textdecor#box#ParagraphRange()
  endif

  return textdecor#box#Box(l1, l2, qargs)
endfunction

" Wizard: ask for parameters, return a single qargs string compatible with parser
function! textdecor#box#Wizard() abort
  " -------------------------
  " Defaults
  " -------------------------
  let style_default  = get(g:, 'textdecor_box_style_default', '-')
  let width_default  = get(g:, 'textdecor_box_minwidth_default', 40)
  let align_default  = get(g:, 'textdecor_box_align_default', 'center')
  let outer_default  = get(g:, 'textdecor_box_outer_default', 'center')
  let screen_default = get(g:, 'textdecor_box_screen_default', 80)
  let pad_default    = get(g:, 'textdecor_box_innerpad_default', 1)

  " -------------------------
  " Step 1: core prompts
  " -------------------------
  let style = input('Style [-/=/+/n (none)] ['.style_default.']: ')
  let width = input('Box min width ['.width_default.']: ')
  let align = input('Text align [l/r/c/b/j] (left/right/center/cblock/justify) ['.align_default.']: ')
  let outer = input('Box align [l/c/r/n] (left/center/right/none) ['.outer_default.']: ')

  " Apply defaults if empty
  let style = (style ==# '' ? style_default : style)
  let align = (align ==# '' ? align_default : align)
  let width = (width ==# '' ? width_default : width)
  let outer = (outer ==# '' ? outer_default : outer)

  " Normalize style: allow presets, none, or any single printable symbol
  let s = type(style)==v:t_string ? trim(style) : style
  let sl = tolower(s)

  if sl =~# '^\%(n\|none\|plain\)$'
	  let style = 'n'
  elseif sl =~# '^[-=+]$'
	  let style = sl
  elseif s =~# '^\S$' && s !~# '[[:alnum:]]'
	  " accept any single non-alphanumeric printable char (e.g. *, #, ~)
	  let style = s
  else
	  let style = tolower(style_default)
	  if style =~# '^\%(n\|none\|plain\)$' | let style = 'n' | endif
  endif

  " Normalize align/outter
  let align_map = {'l':'left','r':'right','c':'center','b':'centerblock','j':'justify'}
  let akey = tolower(align)
  let align = has_key(align_map, akey) ? align_map[akey] : align

  let outer_map = {'l':'left','c':'center','r':'right','n':'none'}
  let okey = tolower(outer)
  let outer = has_key(outer_map, okey) ? outer_map[okey] : outer

  " Coerce numbers
  let width = width =~# '^\d\+$' ? str2nr(width) : str2nr(width_default)
  if width < 4 | let width = 4 | endif

  " -------------------------
  " Step 2: conditional prompts
  " -------------------------

  let screen = ''
  if outer ==# 'center' || outer ==# 'right'
    let wcols = s:textwidth_effective(win_getid())
    " Enter → 80 | number → that number | @NN → (window_text_width - NN) | w → window_text_width
    let scr_in = input("Screen width (number / @NN / 'w' for window=".wcols.") [80]: ")
  
    if scr_in ==# ''
      let screen = screen_default
    elseif scr_in =~? '^\s*w\s*$'
      let screen = wcols
    elseif type(scr_in)==v:t_string && scr_in =~# '^@\d\+$'
      let off = str2nr(scr_in[1:])
      let screen = max([1, wcols - off])
    elseif scr_in =~# '^\d\+$'
      let screen = str2nr(scr_in)
      if screen < 1 | let screen = 80 | endif
    else
      let screen = 80
    endif
  endif

  let pad = 0
  if style !=# 'n'
    let pad_in = input('Inner padding ['.pad_default.']: ')
    let pad = (pad_in ==# '' ? pad_default : pad_in)
    let pad = pad =~# '^\d\+$' ? str2nr(pad) : str2nr(pad_default)
    if pad < 0 | let pad = 0 | endif
  endif


  " -------------------------
  " Build qargs in order
  " -------------------------
  let parts = [style, string(width), align]
  if style !=# 'n'
    call add(parts, 'pad='.string(pad))
  endif
  if outer ==# 'center' || outer ==# 'right'
    call add(parts, 'outer='.outer)
    if type(screen)==v:t_string && screen =~# '^@\d\+$'
      call add(parts, screen)
    else
      call add(parts, 'screen='.string(screen))
    endif
  elseif outer ==# 'none'
    call add(parts, 'outer=none')
  else
    " outer=left → omit outer/screen entirely
  endif

  return join(parts, ' ')
endfunction



" Returns [l1, l2] for the blank-line-delimited paragraph under the cursor.
function! textdecor#box#ParagraphRange() abort
  let l1 = line('.')
  while l1 > 1 && getline(l1 - 1) !~# '^\s*$'
    let l1 -= 1
  endwhile

  let l2 = line('.')
  let last = line('$')
  while l2 < last && getline(l2 + 1) !~# '^\s*$'
    let l2 += 1
  endwhile
  return [l1, l2]
endfunction


" Return the number of columns available for text in the given window
function! s:textwidth_effective(winid) abort
  let info = getwininfo(a:winid)[0]
  return info.width - info.textoff
endfunction


