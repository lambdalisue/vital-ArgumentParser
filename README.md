vital-ArgumentParser
==============================================================================
A high functional argument parser

- Version:   0.1.0
- Author:   Alisue <lambdalisue@hashnote.net>
- Support:  Vim 7.3 and above


INTRODUCTIONS
==============================================================================

*Vital.ArgumentParser* is a high functional argument (option) parser.
There is a Vital.OptionParser but this parser is much flexible while:

1. Argument can be defined as a required argument. Validation will fail if not
   all required arguments are specified.
2. Argument behavior can be regulated with 'kind' option.
   Vital.ArgumentParser-kinds-switch does not take any value,
   Vital.ArgumentParser-kinds-value reqiure a value,
   Vital.ArgumentParser-kinds-any can be used as a switch or value, and
   Vital.ArgumentParser-kinds-choice require a value listed in 'choices'
   option
3. When more than two conflicted arguments are specified, it will tell the
   user that these arguments are conflicted and cannot be used in the same
   time (See Vital.ArgumentParser-conflict_with)
4. Arguments can be defined as subordinations. The subordination arguments
   cannot be specified without parents (See
   Vital.ArgumentParser-subordination_of)
5. Arguments can depend on several other arguments. The argument cannot be
   specified while all dependencies are resolved (See
   Vital.ArgumentParser-depend_on)
6. There are several validations and you can control which validations should
   be performed (See Vital.ArgumentParser-validation)
7. There are several hooks to manipulate the arguments in each steps (See
   Vital.ArgumentParser-hooks)


INSTALL
==============================================================================

```vim
NeoBundle 'lambdalisue/vital-ArgumentParser'
```

USAGE
==============================================================================

Create a new instance of a parser with Vital.ArgumentParser.new() function.
Then define arguments with Vital.ArgumentParser.add_argument(). If you need,
you can define hooks (Vital.ArgumentParser-hooks) in this time.
This library's interface is inspired by ArgumentParser in Python.

```vim
" make a argument parser instance
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

" sample command
command! -nargs=? -range=% -bang Hoge
	\ :call Command(<q-bang>, [<line1>, <line2>], <f-args>)

Hoge! --foo --bar --hoge a --piyo Hi
" => {
"	'__bang__': 1,
"	'__range__': [1, 56],
"	'__args__': ['foo', 'bar', 'hoge', 'piyo'],
"	'__unknown__': [],
"	'foo': 1,
"	'bar': 1,
"	'hoge': 'a',
"	'piyo': 'Hi',
" }

" show help
Hoge --help
"
" Arguments:
"     --foo [FOO]          description of the argument
"                          (kind: ANY)
" 
" -h, --help               show this help message
"                          (kind: SWITCH)
" 
" -a, --ahya [AHYA]        description of the argument
"                          (kind: ANY)
" 
"     --private [PRIVATE]  a visibility flag of command
"                          (kind: ANY)
"                          (conflict_with: visibility)
"                          (subordination_of: add, change, delete)
" 
" -h, --hoge {choice}      description of the argument
"                          (kind: CHOICE)
"                          ({choice}: a, b, c)
" 
"     --bar                description of the argument
"                          (kind: SWITCH)
" 
"     --change [CHANGE]    a command to change something
"                          (kind: ANY)
"                          (conflict_with: command)
" 
"     --delete [DELETE]    a command to delete something
"                          (kind: ANY)
"                          (conflict_with: command)
" 
"     --add [ADD]          a command to add something
"                          (kind: ANY)
"                          (conflict_with: command)
" 
" -p, --piyo [PIYO]        description of the argument
"                          (kind: ANY)
"                          (required)
" 
"     --public [PUBLIC]    a visibility flag of command
"                          (kind: ANY)
"                          (conflict_with: visibility)
"                          (subordination_of: add, change, delete)
" 
```


See `:help Vital.ArgumentParser`.
