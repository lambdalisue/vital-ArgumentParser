let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#of('vital')
let s:A = s:V.import('ArgumentParser')

function! s:callback(opts) abort " {{{
  echo a:opts
endfunction " }}}

let s:parser = s:A.new({
      \ 'name': 'ArgumentParser',
      \ 'description': 'An ArgumentParser demo command',
      \ 'description_unknown': '[{file1}, {file2}, ...]',
      \})
" basic
call s:parser.add_argument('--foo', 'A simple argument')
call s:parser.add_argument('--bar', '-b', 'A simple argument with alias')
call s:parser.add_argument('--hoge', "multiline\ndescription")
call s:parser.add_argument('--piyo', ['multiline', 'description', 'with list'])
call s:parser.add_argument('--puyo', 'ANY argument', { 'type': s:A.types.any })
call s:parser.add_argument('--poyo', 'VALUE argument', { 'type': s:A.types.value })
call s:parser.add_argument('--payo', 'CHOICE argument', { 'choices': ['a', 'b', 'c'] })

" required
" ArgumentParser command will fail without --required
call s:parser.add_argument('--required', { 'required': 1 })

" conflict
" ArgumentParser command will fail when more than two of
" --conflict1, --conflict2, --conflict3 are specified
call s:parser.add_argument('--conflict1', { 'conflicts': ['conflict2', 'conflict3'] })
call s:parser.add_argument('--conflict2', { 'conflicts': ['conflict1', 'conflict3'] })
call s:parser.add_argument('--conflict3', { 'conflicts': ['conflict1', 'conflict2'] })

" superordinate and subordinate (require at least one)
" ArgumentParser command will fail when --subordinate is specified but
" non of --superordinate1 nor --superordinate2 is specified
call s:parser.add_argument('--superordinate1')
call s:parser.add_argument('--superordinate2')
call s:parser.add_argument('--subordinate', { 'superordinates': ['superordinate1', 'superordinate2'] })

" dependencies (require all)
" ArgumentParser command will fail when --baby is specified but
" --papa nor --mama is specified
call s:parser.add_argument('--papa')
call s:parser.add_argument('--mama')
call s:parser.add_argument('--baby', { 'dependencies': ['papa', 'mama'] })

" pattern
" ArgumentParser command will fail when --pattern is specified and the value
" does not follow the specified pattern
call s:parser.add_argument('--pattern', { 'pattern': '\v\d{3}-\d{4}' })

" positional argument
call s:parser.add_argument('positional1', { 'choices': [
      \ 'positional1_a',
      \ 'positional1_b',
      \ 'positional1_c',
      \]})
call s:parser.add_argument('positional2')

function! s:ArgumentParserParse(...) abort
  let opts = call(s:parser.parse, a:000, s:parser)
  if !empty(opts)
    echo opts
  endif
endfunction
function! s:ArgumentParserComplete(...) abort
  return call(s:parser.complete, a:000, s:parser)
endfunction
command! -nargs=? -range -bang
      \ -complete=customlist,s:ArgumentParserComplete ArgumentParser
      \ :call s:ArgumentParserParse(<q-bang>, [<line1>, <line2>], <f-args>)

let &cpo = s:save_cpo
" vim:set et ts=2 sts=2 sw=2 tw=0 fdm=marker:
