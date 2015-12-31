let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V) abort " {{{
  let s:P = a:V.import('Prelude')
  let s:D = a:V.import('Data.Dict')
  let s:L = a:V.import('Data.List')
  let s:H = a:V.import('System.Filepath')
endfunction " }}}
function! s:_vital_created(module) abort " {{{
  if !exists('s:const')
    let s:const = {}
    let s:const.types = {}
    let s:const.types.any = 'ANY'
    let s:const.types.value = 'VALUE'
    let s:const.types.switch = 'SWITCH'
    let s:const.types.choice = 'CHOICE'
    lockvar s:const
  endif
  call extend(a:module, s:const)
endfunction " }}}
function! s:_vital_depends() abort " {{{
  return ['Prelude', 'Data.Dict', 'Data.List', 'System.Filepath']
endfunction " }}}
function! s:_dummy() abort " {{{
endfunction " }}}
function! s:_throw(msg) abort " {{{
  throw printf('vital: ArgumentParser: %s', a:msg)
endfunction " }}}
function! s:_ensure_list(x) abort " {{{
  return s:P.is_list(a:x) ? a:x : [a:x]
endfunction " }}}

" Public functions
function! s:splitargs(str) abort " {{{
  let single_quote = '\v''\zs[^'']+\ze'''
  let double_quote = '\v"\zs[^"]+\ze"'
  let bare_strings = '\v[^ \t''"]+'
  let pattern = printf('\v%%(%s|%s|%s)',
        \ single_quote,
        \ double_quote,
        \ bare_strings,
        \)
  return split(a:str, printf('\v%s*\zs%%(\s+|$)\ze', pattern))
endfunction " }}}
function! s:strip_quotes(str) abort " {{{
  if a:str =~# '\v^%(".*"|''.*'')$'
    return a:str[1:-2]
  else
    return a:str
  endif
endfunction " }}}
function! s:new(...) abort " {{{
  let settings = extend({
        \ 'name': '',
        \ 'description': '',
        \ 'auto_help': 1,
        \ 'validate_required': 1,
        \ 'validate_types': 1,
        \ 'validate_conflicts': 1,
        \ 'validate_superordinates': 1,
        \ 'validate_dependencies': 1,
        \ 'validate_pattern': 1,
        \ 'enable_positional_assign': 0,
        \ 'complete_unknown': function('s:complete_dummy'),
        \ 'unknown_description': '',
        \}, get(a:000, 0, {}))
  " validate unknown options
  let available_settings = [
        \ 'name',
        \ 'description',
        \ 'auto_help',
        \ 'validate_required',
        \ 'validate_types',
        \ 'validate_conflicts',
        \ 'validate_superordinates',
        \ 'validate_dependencies',
        \ 'validate_pattern',
        \ 'enable_positional_assign',
        \ 'complete_unknown',
        \ 'unknown_description',
        \]
  for key in keys(settings)
    if key !~# '^__\w' && index(available_settings, key) == -1
      call s:_throw(printf(
            \ 'Unknown setting "%s" is specified', key,
            \))
    endif
  endfor
  let parser = extend(deepcopy(s:parser), s:D.pick(settings, [
        \ 'name',
        \ 'auto_help',
        \ 'complete_unknown',
        \ 'validate_required',
        \ 'validate_types',
        \ 'validate_conflicts',
        \ 'validate_superordinates',
        \ 'validate_dependencies',
        \ 'validate_pattern',
        \ 'enable_positional_assign',
        \ 'unknown_description',
        \]))
  let parser.description = s:P.is_list(settings.description)
        \ ? join(settings.description, "\n")
        \ : settings.description
  if parser.auto_help
    call parser.add_argument(
          \ '--help', '-h', 'show this help',
          \)
  endif
  return parser
