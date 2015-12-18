let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#of('vital')
let s:A = s:V.import('ArgumentParser')

function! s:get_parser() abort
  if exists('s:parser')
    return s:parser
  endif
  let s:parser = s:A.new({
        \ 'name': 'ArgumentParserDemo',
        \ 'description': 'A description of the command',
        \})
  call s:parser.add_argument(
        \ '--foo', '-f', 'A description of foo',
        \)
  call s:parser.add_argument(
        \ '--bar', '-b', 'A description of bar', {
        \   'choices': ['b', 'ba', 'bar'],
        \})
  return s:parser
endfunction

function! s:parse(...) abort
  let parser = s:get_parser()
  return call(parser.parse, a:000, parser)
endfunction
function! s:complete(...) abort
  let parser = s:get_parser()
  return call(parser.complete, a:000, parser)
endfunction
function! s:command(...) abort
  let options = call('s:parse', a:000)
  if empty(options)
    return
  endif
  echomsg string(options)
endfunction

command! -nargs=? -range -bang
        \ -complete=customlist,s:complete
        \ ArgumentParserDemo
        \ :call s:command(<q-bang>, [<line1>, <line2>], <f-args>)

let &cpo = s:save_cpo
" vim:set et ts=2 sts=2 sw=2 tw=0 fdm=marker:
