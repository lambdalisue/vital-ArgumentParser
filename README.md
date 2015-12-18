vital-ArgumentParser  [![Build Status](https://travis-ci.org/lambdalisue/vital-ArgumentParser.svg)](https://travis-ci.org/lambdalisue/vital-ArgumentParser)
==============================================================================
A high functional argument parser

- Version:   0.2.0
- Author:   Alisue <lambdalisue@hashnote.net>
- Support:  Vim 7.3 and above


INTRODUCTIONS
-------------------------------------------------------------------------------

*Vital.ArgumentParser* is a high functional argument (option) parser.
There is a Vital.OptionParser but this parser is much flexible while:

1. Positional argument is supported
2. Positional assignment is supported (`--foo bar` instead of `--foo=bar`)
3. Quotation is supported (`--foo="bar bar"` or `--foo "bar bar"`)
4. Powerful validations
   - Warn when a required argument is missing
   - Warn when no value is assigned for VALUE or CHOICE argument
   - Warn when a value is assigned for SWITCH argument
   - Warn when a value is not found in 'choices' for CHOICE argument
   - Warn when conflicted arguments are specified together
   - Warn when argument dependencies are not satisfied
   - Warn when superordinate argument is not specified together
   - Warn when a value does not follow a required regex pattern
   - Validation can enable/disable with settings
5. Powerful completion
   - Complete optional arguments
   - Complete a value of optional/positional argument from a pre-specified
     list
   - Complete a value of optional/positional argument from a pre-specified
     function
   - Complete unknown arguments
   - Easy to make a custom complete function
6. Powerful hook functions
   - Hook just before/after validation
   - Hook just before/after completion
   - Easy to regulate the behavior of parser with hooks
7. Several misc options
   - `terminal`: terminate further parsing at a particular argument
   - `deniable`: support '--no-' prefix to assign negative value
   - `on_default`: a default value when the option is specified without value


INSTALL
-------------------------------------------------------------------------------

```vim
NeoBundle 'lambdalisue/vital-ArgumentParser'
```

And call the following to bundle this plugin

```vim
:Vitalize . +ArgumentParser
```

USAGE
-------------------------------------------------------------------------------

Create a new instance of a parser with Vital.ArgumentParser.new() function.
Then define arguments with Vital.ArgumentParser.add_argument().

```vim
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
```

Then

```
:ArgumentParserDemo --foo
" {
"   'foo': 1,
"   '__args__': ['--foo'],
"   '__bang__': 0,
"   '__unknown__': [],
"   '__range__': [34, 34]
" }

:ArgumentParserDemo --foo --bar=bar
" {
"   'foo': 1,
"   'bar': 'bar',
"   '__args__': ['--foo', '--bar=bar'],
"   '__bang__': 0,
"   '__unknown__': [],
"   '__range__': [34, 34]
" }

:ArgumentParserDemo --help
" 
" :ArgumentParserDemo [--help] [--foo] [--bar={BAR}]
" 
" A description of the command
" 
" Optional arguments:
"   -h, --help       show this help
"   -f, --foo        A description of foo
"   -b, --bar={BAR}  A description of bar
" 
```

See `:help Vital.ArgumentParser` for more detail.


License
-------------------------------------------------------------------------------
The MIT License (MIT)

Copyright (c) 2014 Alisue, hashnote.net

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
