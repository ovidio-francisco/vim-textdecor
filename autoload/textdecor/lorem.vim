if exists('g:autoloaded_textdecor_lorem') | finish | endif
let g:autoloaded_textdecor_lorem = 1

function! textdecor#lorem#Run(...) abort
  " Defaults: :Lorem -> 1 paragraph, 5 sentences
  let p = 1
  let s = 5
  if a:0 == 1
    let s = max([1, str2nr(a:1)])
  elseif a:0 >= 2
    let p = max([1, str2nr(a:1)])
    let s = max([1, str2nr(a:2)])
  endif

  " Single attempt; if it fails, show one message.
  let code = 'my($p,$s)=@ARGV; my $l=Text::Lorem->new; my @paras; for(1..$p){ my $x=$l->sentences($s); $x =~ s/\s*\R+\s*/ /g; push @paras,$x } print join("\n\n",@paras),qq(\n);'
  let cmd  = 'perl -MText::Lorem -e ' . shellescape(code) . ' ' . p . ' ' . s

  let out = system(cmd)
  if v:shell_error
    echohl WarningMsg
    echom 'vim-textdecor: :Lorem needs Perl module Text::Lorem (try: cpan install Text::Lorem)'
    echohl None
    return
  endif

  " Insert below current line (like :read !cmd)
  call append(line('.'), split(out, "\n", 1))
endfunction
