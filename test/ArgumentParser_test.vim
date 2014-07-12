"******************************************************************************
"
" Author:   Alisue <lambdalisue@hashnote.net>
" URL:      http://hashnote.net/
" License:  MIT license
" (C) 2014, Alisue, hashnote.net
"******************************************************************************
let s:save_cpo = &cpo
set cpo&vim

let s:root = fnamemodify(expand('<sfile>'), ':p:h')
let s:suite = themis#suite('vital-ArgumentParser')
let s:assert = themis#helper('assert')

call vital#of('vital').unload()
let s:V = vital#of('vital')
let s:A = s:V.import("ArgumentParser")

"function! s:suite.test_shellwords() " {{{
"  call s:assert.equals(s:A.shellwords("A B C"), ["A", "B", "C"])
"  call s:assert.equals(s:A.shellwords("A 'B C' D"), ["A", "B C", "D"])
"  call s:assert.equals(s:A.shellwords("A \"B C\" D"), ["A", "B C", "D"])
"  call s:assert.equals(s:A.shellwords("A 'B \"C\" D'"), ["A", "B \"C\" D"])
"endfunction " }}}
function! s:suite.test_new() " {{{
  let p = s:A.new()
  call s:assert.true(has_key(p, 'add_argument'))
endfunction " }}}
function! s:suite.test_add_argument() " {{{
  let p = s:A.new()
  call p.add_argument('--foo', 'description')
  call s:assert.equals(p._long_arguments['foo'].name, 'foo')
  call s:assert.equals(p._long_arguments['foo'].short, '')
  call s:assert.equals(p._long_arguments['foo'].description, 'description')

  call p.add_argument('--foo', '-f', 'description')
  call s:assert.equals(p._long_arguments['foo'].name, 'foo')
  call s:assert.equals(p._long_arguments['foo'].short, 'f')
  call s:assert.equals(p._long_arguments['foo'].description, 'description')
  call s:assert.equals(p._short_arguments['f'].name, 'foo')
  call s:assert.equals(p._short_arguments['f'].short, 'f')
  call s:assert.equals(p._short_arguments['f'].description, 'description')

  call p.add_argument('--foo', 'description', {
        \ 'conflict_with': ['bar', 'hoge'],
        \})
  call s:assert.equals(p._long_arguments['foo'].conflict_with, ['bar', 'hoge'])
  call s:assert.equals(p._conflict_groups['bar'], ['foo'])
  call s:assert.equals(p._conflict_groups['hoge'], ['foo'])

  call p.add_argument('--foo', 'description', {
        \ 'subordination_of': ['bar', 'hoge'],
        \})
  call s:assert.equals(p._long_arguments['foo'].subordination_of,
        \ ['bar', 'hoge'])
  call s:assert.equals(p._subordinations['foo'], ['bar', 'hoge'])

  call p.add_argument('--foo', 'description', {
        \ 'depend_on': ['bar', 'hoge'],
        \})
  call s:assert.equals(p._long_arguments['foo'].depend_on, ['bar', 'hoge'])
  call s:assert.equals(p._depends['foo'], ['bar', 'hoge'])

  call p.add_argument('--foo', 'description', {
        \ 'required': 1,
        \})
  call s:assert.equals(p._long_arguments['foo'].required, 1)
  call s:assert.equals(p._required, ['foo'])

  call p.add_argument('--foo', 'description', {
        \ 'kind': p.kinds.any,
        \})
  call s:assert.equals(p._long_arguments['foo'].kind, p.kinds.any)
  call p.add_argument('--foo', 'description', {
        \ 'kind': p.kinds.switch,
        \})
  call s:assert.equals(p._long_arguments['foo'].kind, p.kinds.switch)
  call p.add_argument('--foo', 'description', {
        \ 'kind': p.kinds.value,
        \})
  call s:assert.equals(p._long_arguments['foo'].kind, p.kinds.value)
  call p.add_argument('--foo', 'description', {
        \ 'choices': ['A', 'B', 'C'],
        \})
  call s:assert.equals(p._long_arguments['foo'].kind, p.kinds.choice)
  call s:assert.equals(p._long_arguments['foo'].choices, ['A', 'B', 'C'])

  call p.add_argument('--foo', 'description')
  call s:assert.true(type(p._long_arguments['foo'].complete) == 2)
  call p.add_argument('--foo', 'description', {
        \ 'complete': ['a', 'b', 'c']
        \})
  call s:assert.true(type(p._long_arguments['foo'].complete) == 3)
  call p.add_argument('--foo', 'description', {
        \ 'choices': ['a', 'b', 'c']
        \})
  call s:assert.true(type(p._long_arguments['foo'].complete) == 3)

  call p.add_argument('--foo', 'description', {
        \ 'default': 'bar',
        \})
  call s:assert.equals(p._long_arguments['foo'].default, 'bar')
endfunction " }}}
function! s:suite.test__parse_cmdline() " {{{
  let p = s:A.new()
  call p.add_argument('--foo', 'description')
  call p.add_argument('--bar', '-b', 'description')
  call p.add_argument('--hoge', 'description')
  let args = p._parse_cmdline('--foo -b hoge piyo')
  call s:assert.equals(args, {
        \ '__unknown__': ['piyo'],
        \ '__args__': ['foo', 'bar'],
        \ 'foo': p.true, 'bar': 'hoge',
        \})
endfunction " }}}
function! s:suite.test__parse_args() " {{{
  let p = s:A.new()
  call p.add_argument('--foo', 'description')
  call p.add_argument('--bar', '-b', 'description')
  call p.add_argument('--hoge', 'description')
  let args = p._parse_args('!', [0, 1], '--foo -b hoge piyo')
  call s:assert.equals(args, {
        \ '__bang__': 1,
        \ '__range__': [0, 1],
        \ '__unknown__': ['piyo'],
        \ '__args__': ['foo', 'bar'],
        \ 'foo': p.true, 'bar': 'hoge',
        \})
endfunction " }}}
function! s:suite.test__validate_conflict_groups() " {{{
  let p = s:A.new()
  call p.add_argument('--foo', 'description', {
        \ 'conflict_with': 'command',
        \})
  call p.add_argument('--bar', 'description', {
        \ 'conflict_with': 'command',
        \})
  call p.add_argument('--hoge', 'description', {
        \ 'conflict_with': ['command', 'command2'],
        \})
  call p.add_argument('--piyo', 'description', {
        \ 'conflict_with': ['command2'],
        \})
  let opts = {'verbose': 0}
  let args = p._parse_cmdline('--foo --bar')
  call s:assert.true(p._validate_conflict_groups(args, opts))
  let args = p._parse_cmdline('--foo --bar --hoge')
  call s:assert.true(p._validate_conflict_groups(args, opts))
  let args = p._parse_cmdline('--hoge --piyo')
  call s:assert.true(p._validate_conflict_groups(args, opts))
  let args = p._parse_cmdline('--foo --piyo')
  call s:assert.false(p._validate_conflict_groups(args, opts))
endfunction " }}}
function! s:suite.test__validate_subordinations() " {{{
  let p = s:A.new()
  call p.add_argument('--foo', 'description')
  call p.add_argument('--bar', 'description')
  call p.add_argument('--hoge', 'description', {
        \ 'subordination_of': 'foo',
        \})
  call p.add_argument('--piyo', 'description', {
        \ 'subordination_of': ['foo', 'bar'],
        \})
  let opts = {'verbose': 0}
  let args = p._parse_cmdline('--foo --hoge')
  call s:assert.false(p._validate_subordinations(args, opts))
  let args = p._parse_cmdline('--bar --hoge')
  call s:assert.true(p._validate_subordinations(args, opts))
  let args = p._parse_cmdline('--piyo')
  call s:assert.true(p._validate_subordinations(args, opts))
  let args = p._parse_cmdline('--bar --piyo')
  call s:assert.false(p._validate_subordinations(args, opts))
endfunction " }}}
function! s:suite.test__validate_depends() " {{{
  let p = s:A.new()
  call p.add_argument('--foo', 'description')
  call p.add_argument('--bar', 'description')
  call p.add_argument('--hoge', 'description', {
        \ 'depend_on': 'foo',
        \})
  call p.add_argument('--piyo', 'description', {
        \ 'depend_on': ['foo', 'bar'],
        \})
  let opts = {'verbose': 0}
  let args = p._parse_cmdline('--foo --hoge')
  call s:assert.false(p._validate_depends(args, opts))
  let args = p._parse_cmdline('--bar --hoge')
  call s:assert.true(p._validate_depends(args, opts))
  let args = p._parse_cmdline('--piyo')
  call s:assert.true(p._validate_depends(args, opts))
  let args = p._parse_cmdline('--bar --piyo')
  call s:assert.true(p._validate_depends(args, opts))
  let args = p._parse_cmdline('--foo --bar --piyo')
  call s:assert.false(p._validate_depends(args, opts))
endfunction " }}}
function! s:suite.test__validate_required() " {{{
  let p = s:A.new()
  call p.add_argument('--foo', 'description')
  call p.add_argument('--bar', 'description')
  call p.add_argument('--hoge', 'description', {
        \ 'required': 1,
        \})
  call p.add_argument('--piyo', 'description', {
        \ 'required': 1,
        \})
  let opts = {'verbose': 0}
  let args = p._parse_cmdline('--foo --hoge')
  call s:assert.true(p._validate_required(args, opts))
  let args = p._parse_cmdline('--bar --hoge')
  call s:assert.true(p._validate_required(args, opts))
  let args = p._parse_cmdline('--piyo')
  call s:assert.true(p._validate_required(args, opts))
  let args = p._parse_cmdline('--hoge --piyo')
  call s:assert.false(p._validate_required(args, opts))
endfunction " }}}
function! s:suite.test__validate_kinds() " {{{
  let p = s:A.new()
  call p.add_argument('--foo', 'description', {
        \ 'kind': p.kinds.any
        \})
  call p.add_argument('--bar', 'description', {
        \ 'kind': p.kinds.switch,
        \})
  call p.add_argument('--hoge', 'description', {
        \ 'kind': p.kinds.value,
        \})
  call p.add_argument('--piyo', 'description', {
        \ 'choices': ['A', 'B', 'C'],
        \})
  call s:assert.false(p._validate_kinds(
        \ p._parse_cmdline('--foo'),
        \ {'verbose': 0}))
  call s:assert.false(p._validate_kinds(
        \ p._parse_cmdline('--bar'),
        \ {'verbose': 0}))
  call s:assert.true(p._validate_kinds(
        \ p._parse_cmdline('--bar INVALID'),
        \ {'verbose': 0}))
  call s:assert.true(p._validate_kinds(
        \ p._parse_cmdline('--hoge'),
        \ {'verbose': 0}))
  call s:assert.false(p._validate_kinds(
        \ p._parse_cmdline('--hoge VALID'),
        \ {'verbose': 0}))
  call s:assert.true(p._validate_kinds(
        \ p._parse_cmdline('--piyo'),
        \ {'verbose': 0}))
  call s:assert.true(p._validate_kinds(
        \ p._parse_cmdline('--piyo INVALID'),
        \ {'verbose': 0}))
  call s:assert.false(p._validate_kinds(
        \ p._parse_cmdline('--piyo A'),
        \ {'verbose': 0}))
endfunction " }}}
function! s:suite.test__validate_unknown() " {{{
  let p = s:A.new()
  call p.add_argument('--foo', 'description')
  call p.add_argument('--bar', 'description')
  call p.add_argument('--hoge', 'description')
  call p.add_argument('--piyo', 'description')
  call s:assert.false(p._validate_unknown(
        \ p._parse_cmdline('--foo --bar --hoge --piyo VALID'),
        \ {'verbose': 0}))
  call s:assert.true(p._validate_unknown(
        \ p._parse_cmdline('--foo --bar --hoge --piyo --unknown'),
        \ {'verbose': 0}))
endfunction " }}}
function! s:suite.test__translate() " {{{
  let p = s:A.new()
  call p.add_argument('--foo', 'description', {
        \ 'kind': p.kinds.any
        \})
  call p.add_argument('--bar', 'description', {
        \ 'kind': p.kinds.switch,
        \})
  call p.add_argument('--hoge', 'description', {
        \ 'kind': p.kinds.value,
        \})
  call p.add_argument('--piyo', 'description', {
        \ 'choices': ['A', 'B', 'C'],
        \})
  let args = p._parse_cmdline('--foo --bar --hoge VALID --piyo A')
  call s:assert.equals(p._transform(args), {
        \ '__unknown__': [],
        \ '__args__': ['foo', 'bar', 'hoge', 'piyo'],
        \ 'foo': 1, 'bar': 1, 'hoge': 'VALID', 'piyo': 'A',
        \})
endfunction " }}}
function! s:suite.test_parse() " {{{
  let p = s:A.new()
  let p.results = {
        \ 'pre_validation': 0,
        \ 'post_validation': 0,
        \ 'pre_transformation': 0,
        \ 'post_transformation': 0,
        \}
  function! p.hooks.pre_validation(args)
    let self.results.pre_validation = 1
    return a:args
  endfunction
  function! p.hooks.post_validation(args)
    let self.results.post_validation = 1
    return a:args
  endfunction
  function! p.hooks.pre_transformation(args)
    let self.results.pre_transformation = 1
    return a:args
  endfunction
  function! p.hooks.post_transformation(args)
    let self.results.post_transformation = 1
    return a:args
  endfunction

  call p.parse('', [0, 0], '', {'verbose': 0})

  call s:assert.true(p.results.pre_validation)
  call s:assert.true(p.results.post_validation)
  call s:assert.true(p.results.pre_transformation)
  call s:assert.true(p.results.post_transformation)

  call p.add_argument('--foo', 'description')
  call p.add_argument('--bar', 'description', {
        \ 'kind': p.kinds.any,
        \ 'default': 'hoge',
        \})
  call s:assert.equals(p.parse('', [0, 0], ''), {
        \ '__bang__': 0,
        \ '__range__': [0, 0],
        \ '__unknown__': [],
        \ '__args__': [],
        \ 'bar': 'hoge',
        \})
  call s:assert.equals(p.parse('', [0, 0], '--bar piyo'), {
        \ '__bang__': 0,
        \ '__range__': [0, 0],
        \ '__unknown__': [],
        \ '__args__': ['bar'],
        \ 'bar': 'piyo',
        \})

endfunction " }}}
function! s:suite.test_has_conflict_with() " {{{
  let p = s:A.new()
  call p.add_argument('--foo', 'description', {
        \ 'conflict_with': 'command',
        \})
  call p.add_argument('--bar', 'description', {
        \ 'conflict_with': 'command',
        \})
  call p.add_argument('--hoge', 'description', {
        \ 'conflict_with': ['command', 'command2'],
        \})
  call p.add_argument('--piyo', 'description', {
        \ 'conflict_with': 'command2',
        \})

  call s:assert.true(p.has_conflict_with(
        \ 'foo',
        \ p._parse_cmdline('--foo')
        \))
  call s:assert.true(p.has_conflict_with(
        \ 'foo',
        \ p._parse_cmdline('--foo --bar')
        \))
  call s:assert.true(p.has_conflict_with(
        \ 'foo',
        \ p._parse_cmdline('--hoge --bar')
        \))
