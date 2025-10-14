if exists('g:autoloaded_textdecor_lorem') | finish | endif
let g:autoloaded_textdecor_lorem = 1

function! textdecor#lorem#Run(...) abort
  let p = 1 | let s = 5
  if a:0 == 1 | let s = max([1, str2nr(a:1)])
  elseif a:0 >= 2 | let p = max([1, str2nr(a:1)]) | let s = max([1, str2nr(a:2)]) | endif

  let code = 'my($p,$s)=@ARGV; my $l=Text::Lorem->new; my @paras; for(1..$p){ my $x=$l->sentences($s); $x =~ s/\s*\R+\s*/ /g; push @paras,$x } if(@paras>1){ print join("\n\n",@paras),"\n" } else { print $paras[0],"\n" };'
  let cmd  = 'perl -MText::Lorem -e ' . shellescape(code) . ' ' . p . ' ' . s

  try
    execute 'read !' . cmd
  catch
    echohl WarningMsg | echom 'vim-textdecor: :Lorem needs Text::Lorem (cpan install Text::Lorem)' | echohl None
  endtry
endfunction
