
function! Decore(...)
  let l:text  = getline('.')
  let l:total = (a:0 >= 1 ? a:1 : 40)
  let l:filler = (a:0 >= 2 ? a:2 : '-') " default '-'

  " Optional enclosers
  let l:l_enclose = ''
  let l:r_enclose = ''
  if a:0 >= 3 && type(a:3) == v:t_string && a:3 !=# ''
    let l:enc    = a:3
    let l:nchars = strchars(l:enc)
    if l:nchars >= 2
      let l:l_enclose = strcharpart(l:enc, 0, 1)
      let l:r_enclose = strcharpart(l:enc, l:nchars - 1, 1)
    else
      let l:l_enclose = l:enc
      let l:r_enclose = l:enc
    endif
  endif

  " Case: empty line → just filler
  if empty(l:text)
    call setline('.', repeat(l:filler, l:total))
    return
  endif

  " Build decorated text
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

  " Distribute filler evenly
  let l:left  = repeat(l:filler, float2nr(l:remaining / 2))
  let l:right = repeat(l:filler, l:remaining - len(l:left))

  call setline('.', l:left . l:decorated . l:right)
endfunction


function! DecoreSmart(filler, countlen) abort
  let L = a:countlen >= 10 ? a:countlen
        \ : a:countlen == 1 ? 20
        \ : a:countlen == 2 ? 40
        \ : a:countlen == 3 ? 80
        \ : 40

  let c = getchar()                " Get exactly one key

  if c == 13 || c == 10 || c == 27 " CR  NL or Esc => no encloser
    let E = ''
  else
    let ch = nr2char(c)
    let pairs = { '[':'[]', '{':'{}', '(':'()', '<':'<>' }
    let E = has_key(pairs, ch) ? pairs[ch] : (ch . ch)
  endif

  call Decore(L, a:filler, E)
endfunction






" if exists('g:loaded_textdecor_decore') | finish | endif
" let g:loaded_textdecor_decore = 1

" " :Decore [total] [filler] [enclosers]
" " :DecoreSmart [filler] [countlen]
" command! -nargs=* Decore      call textdecor#decore#Run(<q-args>)
" command! -nargs=* DecoreSmart call textdecor#decore#Smart(<q-args>)