endfunction " }}}
function! s:suite.test_has_subordination_of() " {{{
  let p = s:A.new()
  call p.add_argument('--foo', 'description', {
        \})
  call p.add_argument('--bar', 'description', {
        \})
  call p.add_argument('--hoge', 'description', {
        \ 'subordination_of': 'foo',
        \})
  call p.add_argument('--piyo', 'description', {
        \ 'subordination_of': ['foo', 'bar']
        \})

  call s:assert.false(p.has_subordination_of(
        \ 'foo',
        \ p._parse_cmdline('--foo')
        \))
  call s:assert.false(p.has_subordination_of(
        \ 'hoge',
        \ p._parse_cmdline('--hoge')
        \))
  call s:assert.true(p.has_subordination_of(
        \ 'hoge',
        \ p._parse_cmdline('--foo')
        \))
  call s:assert.true(p.has_subordination_of(
        \ 'hoge',
        \ p._parse_cmdline('--foo --hoge')
        \))
endfunction " }}}
function! s:suite.test_has_depend_on() " {{{
  let p = s:A.new()
  call p.add_argument('--foo', 'description', {
        \})
  call p.add_argument('--bar', 'description', {
        \})
  call p.add_argument('--hoge', 'description', {
        \ 'depend_on': 'foo',
        \})
  call p.add_argument('--piyo', 'description', {
        \ 'depend_on': ['foo', 'bar']
        \})

  call s:assert.false(p.has_depend_on(
        \ 'hoge',
        \ p._parse_cmdline('--hoge')
        \))
  call s:assert.true(p.has_depend_on(
        \ 'hoge',
        \ p._parse_cmdline('--foo')
        \))
  call s:assert.true(p.has_depend_on(
        \ 'hoge',
        \ p._parse_cmdline('--foo --hoge')
        \))
  call s:assert.false(p.has_depend_on(
        \ 'piyo',
        \ p._parse_cmdline('--foo --piyo')
        \))
  call s:assert.true(p.has_depend_on(
        \ 'piyo',
        \ p._parse_cmdline('--foo --bar --piyo')
        \))
endfunction " }}}
function! s:suite.test__complete_long_argument() " {{{
  let p = s:A.new({'auto_help': 0})
  call p.add_argument('--foo', 'description', {
        \ 'conflict_with': 'command',
        \})
  call p.add_argument('--bar', 'description', {
        \ 'conflict_with': 'command',
        \})
  call p.add_argument('--hoge', 'description', {
        \ 'subordination_of': 'foo',
        \})
  call p.add_argument('--piyo', 'description', {
        \ 'depend_on': ['foo', 'bar']
        \})

  " Note: depend_on should not influence completion
  call s:assert.equals(
        \ p._complete_long_argument('', p._parse_cmdline('')),
        \ ['--foo', '--bar', '--piyo']
        \)
  call s:assert.equals(
        \ p._complete_long_argument('', p._parse_cmdline('--foo')),
        \ ['--hoge', '--piyo']
        \)
  call s:assert.equals(
        \ p._complete_long_argument('', p._parse_cmdline('--foo --bar')),
        \ ['--hoge', '--piyo']
        \)
  call s:assert.equals(
        \ p._complete_long_argument('--f', p._parse_cmdline('')),
        \ ['--foo']
        \)
endfunction " }}}
function! s:suite.test__complete_short_argument() " {{{
  let p = s:A.new({'auto_help': 0})
  call p.add_argument('--foo', '-f', 'description', {
        \ 'conflict_with': 'command',
        \})
  call p.add_argument('--bar', '-b', 'description', {
        \ 'conflict_with': 'command',
        \})
  call p.add_argument('--hoge', '-h', 'description', {
        \ 'subordination_of': 'foo',
        \})
  call p.add_argument('--piyo', '-p', 'description', {
        \ 'depend_on': ['foo', 'bar']
        \})

  call s:assert.equals(
        \ p._complete_short_argument('', p._parse_cmdline('')),
        \ ['-p', '-b', '-f']
        \)
  call s:assert.equals(
        \ p._complete_short_argument('', p._parse_cmdline('-f')),
        \ ['-p', '-h']
        \)
  call s:assert.equals(
        \ p._complete_short_argument('', p._parse_cmdline('-f -b')),
        \ ['-p', '-h']
        \)
  call s:assert.equals(
        \ p._complete_short_argument('-f', p._parse_cmdline('')),
        \ ['-f']
        \)
