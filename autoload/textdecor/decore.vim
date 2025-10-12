" Builds a decorated line on the current line.
" Args via <q-args>:
"   total (number), filler (string), enclosers (string like '[]', '{}', '()' or any 1–2 chars)
function! textdecor#decore#Run(qargs) abort
  " Defaults
  let l:total   = 40
  let l:filler  = '-'
  let l:enc     = ''

  " Parse qargs (Option 1)
  if !empty(a:qargs)
    let l:tokens = split(a:qargs)
    " first number -> total
    " first non-number -> filler
    " second non-number -> enclosers
    let l:got_filler = 0
    for tok in l:tokens
      if tok =~# '^\d\+$'
        let l:total = str2nr(tok)
      elseif !l:got_filler
        let l:filler = tok
        let l:got_filler = 1
      else
        let l:enc = tok
      endif
    endfor
  endif

  " Current line
  let l:text = getline('.')

  " Empty line → just a filler bar
  if empty(l:text)
    call setline('.', repeat(l:filler, l:total))
    return
  endif

  " Build optional enclosers (keep your original behavior)
  let l:l_enclose = ''
  let l:r_enclose = ''
  if type(l:enc) == v:t_string && l:enc !=# ''
    let l:nchars = strchars(l:enc)
    if l:nchars >= 2
      let l:l_enclose = strcharpart(l:enc, 0, 1)
      let l:r_enclose = strcharpart(l:enc, l:nchars - 1, 1)
    else
      let l:l_enclose = l:enc
      let l:r_enclose = l:enc
    endif
  endif

  " Build decorated core
  let l:has_enclose = (l:l_enclose !=# '' || l:r_enclose !=# '')
  if l:has_enclose
    let l:decorated = ' ' . l:l_enclose . ' ' . l:text . ' ' . l:r_enclose . ' '
  else
    let l:decorated = ' ' . l:text . ' '
  endif

  let l:remaining = l:total - len(l:decorated)
  if l:remaining < 2
    echo "Line too long for " . l:total . " chars"
    return
  endif

  " Distribute filler evenly (preserve your original len()-based logic)
  let l:left  = repeat(l:filler, float2nr(l:remaining / 2))
  let l:right = repeat(l:filler, l:remaining - len(l:left))

  call setline('.', l:left . l:decorated . l:right)
endfunction

" Interactive variant:
" - filler: string (default '-')
" - countlen: number or 1/2/3 → 20/40/80 (keeps your mapping)
" Prompts one key for encloser; pairs [] {} () <> or duplicates any other char.
function! textdecor#decore#Smart(qargs) abort
  " Defaults
  let l:filler   = '-'
  let l:countlen = 2

  if !empty(a:qargs)
    for tok in split(a:qargs)
      if tok =~# '^\d\+$'
        let l:countlen = str2nr(tok)
      else
        let l:filler = tok
      endif
    endfor
  endif

  " Map countlen to length (keep your original rule)
  let l:L = l:countlen >= 10 ? l:countlen
        \ : l:countlen == 1 ? 20
        \ : l:countlen == 2 ? 40
        \ : l:countlen == 3 ? 80
        \ : 40

  " Read one key for encloser
  let l:c = getchar()
  if l:c == 13 || l:c == 10 || l:c == 27
    let l:E = ''
  else
    let l:ch = nr2char(l:c)
    let l:pairs = { '[':'[]', '{':'{}', '(':'()', '<':'<>' }
    let l:E = has_key(l:pairs, l:ch) ? l:pairs[l:ch] : (l:ch . l:ch)
  endif

  " Reuse Run() with assembled args
  call textdecor#decore#Run(l:L . ' ' . l:filler . ' ' . l:E)
endfunction