endfunction " }}}
" @vimlint(EVL104, 1, l:options)
" @vimlint(EVL104, 1, l:description)
" @vimlint(EVL104, 1, l:alias)
function! s:new_argument(name, ...) abort " {{{
  " determind name
  if a:name =~# '^--\?'
    let positional = 0
    let name = substitute(a:name, '^--\?', '', '')
  else
    let positional = 1
    let name = a:name
  endif
  " determind arguments
  if a:0 == 0 " add_argument({name})
    let alias = ''
    let description = ''
    let options = {}
  elseif a:0 == 1
    " add_argument({name}, {description})
    " add_argument({name}, {options})
    if s:P.is_string(a:1) || s:P.is_list(a:1)
      let alias = ''
      let description = a:1
      let options = {}
    else
      let alias = ''
      let description = ''
      let options = a:1
    endif
  elseif a:0 == 2
    " add_argument({name}, {alias}, {description})
    " add_argument({name}, {description}, {options})
    if s:P.is_string(a:2) || s:P.is_list(a:2)
      let alias = a:1
      let description = a:2
      let options = {}
    elseif s:P.is_dict(a:2)
      let alias = ''
      let description = a:1
      let options = a:2
    endif
  elseif a:0 == 3
    " add_argument({name}, {alias}, {description}, {options})
    let alias = a:1
    let description = a:2
    let options = a:3
  else
    call s:_throw('Too many arguments are specified')
  endif
  " validate unknown options
  let available_options = [
        \ 'alias',
        \ 'description',
        \ 'terminal',
        \ 'required',
        \ 'default',
        \ 'on_default',
        \ 'type',
        \ 'deniable',
        \ 'choices',
        \ 'pattern',
        \ 'complete',
        \ 'conflicts',
        \ 'dependencies',
        \ 'superordinates',
        \]
  for key in keys(options)
    if key !~# '^__\w' && index(available_options, key) == -1
      call s:_throw(printf(
            \ 'Unknown option "%s" is specified', key,
            \))
    endif
  endfor
  " create an argument instance
  let argument = extend(deepcopy(s:argument), extend({
        \ 'name': name,
        \ 'description': s:_ensure_list(description),
        \ 'positional': positional,
        \ 'alias': substitute(alias, '^-', '', ''),
        \ 'complete': function('s:_dummy'),
        \}, options))
  " automatically assign argument type
  if argument.type == -1
    if !empty(argument.choices)
      let argument.type = s:const.types.choice
    elseif !empty(argument.pattern)
      let argument.type = s:const.types.value
    elseif argument.complete != function('s:_dummy')
      let argument.type = s:const.types.value
    elseif argument.positional
      let argument.type = s:const.types.value
    else
      let argument.type = s:const.types.switch
    endif
  endif
  " automatically assign complete function
  if argument.complete == function('s:_dummy')
    if argument.type == s:const.types.choice
      let argument.complete = function('s:complete_choices')
    else
      let argument.complete = function('s:complete_dummy')
    endif
  endif
  " validate options
  if positional
    if !empty(argument.alias)
      call s:_throw(
            \ '"alias" option cannot be specified to a positional argument'
            \)
    elseif !empty(argument.default)
      call s:_throw(
            \ '"default" option cannot be specified to a positional argument'
            \)
    elseif argument.type != s:const.types.value && argument.type != s:const.types.choice
      call s:_throw(
            \ '"type" option cannot be ANY or SWITCH for a positional argument'
            \)
    elseif !empty(argument.conflicts)
      call s:_throw(
            \ '"conflicts" option cannot be specified to a positional argument'
            \)
    elseif !empty(argument.dependencies)
      call s:_throw(
            \ '"dependencies" option cannot be specified to a positional argument'
            \)
    elseif !empty(argument.superordinates)
      call s:_throw(
            \ '"superordinates" option cannot be specified to a positional argument'
            \)
    endif
  elseif !empty(argument.default) && argument.required
    call s:_throw(
          \ '"default" and "required" options cannot be specified together'
          \)
  elseif empty(argument.choices) && argument.type == s:const.types.choice
    call s:_throw(
          \ '"choices" option is required for CHOICE argument'
          \)
  elseif !empty(argument.pattern) && argument.type == s:const.types.switch
    call s:_throw(
          \ '"pattern" option cannot be specified for SWITCH argument'
          \)
  endif
  return argument
endfunction " }}}

function! s:complete_dummy(arglead, cmdline, cursorpos, ...) dict abort " {{{
  return []
endfunction " }}}
function! s:complete_files(arglead, cmdline, cursorpos, ...) dict abort " {{{
  let root = expand(get(self, '__complete_files_root', '.'))
  let root = s:H.realpath(s:H.remove_last_separator(root) . s:H.separator())
  let candidates = split(
        \ glob(s:H.join(root, a:arglead . '*'), 0),
        \ "\r\\?\n",
        \)
  " substitute 'root'
  call map(candidates, printf(
        \ 'substitute(v:val, ''^%s'', "", "")',
        \ escape(root, '\~.^$[]'),
        \))
  " substitute /home/<user> to ~/ if ~/ is specified
  if a:arglead =~# '^\~'
    call map(candidates, printf(
          \ 'substitute(v:val, ''^%s'', "~", "")',
          \ escape(expand('~'), '\~.^$[]'),
          \))
  endif
  call map(candidates, printf(
        \ 'isdirectory(v:val) ? v:val . "%s" : v:val',
        \ s:H.path_separator(),
        \))
  return candidates
endfunction " }}}
function! s:complete_choices(arglead, cmdline, cursorpos, ...) dict abort " {{{
  let options = get(a:000, 0, {})
  if !has_key(self, 'get_choices')
    return []
  endif
  let candidates = self.get_choices(options)
  call filter(candidates, printf('v:val =~# "^%s"', a:arglead))
  return candidates
endfunction " }}}

" Instance
let s:argument = {
      \ 'name': '',
      \ 'description': [],
      \ 'terminal': 0,
      \ 'positional': 0,
      \ 'required': 0,
      \ 'default': '',
      \ 'alias': '',
      \ 'type': -1,
      \ 'deniable': 0,
      \ 'choices': [],
      \ 'pattern': '',
      \ 'conflicts': [],
      \ 'dependencies': [],
      \ 'superordinates': [],
      \}
function! s:argument.get_choices(options) abort " {{{
  if s:P.is_funcref(self.choices)
    let candidates = self.choices(deepcopy(a:options))
  elseif s:P.is_list(self.choices)
    let candidates = self.choices
  else
    let candidates = []
  endif
  return candidates
endfunction " }}}

let s:parser = {
      \ 'hooks': {},
      \ 'arguments': {},
      \ '_arguments': [],
      \ 'positional': [],
      \ 'required': [],
      \ 'alias': {},
      \}
function! s:parser.register_argument(argument) abort " {{{
  " Validate argument
  if has_key(self.arguments, a:argument.name)
    call s:_throw(printf(
          \ 'An argument "%s" is already registered',
          \ a:argument.name,
          \))
  endif
  " register argument
  let self.arguments[a:argument.name] = a:argument
  call add(self._arguments, a:argument)
  " register positional
  if a:argument.positional
    call add(self.positional, a:argument.name)
  endif
  " register required
  if a:argument.required
    call add(self.required, a:argument.name)
  endif
  " register alias
  if !empty(a:argument.alias)
    let self.alias[a:argument.alias] = a:argument.name
  endif
endfunction " }}}
function! s:parser.unregister_argument(argument) abort " {{{
  " Validate argument
  if !has_key(self.arguments, a:argument.name)
    call s:_throw(printf(
          \ 'An argument "%s" has not been registered yet',
          \ a:argument.name,
          \))
  endif
  " unregister argument
  unlet! self.arguments[a:argument.name]
  call remove(self._arguments, index(self._arguments, a:argument))
  " unregister positional
  if a:argument.positional
    call remove(self.positional, index(self.positional, a:argument.name))
  endif
  " unregister required
  if a:argument.required
    call remove(self.required, index(self.required, a:argument.name))
  endif
  " unregister alias
  if !empty(a:argument.alias)
    unlet! self.alias[a:argument.alias]
  endif