endfunction " }}}
function! s:suite.test__complete_argument_value() " {{{
  let p = s:A.new({'auto_help': 0})
  function p.user_defined_complete(arglead, cmdline, cursorpos, args)
    return ['I', 'am', 'a', 'Vimmer']
  endfunction
  call p.add_argument('--foo', 'description', {
        \ 'complete': [],
        \})
  call p.add_argument('--bar', 'description', {
        \ 'choices': ['foo', 'bar', 'hoge', 'piyo'],
        \})
  call p.add_argument('--hoge', 'description', {
        \ 'complete': p.user_defined_complete,
        \})

  call s:assert.equals(p._complete_argument_value('', '', 0,
        \ p._parse_cmdline('--foo')),
        \ []
        \)
  call s:assert.equals(p._complete_argument_value('', '', 0,
        \ p._parse_cmdline('--bar')),
        \ ['foo', 'bar', 'hoge', 'piyo']
        \)
  call s:assert.equals(p._complete_argument_value('f', '', 0,
        \ p._parse_cmdline('--bar')),
        \ ['foo']
        \)
  call s:assert.equals(p._complete_argument_value('', '', 0,
        \ p._parse_cmdline('--hoge')),
        \ ['I', 'am', 'a', 'Vimmer']
        \)
  " user defined function should not be filtered if the function does not
  " filter
  call s:assert.equals(p._complete_argument_value('Vim', '', 0,
        \ p._parse_cmdline('--hoge')),
        \ ['I', 'am', 'a', 'Vimmer']
        \)
endfunction " }}}
function! s:suite.test_complete() " {{{
  let p = s:A.new({'auto_help': 0})
  function p.user_defined_complete(arglead, cmdline, cursorpos, args)
    return ['I', 'am', 'a', 'Vimmer']
  endfunction
  call p.add_argument('--foo', '-f', 'description', {
        \ 'kind': p.kinds.switch,
        \})
  call p.add_argument('--bar', '-b', 'description', {
        \ 'choices': ['foo', 'bar', 'hoge', 'piyo'],
        \})
  call p.add_argument('--hoge', 'description', {
        \ 'kind': p.kinds.any,
        \ 'complete': p.user_defined_complete,
        \})

  call s:assert.equals(p.complete('', '', 0),
        \ ['--foo', '--hoge', '--bar', '-b', '-f'],
        \)
  call s:assert.equals(p.complete('', '--foo', 0),
        \ ['--hoge', '--bar', '-b'],
        \)
  call s:assert.equals(p.complete('', '--bar', 0),
        \ ['foo', 'bar', 'hoge', 'piyo'],
        \)
  call s:assert.equals(p.complete('', '--bar VALID', 0),
        \ ['--foo', '--hoge', '-f'],
        \)
  call s:assert.equals(p.complete('', '--hoge', 0),
        \ ['I', 'am', 'a', 'Vimmer'],
        \)
  call s:assert.equals(p.complete('', '--hoge Vimmer', 0),
        \ ['--foo', '--bar', '-b', '-f'],
        \)
endfunction " }}}

function! s:suite.test__format_definition() " {{{
  let p = s:A.new()
  let foo = p.add_argument('--foo', '-f', 'description', {
        \ 'kind': p.kinds.any,
        \})
  let bar = p.add_argument('--bar', '-b', 'description', {
        \ 'kind': p.kinds.switch,
        \})
  let hoge = p.add_argument('--hoge', 'description', {
        \ 'kind': p.kinds.value,
        \})
  let piyo = p.add_argument('--piyo', 'description', {
        \ 'choices': ['a', 'b', 'c'],
        \})
  call s:assert.equals(
        \ p._format_definition(foo),
        \ "-f, --foo [FOO]")
  call s:assert.equals(
        \ p._format_definition(bar),
        \ "-b, --bar")
  call s:assert.equals(
        \ p._format_definition(hoge),
        \ "    --hoge HOGE")
  call s:assert.equals(
        \ p._format_definition(piyo),
        \ "    --piyo {choice}")
