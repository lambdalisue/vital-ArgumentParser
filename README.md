vital-ArgumentParser  [![Build Status](https://travis-ci.org/lambdalisue/vital-ArgumentParser.svg)](https://travis-ci.org/lambdalisue/vital-ArgumentParser)
==============================================================================
A high functional argument parser

- Version:   0.2.0
- Author:   Alisue <lambdalisue@hashnote.net>
- Support:  Vim 7.3 and above


INTRODUCTIONS
==============================================================================

*Vital.ArgumentParser* is a high functional argument (option) parser.
There is a Vital.OptionParser but this parser is much flexible while:

1.  Positional argument is supported
2.  Positional assignment is supported (`--foo bar` instead of `--foo=bar`)
3.  Quotation is supported (`--foo="bar bar"` or `--foo "bar bar"`)
4.  Powerful validations
    -   Warn if one of required positional/optional argument is not specified
    -   Warn if an argument value is/isn't specified (follow the argument type)
    -   Warn if an argument value does not follow a specified regex pattern
    -   Warn if an argument is conflicted with others
    -   Warn if no superordinate arguments is specified
    -   Warn if one of dependencies is missing
5.  Several misc options are supported
    -   terminal: terminate parsing argument
    -   deniable: support '--no-' prefix to reverse value
6.  User can manipulate options with hooks


INSTALL
==============================================================================

```vim
NeoBundle 'lambdalisue/vital-ArgumentParser'
```

And call the following to bundle this plugin

```vim
:Vitalize . +ArgumentParser
```

USAGE
==============================================================================

Create a new instance of a parser with Vital.ArgumentParser.new() function.
Then define arguments with Vital.ArgumentParser.add_argument().

```vim
let s:V = vital#of('vital')
let s:A = s:V.import('ArgumentParser')

function! s:callback(opts) abort " {{{
  echo a:opts
endfunction " }}}

let s:parser = s:A.new({
      \ 'name': 'ArgumentParser',
      \ 'description': 'An ArgumentParser demo command',
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
```

Then, the `:ArgumentParse -h` will show

```
:ArgumentParser [positional1] [positional2] [--help] [--foo] [--bar] [--hoge] [--piyo] [--puyo[=PUYO]] [--poyo=POYO] [--payo={PAYO}] --required [--conflict1] [--conflict2] [--conflict3] [--superordinate1] [--superordinate2] [--subordinate] [--papa] [--mama] [--baby] [--pattern=PATTERN]

An ArgumentParser demo command

Positional arguments:
  positional1            
  positional2            

Optional arguments:
  -h, --help             show this help
      --foo              A simple argument
  -b, --bar              A simple argument with alias
      --hoge             multiline
                         description
      --piyo             multiline
                         description
                         with list
      --puyo[=PUYO]      ANY argument
      --poyo=POYO        VALUE argument
      --payo={PAYO}      CHOICE argument
      --required          (*)
      --conflict1        
      --conflict2        
      --conflict3        
      --superordinate1   
      --superordinate2   
      --subordinate      
      --papa             
      --mama             
      --baby             
      --pattern=PATTERN  
```

See `:help Vital.ArgumentParser`.