endfunction " }}}
function! s:parser.add_argument(...) abort " {{{
  let argument = call('s:new_argument', a:000)
  call self.register_argument(argument)
  return argument
endfunction " }}}

function! s:parser.get_conflicted_arguments(name, options) abort " {{{
  let conflicts = self.arguments[a:name].conflicts
  if empty(conflicts)
    return []
  endif
  let conflicts_pattern = printf('\v^%%(%s)$', join(conflicts, '|'))
  return filter(keys(a:options), 'v:val =~# conflicts_pattern')
endfunction " }}}
function! s:parser.get_superordinate_arguments(name, options) abort " {{{
  let superordinates = self.arguments[a:name].superordinates
  if empty(superordinates)
    return []
  endif
  let superordinates_pattern = printf('\v^%%(%s)$', join(superordinates, '|'))
  return filter(keys(a:options), 'v:val =~# superordinates_pattern')
endfunction " }}}
function! s:parser.get_missing_dependencies(name, options) abort " {{{
  let dependencies = self.arguments[a:name].dependencies
  if empty(dependencies)
    return []
  endif
  let exists_pattern = printf('\v^%%(%s)$', join(keys(a:options), '|'))
  return filter(dependencies, 'v:val !~# exists_pattern')
endfunction " }}}
function! s:parser.get_positional_arguments() abort " {{{
  return deepcopy(self.positional)
endfunction " }}}
function! s:parser.get_optional_arguments() abort " {{{
  return map(filter(values(self.arguments), '!v:val.positional'), 'v:val.name')
endfunction " }}}
function! s:parser.get_optional_argument_aliases() abort " {{{
  return keys(self.alias)
endfunction " }}}

function! s:parser.parse(bang, range, ...) abort " {{{
  let cmdline = get(a:000, 0, '')
  let args = s:P.is_string(cmdline) ? s:splitargs(cmdline) : cmdline
  let options = self._parse_args(args, extend({
        \ '__bang__': s:P.is_string(a:bang) ? a:bang ==# '!' : a:bang,
        \ '__range__': a:range,
        \}, get(a:000, 1, {})))
  call self._regulate_options(options)
  " to avoid exception in validation
  if self.auto_help && get(options, 'help', 0)
    redraw | echo self.help()
    return {}
  endif
  call self.hooks.pre_validate(options)
  try
    call self._validate_options(options)
  catch /vital: ArgumentParser:/
    echohl WarningMsg
    redraw
    echo printf('%s validation error:', self.name)
    echohl None
    echo substitute(v:exception, '^vital: ArgumentParser: ', '', '')
    if self.auto_help
      echo printf("See a command usage by ':%s -h'",
            \ self.name,
            \)
    endif
    return {}
  endtry
  call self.hooks.post_validate(options)
  return options
endfunction " }}}
" @vimlint(EVL104, 1, l:name)
" @vimlint(EVL101, 1, l:value)
function! s:parser._parse_args(args, ...) abort " {{{
  let options = extend({
        \ '__unknown__': [],
        \ '__args__': [],
        \}, get(a:000, 0, {}))
  let options.__args__ = extend(options.__args__, a:args)
  let length = len(options.__args__)
  let cursor = 0
  let arguments_pattern = printf('\v^%%(%s)$', join(keys(self.arguments), '|'))
  let positional_length = len(self.positional)
  let positional_cursor = 0
  while cursor < length
    let cword = options.__args__[cursor]
    let nword = (cursor+1 < length) ? options.__args__[cursor+1] : ''
    if cword ==# '--'
      let cursor += 1
      let options.__terminated__ = 1
      break
    elseif cword =~# '^--\?'
      " optional argument
      let m = matchlist(cword, '\v^\-\-?([^=]+|)%(\=(.*)|)')
      let name = get(self.alias, m[1], m[1])
      if name =~# arguments_pattern
        if !empty(m[2])
          let options[name] = s:strip_quotes(m[2])
        elseif get(self, 'enable_positional_assign', 0) && !empty(nword) && nword !~# '^--\?'
          let options[name] = s:strip_quotes(nword)
          let cursor += 1
        else
          let options[name] = get(self.arguments[name], 'on_default', 1)
        endif
      elseif substitute(name, '^no-', '', '') =~# arguments_pattern
        let name = substitute(name, '^no-', '', '')
        if self.arguments[name].deniable
          let options[name] = 0
        else
          call add(options.__unknown__, cword)
        endif
      else
        call add(options.__unknown__, cword)
      endif
    else
      if positional_cursor < positional_length
        let name = self.positional[positional_cursor]
        let options[name] = s:strip_quotes(cword)
        let positional_cursor += 1
      else
        let name = ''
        call add(options.__unknown__, cword)
      endif
    endif
    " terminal check
    if !empty(name) && get(self.arguments, name, { 'terminal': 0 }).terminal
      let cursor += 1
      let options.__terminated__ = 1
      break
    else
      let cursor += 1
    endif
  endwhile
  " assign remaining args as unknown
  let options.__unknown__ = extend(
        \ options.__unknown__,
        \ options.__args__[ cursor : ],
        \)
  return options
endfunction " @vimlint(EVL104, 0, l:name) @vimlint(EVL101, 0, l:value) }}}
function! s:parser._regulate_options(options) abort " {{{
  " assign default values
  let exists_pattern = printf('\v^%%(%s)$', join(keys(a:options), '|'))
  for argument in values(self.arguments)
    if !empty(argument.default) && argument.name !~# exists_pattern
      let a:options[argument.name] = argument.default
    endif
  endfor
endfunction " }}}
function! s:parser._validate_options(options) abort " {{{
  if self.validate_required
    call self._validate_required(a:options)
  endif
  if self.validate_types
    call self._validate_types(a:options)
  endif
  if self.validate_conflicts
    call self._validate_conflicts(a:options)
  endif
  if self.validate_superordinates
    call self._validate_superordinates(a:options)
  endif
  if self.validate_dependencies
    call self._validate_dependencies(a:options)
  endif
  if self.validate_pattern
    call self._validate_pattern(a:options)
  endif
endfunction " }}}
function! s:parser._validate_required(options) abort " {{{
  let exist_required = keys(a:options)
  for name in self.required
    if index(exist_required, name) == -1
      call s:_throw(printf(
            \ 'Argument "%s" is required but not specified',
            \ name,
            \))
    endif
  endfor
endfunction " }}}
function! s:parser._validate_types(options) abort " {{{
  for [name, value] in items(a:options)
    if name !~# '\v^__.*__$'
      let type = self.arguments[name].type
      if type == s:const.types.value && s:P.is_number(value)
        call s:_throw(printf(
              \ 'Argument "%s" is VALUE argument but no value is specified',
              \ name,
              \))
      elseif type == s:const.types.switch && s:P.is_string(value)
        call s:_throw(printf(
              \ 'Argument "%s" is SWITCH argument but "%s" is specified',
              \ name, value,
              \))
      elseif type == s:const.types.choice
        let candidates = self.arguments[name].get_choices(a:options)
        let pattern = printf('\v^%%(%s)$', join(candidates, '|'))
        if s:P.is_number(value)
          call s:_throw(printf(
                \ 'Argument "%s" is CHOICE argument but no value is specified',
                \ name,
                \))
        elseif value !~# pattern
          call s:_throw(printf(
                \ 'Argument "%s" is CHOICE argument but an invalid value "%s" is specified',
                \ name, value,
                \))
        endif
      endif
    endif
    silent! unlet name
    silent! unlet value
  endfor
