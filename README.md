vital-ArgumentParser
==============================================================================
[![Travis CI](https://img.shields.io/travis/lambdalisue/vital-ArgumentParser/master.svg?style=flat-square&label=Travis%20CI)](https://travis-ci.org/lambdalisue/vital-ArgumentParser) [![AppVeyor](https://img.shields.io/appveyor/ci/lambdalisue/vital-ArgumentParser/master.svg?style=flat-square&label=AppVeyor)](https://ci.appveyor.com/project/lambdalisue/vital-ArgumentParser/branch/master) ![Version 1.1.0](https://img.shields.io/badge/version-1.1.0-yellow.svg?style=flat-square) ![Support Vim 7.3 or above](https://img.shields.io/badge/support-Vim%207.3%20or%20above-yellowgreen.svg?style=flat-square) [![MIT License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](LICENSE) [![Doc](https://img.shields.io/badge/doc-%3Ah%20vital--ArgumentParser-orange.svg?style=flat-square)](doc/vital-argument-parser.txt)

A high functional argument parser


Introductions
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

Plugins which use vital-ArgumentParser
-------------------------------------------------------------------------------

- [lambdalisue/vim-gista](https://github.com/lambdalisue/vim-gista) : A gist manipulation plugin
- [lambdalisue/vim-gita](https://github.com/lambdalisue/vim-gita) : A git manipulation plugin

Let me know if you are using this module ;-)

Install
-------------------------------------------------------------------------------

```vim
NeoBundle 'lambdalisue/vital-ArgumentParser'
```

And call the following to bundle this plugin

```vim
:Vitalize . +ArgumentParser
```

Usage
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
        \ :call s:command(<q-bang>, [<line1>, <line2>], <q-args>)
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

### Available options for a new instance

Available options for `{options}` of `Vital.ArgumentParser.new({options})`.
The default values of all switch options except `enable_positional_assign` are 1 (enabled).

| Key name | Description |
| --- | --- |
| `name` | A name of the command used in `help()` method |
| `description` | A description of the command used in `help()` method. `List` or `String` is available |
| `auto_help` | 1 to create `-h/--help` argument automatically. |
| `validate_required` | 1 to validate missing required arguments based on `required` option |
| `validate_types` | 1 to validate invalid value assignments based on `type` option |
| `validate_conflicts` | 1 to validate conflicted arguments based on `conflicts` option |
| `validate_superordinates` | 1 to validate missing superordinate arguments based on `superordinates` option |
| `validate_dependencies` | 1 to validate missing dependencies based on `depends` option |
| `validate_pattern` | 1 to validate invalid pattern assignment based on `pattern` option |
| `enable_positional_assign` | 1 to enable `-foo VALUE` type assignment. Default is 0 |
| `complete_unknown` | A `Funcref` used to complete unknown arguments |
| `unknown_description` | A description of unknown arguments used in `help()` method |

The following code create a new parser instance with all options.

```vim
let parser = s:A.new({
    \ 'name': 'Hello',
    \ 'description': 'Goodbye',
    \ 'auto_help': 1,
    \ 'validate_required': 1,
    \ 'validate_types': 1,
    \ 'validate_conflicts': 1,
    \ 'validate_superordinates': 1,
    \ 'validate_dependencies': 1,
    \ 'validate_pattern': 1,
    \ 'enable_positional_assign': 0,
    \ 'complete_unknown': s:A.complete_dummy,
    \ 'unknown_description': 'DUMMY',
    \})
echo parsr.help()
"
" :Hello -- DUMMY
"
" Goodbye
"
" Optional arguments:
"   -h, --help  show this help
"
```

See `:help Vital.ArgumentParser.new()` for more detail.

### Available options for a new argument

Available options for `{options}` of `parser.add_argument({name}, {description}, {options})`.

| Key name | Description |
| --- | --- |
| `description` | A description of the argument used in `help()` method |
| `alias` | A short name of the argument. Usually the value starts from a single dash (e.g. `-f`) |
| `terminal` | 1 to terminate further parsing after this argument. Useful to create sub-actions like `git XXX` commands |
| `required` | 1 to throw an exception when the argument is not specified |
| `default` | A default value of the argument |
| `on_default` | A default value of the argument when the argument is specified without value assignment |
| `type` | Specify a type of the argument. See `:help Vital.ArgumentParser-constants.types` |
| `deniable` | 1 to allow a negative assignment with `--no-` prefix (e.g. `--verbose` vs `--no-verbose`) |
| `choices` | A `List` or `Funcref` which return a `List` to restrict available values of the argument |
| `pattern` | A regex pattern to restrict available values of the argument |
| `complete` | A complete `Funcref` used to complete the value |
| `conflicts` | An argument name `List` to specify arguments which conflict with this argument |
| `dependencies` | An argument name `List` to specify arguments which this argument depends |
| `superordinates` | An argument name `List` to specify superordinate arguments of this argument |

See `:help Vital.ArgumentParser.new_argument()` or `:help Vital.ArgumentParser-instance.add_argument()`


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