endfunction " }}}
function! s:suite.test__format_description() " {{{
  let p = s:A.new()
  let foo = p.add_argument('--foo', '-f', 'description', {
        \ 'kind': p.kinds.any,
        \ 'conflict_with': ['command', 'command2'],
        \})
  let bar = p.add_argument('--bar', '-b', 'description', {
        \ 'kind': p.kinds.switch,
        \ 'subordination_of': ['command', 'command2'],
        \})
  let hoge = p.add_argument('--hoge', 'description', {
        \ 'kind': p.kinds.value,
        \ 'depend_on': ['command', 'command2'],
        \})
  let piyo = p.add_argument('--piyo', 'description', {
        \ 'choices': ['a', 'b', 'c'],
        \ 'required': 1,
        \})
  call s:assert.equals(
        \ p._format_description(foo),
        \ "description\n(kind: ANY)\n(conflict_with: command, command2)\n"
        \)
  call s:assert.equals(
        \ p._format_description(bar),
        \ "description\n(kind: SWITCH)\n(subordination_of: command, command2)\n"
        \)
  call s:assert.equals(
        \ p._format_description(hoge),
        \ "description\n(kind: VALUE)\n(depend_on: command, command2)\n"
        \)
  call s:assert.equals(
        \ p._format_description(piyo),
        \ "description\n(kind: CHOICE)\n(required)\n({choice}: a, b, c)\n"
        \)
endfunction " }}}
function! s:suite.test_help() " {{{
  let p = s:A.new({'auto_help': 0})
  call p.add_argument('--foo', '-f', 'description', {
        \ 'kind': p.kinds.any,
        \ 'conflict_with': ['command', 'command2'],
        \})
  call p.add_argument('--bar', '-b', 'description', {
        \ 'kind': p.kinds.switch,
        \ 'subordination_of': ['command', 'command2'],
        \})
  call p.add_argument('--hoge', 'description', {
        \ 'kind': p.kinds.value,
        \ 'depend_on': ['command', 'command2'],
        \})
  call p.add_argument('--piyo', 'description', {
        \ 'choices': ['a', 'b', 'c'],
        \ 'required': 1,
        \})
  let expect = [
        \ "-f, --foo [FOO]      description",
        \ "                     (kind: ANY)",
        \ "                     (conflict_with: command, command2)",
        \ "",
        \ "    --hoge HOGE      description",
        \ "                     (kind: VALUE)",
        \ "                     (depend_on: command, command2)",
        \ "",
        \ "-b, --bar            description",
        \ "                     (kind: SWITCH)",
        \ "                     (subordination_of: command, command2)",
        \ "",
        \ "    --piyo {choice}  description",
        \ "                     (kind: CHOICE)",
        \ "                     (required)",
        \ "                     ({choice}: a, b, c)",
        \ "",
        \]
  call s:assert.equals(
        \ p.help(),
        \ join(expect, "\n"),
        \)
endfunction " }}}

function! s:suite.test_get_completers() " {{{
  let completers = s:A.get_completers()
  call s:assert.true(has_key(completers, 'file'))
endfunction " }}}
function! s:suite.test_file_completers() " {{{
  let completers = s:A.get_completers()
  call s:assert.equals(completers.file(s:root . '/Ar', '', 0, {}), [
        \ s:root . '/ArgumentParser_manual_test.vim',
        \ s:root . '/ArgumentParser_test.vim',
        \])
endfunction " }}}
let &cpo = s:save_cpo
unlet s:save_cpo
"vim: sts=2 sw=2 smarttab et ai textwidth=0 fdm=marker