endfunction " }}}
function! s:parser._validate_conflicts(options) abort " {{{
  for [name, value] in items(a:options)
    if name !~# '\v^__.*__$'
      let conflicts = self.get_conflicted_arguments(name, a:options)
      if !empty(conflicts)
        call s:_throw(printf(
              \ 'Argument "%s" conflicts with an argument "%s"',
              \ name, conflicts[0],
              \))
      endif
    endif
    silent! unlet name
    silent! unlet value
  endfor
endfunction " }}}
function! s:parser._validate_superordinates(options) abort " {{{
  for [name, value] in items(a:options)
    if name !~# '\v^__.*__$'
      let superordinates = self.get_superordinate_arguments(name, a:options)
      if !empty(self.arguments[name].superordinates) && empty(superordinates)
        call s:_throw(printf(
              \ 'No superordinate argument(s) of "%s" is specified',
              \ name,
              \))
      endif
    endif
    silent! unlet name
    silent! unlet value
  endfor
endfunction " }}}
function! s:parser._validate_dependencies(options) abort " {{{
  for [name, value] in items(a:options)
    if name !~# '\v^__.*__$'
      let dependencies = self.get_missing_dependencies(name, a:options)
      if !empty(dependencies)
        call s:_throw(printf(
              \ 'Argument "%s" is required for an argument "%s" but missing',
              \ dependencies[0], name,
              \))
      endif
    endif
    silent! unlet name
    silent! unlet value
  endfor
endfunction " }}}
function! s:parser._validate_pattern(options) abort " {{{
  for [name, value] in items(a:options)
    if name !~# '\v^__.*__$'
      let pattern = self.arguments[name].pattern
      if !empty(pattern) && value !~# pattern
        call s:_throw(printf(
              \ 'A value of argument "%s" does not follow a specified pattern "%s".',
              \ name, pattern,
              \))
      endif
    endif
    silent! unlet name
    silent! unlet value
  endfor
endfunction " }}}
function! s:parser.complete(arglead, cmdline, cursorpos, ...) abort " {{{
  let cmdline = substitute(a:cmdline, '\v^[^ ]+\s', '', '')
  let cmdline = substitute(cmdline, '\v[^ ]+$', '', '')
  let options = extend(
        \ self._parse_args(s:splitargs(cmdline)),
        \ get(a:000, 0, {}),
        \)
  call self.hooks.pre_complete(options)
  if get(options, '__terminated__')
    if s:P.is_funcref(get(self, 'complete_unknown'))
      let candidates = self.complete_unknown(
            \ a:arglead,
            \ cmdline,
            \ a:cursorpos,
            \ options,
            \)
    else
      let candidates = []
    endif
  elseif empty(a:arglead)
    let candidates = []
    let candidates += self._complete_positional_argument_value(
          \ a:arglead,
          \ cmdline,
          \ a:cursorpos,
          \ options,
          \)
    let candidates += self._complete_optional_argument(
          \ a:arglead,
          \ cmdline,
          \ a:cursorpos,
          \ options,
          \)
  elseif a:arglead =~# '\v^\-\-?[^=]+\='
    let candidates = self._complete_optional_argument_value(
          \ a:arglead,
          \ cmdline,
          \ a:cursorpos,
          \ options,
          \)
  elseif a:arglead =~# '\v^\-\-?'
    let candidates = self._complete_optional_argument(
          \ a:arglead,
          \ cmdline,
          \ a:cursorpos,
          \ options,
          \)
  else
    let candidates = self._complete_positional_argument_value(
          \ a:arglead,
          \ cmdline,
          \ a:cursorpos,
          \ options,
          \)
  endif
  call self.hooks.post_complete(candidates, options)
  return candidates
