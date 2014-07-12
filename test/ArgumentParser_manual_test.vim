"******************************************************************************
"
" Author:   Alisue <lambdalisue@hashnote.net>
" URL:      http://hashnote.net/
" License:  MIT license
" (C) 2014, Alisue, hashnote.net
"******************************************************************************
let s:save_cpo = &cpo
set cpo&vim

" make a argument parser instance
call vital#of('vital').unload()
let s:V = vital#of('vital')
let s:P = s:V.import('ArgumentParser')
let s:parser = s:P.new()

call s:parser.add_argument('--foo', 'description of the argument')
call s:parser.add_argument('--bar', 'description of the argument', {
      \ 'kind': s:parser.kinds.switch,
      \})
call s:parser.add_argument('--hoge', '-h',
      \ 'description of the argument', {
      \ 'choices': ['a', 'b', 'c'],
      \})
call s:parser.add_argument('--piyo', '-p',
      \ 'description of the argument', {
      \ 'required': 1,
      \})
call s:parser.add_argument('--ahya', '-a',
      \ 'description of the argument', {
      \ 'default': 'AHYA',
      \})

" conflict_with, subordination_of
call s:parser.add_argument('--add',
      \ 'a command to add something', {
      \ 'conflict_with': 'command',
      \})
call s:parser.add_argument('--change',
      \ 'a command to change something', {
      \ 'conflict_with': 'command',
      \})
call s:parser.add_argument('--delete',
      \ 'a command to delete something', {
      \ 'conflict_with': 'command',
      \})

call s:parser.add_argument('--private',
      \ 'a visibility flag of command', {
      \ 'conflict_with': 'visibility',
      \ 'subordination_of': ['add', 'change', 'delete'],
      \})
call s:parser.add_argument('--public',
      \ 'a visibility flag of command', {
      \ 'conflict_with': 'visibility',
      \ 'subordination_of': ['add', 'change', 'delete'],
      \})

" sample function
function! Command(...)
  echo call(s:parser.parse, a:000, s:parser)
endfunction

function! Complete(...)
  return call(s:parser.complete, a:000, s:parser)
endfunction

" sample command
command! -nargs=? -range=% -bang
      \ -complete=customlist,Complete Hoge
      \ :call Command(<q-bang>, [<line1>, <line2>], <f-args>)


let &cpo = s:save_cpo
unlet s:save_cpo
"vim: sts=2 sw=2 smarttab et ai textwidth=0 fdm=marker