endfunction " }}}
function! s:parser._complete_optional_argument_value(arglead, cmdline, cursorpos, options) abort " {{{
  let m = matchlist(a:arglead, '\v^\-\-?([^=]+)\=(.*)')
  let name = m[1]
  let value = m[2]
  if has_key(self.arguments, name)
    let candidates = self.arguments[name].complete(
          \ value, a:cmdline, a:cursorpos, a:options,
          \)
  else
    let candidates = []
  endif
  call self.hooks.post_complete_argument_value(candidates, a:options)
  return candidates
endfunction " }}}
function! s:parser._complete_optional_argument(arglead, cmdline, cursorpos, options) abort " {{{
  let candidates = []
  for argument in values(self.arguments)
    if has_key(a:options, argument.name) || argument.positional
      continue
    elseif !empty(argument.conflicts) && !empty(self.get_conflicted_arguments(argument.name, a:options))
      continue
    elseif !empty(argument.superordinates) && empty(self.get_superordinate_arguments(argument.name, a:options))
      continue
    endif
    if '--' . argument.name =~# '^' . a:arglead && len(argument.name) > 1
      call add(candidates, '--' . argument.name)
    elseif '-' . argument.name =~# '^' . a:arglead && len(argument.name) == 1
      call add(candidates, '-' . argument.name)
    endif
    if !empty(argument.alias) && '-' . argument.alias =~# '^' . a:arglead
      call add(candidates, '-' . argument.alias)
    endif
  endfor
  call self.hooks.post_complete_optional_argument(candidates, a:options)
  return candidates
endfunction " }}}
function! s:parser._complete_positional_argument_value(arglead, cmdline, cursorpos, options) abort " {{{
  let candidates = []
  let npositional = 0
  for argument in values(self.arguments)
    if argument.positional && has_key(a:options, argument.name)
      let npositional += 1
    endif
  endfor
  if !empty(a:arglead) && npositional > 0
    let npositional -= 1
  endif
  let cpositional = get(self.arguments, get(self.positional, npositional), {})
  if !empty(cpositional)
    let candidates = cpositional.complete(
          \ a:arglead, a:cmdline, a:cursorpos, a:options,
          \)
  endif
  call self.hooks.post_complete_positional_argument(candidates, a:options)
  return candidates
endfunction " }}}

function! s:parser.help() abort " {{{
  let definitions  = { 'positional': [], 'optional': [] }
  let descriptions = { 'positional': [], 'optional': [] }
  let commandlines = []
  for argument in self._arguments
    if argument.positional
      let [definition, description] = self._help_positional_argument(argument)
      call add(definitions.positional, definition)
      call add(descriptions.positional, description)
      if argument.required
        call add(commandlines, definition)
      else
        call add(commandlines, printf('[%s]', definition))
      endif
    else
      let [definition, description] = self._help_optional_argument(argument)
      let partial_definition = substitute(definition, '\v^%([ ]+|\-.,\s)', '', '')
      call add(definitions.optional, definition)
      call add(descriptions.optional, description)
      if argument.required
        call add(commandlines, printf('%s', partial_definition))
      else
        call add(commandlines, printf('[%s]', partial_definition))
      endif
    endif
  endfor
  " find a length of the longest definition
  let max_length = len(s:L.max_by(definitions.positional + definitions.optional, 'len(v:val)'))
  let buflines = []
  call add(buflines, printf(
        \ ':%s', join(filter([
        \ self.name,
        \ join(commandlines),
        \ empty(self.unknown_description)
        \   ? ''
        \   : printf('-- %s', self.unknown_description),
        \], '!empty(v:val)'))))
  call add(buflines, '')
  call add(buflines, self.description)
  if !empty(self.positional)
    call add(buflines, '')
    call add(buflines, 'Positional arguments:')
    for [definition, description] in s:L.zip(definitions.positional, descriptions.positional)
      let _definitions = split(definition, "\n")
      let _descriptions = split(description, "\n")
      let n = max([len(_definitions), len(_descriptions)])
      let i = 0
      while i < n
        let _definition = get(_definitions, i, '')
        let _description = get(_descriptions, i, '')
        call add(buflines, printf(
              \ printf('  %%-%ds  %%s', max_length),
              \ _definition,
              \ _description,
              \))
        let i += 1
      endwhile
    endfor
  endif
  call add(buflines, '')
  call add(buflines, 'Optional arguments:')
  for [definition, description] in s:L.zip(definitions.optional, descriptions.optional)
    let _definitions = split(definition, "\n")
    let _descriptions = split(description, "\n")
    let n = max([len(_definitions), len(_descriptions)])
    let i = 0
    while i < n
      let _definition = get(_definitions, i, '')
      let _description = get(_descriptions, i, '')
      call add(buflines, printf(
            \ printf("  %%-%ds  %%s", max_length),
            \ _definition,
            \ _description,
            \))
      let i += 1
    endwhile
  endfor
  return join(buflines, "\n")
endfunction " }}}
function! s:parser._help_optional_argument(arg) abort " {{{
  if empty(a:arg.alias)
    let alias = '    '
  else
    let alias = printf('-%s, ', a:arg.alias)
  endif
  if a:arg.deniable
    let deniable = '[no-]'
  else
    let deniable = ''
  endif
  if a:arg.type == s:const.types.any
    let definition = printf(
          \ '%s--%s%s[=%s]',
          \ alias,
          \ deniable,
          \ a:arg.name,
          \ toupper(a:arg.name)
          \)
  elseif a:arg.type == s:const.types.value
    let definition = printf(
          \ '%s--%s%s=%s',
          \ alias,
          \ deniable,
          \ a:arg.name,
          \ toupper(a:arg.name)
          \)
  elseif a:arg.type == s:const.types.choice
    let definition = printf(
          \ '%s--%s%s={%s}',
          \ alias,
          \ deniable,
          \ a:arg.name,
          \ toupper(a:arg.name)
          \)
  else
    let definition = printf(
          \ '%s--%s%s',
          \ alias,
          \ deniable,
          \ a:arg.name,
          \)
  endif
  let description = join(a:arg.description, "\n")
  if a:arg.required
    let description = printf('%s (*)', description)
  endif
  return [definition, description]
endfunction " }}}
function! s:parser._help_positional_argument(arg) abort " {{{
  let definition = printf('%s', a:arg.name)
  let description = join(a:arg.description, "\n")
  if a:arg.required
    let description = printf('%s (*)', description)
  endif
  return [definition, description]
endfunction " }}}

" Available user hoks
function! s:parser.hooks.pre_validate(options) abort " {{{
endfunction " }}}
function! s:parser.hooks.post_validate(options) abort " {{{
endfunction " }}}
function! s:parser.hooks.pre_complete(options) abort " {{{
endfunction " }}}
function! s:parser.hooks.post_complete(candidates, options) abort " {{{
endfunction " }}}
function! s:parser.hooks.post_complete_argument_value(candidates, options) abort " {{{
endfunction " }}}
function! s:parser.hooks.post_complete_optional_argument(candidates, options) abort " {{{
endfunction " }}}
function! s:parser.hooks.post_complete_positional_argument(candidates, options) abort " {{{
endfunction " }}}
function! s:parser.hooks.validate() abort " {{{
  let known_hooks = [
        \ 'pre_validate',
        \ 'post_validate',
        \ 'pre_complete',
        \ 'post_complete',
        \ 'post_complete_argument_value',
        \ 'post_complete_optional_argument',
        \ 'post_complete_positional_argument',
        \]
  for key in keys(self)
    if key !=# 'validate' && index(known_hooks, key) == -1
      call s:_throw(printf(
            \ 'Unknown hook "%s" is found.',
            \ key,
            \))
    endif
  endfor
endfunction " }}}

let &cpo = s:save_cpo
unlet s:save_cpo
"vim: sts=2 sw=2 smarttab et ai textwidth=0 fdm=marker
