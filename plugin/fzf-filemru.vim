if exists('g:fzf_filemru_loaded') | finish | endif
let g:fzf_filemru_loaded = 1

let s:filemru_bin = resolve(printf('%s/../bin/filemru.sh', expand('<sfile>:p:h')))
let s:ignore_patterns = '\.git/\|\_^/tmp/'


function! s:update_mru(files) abort
  let selections = filter(copy(a:files), '!empty(v:val) && v:val !~# s:ignore_patterns')
  if empty(selections)
    return
  endif

  let l:cmd = [s:filemru_bin, '--update']
  if has('nvim')
    " Use Neovim's jobstart to avoid the delay
    call jobstart(l:cmd + selections)
  else
    call system(join(l:cmd + map(selections, 'shellescape(v:val)'), ' '))
  endif
endfunction


function! s:cmd_update_mru(verbose, ...) abort
  let cwd = getcwd()
  let arg_files = filter(copy(a:000), '!empty(v:val)')

  if empty(arg_files) && empty(&buftype) && &buflisted
    let arg_files = filter([expand('%')], '!empty(v:val)')
  endif

  let update_files = []
  for fname in arg_files
    let fname = fnamemodify(fname, ':p')
    let prefix = strpart(fname, 0, strlen(cwd))
    if prefix !=# cwd
      if a:verbose
        echohl ErrorMsg
        echo 'Not in current dirctory:' fname
        echohl None
      endif
      continue
    endif

    call add(update_files, strpart(fname, strlen(prefix) + 1))
  endfor

  if !empty(update_files)
    call s:update_mru(update_files)
  elseif a:verbose
    echohl ErrorMsg
    echo 'No files to add to MRU'
    echohl None
  endif
endfunction


" Create FZF options.  Wraps the 'sink*' to clean the file list and update the
" MRU before passing it to the common_sink.
" Reference:
" https://github.com/junegunn/fzf.vim/blob/5a088b24269352885d80525258040bfda4685b1c/autoload/fzf/vim.vim#L404-L415
function s:wrap_options(options) abort
  try
    let wrapped = fzf#wrap('', a:options)
  catch /E117/
    let wrapped = fzf#vim#wrap(a:options)
    echohl WarningMsg
    echomsg '[fzf-filemru] junegunn/fzf is outdated.'
    echohl None
  endtry

  let wrapped.common_sink = remove(wrapped, 'sink*')
  function! wrapped.sink(lines) abort
    let selections = []
    for l in a:lines
      let l = substitute(l, '^\(\s*\(git\|mru\|\-\)\s\+\)', '', '')
      call add(selections, l)
    endfor
    call s:update_mru(selections)
    return self.common_sink(selections)
  endfunction
  let wrapped['sink*'] = remove(wrapped, 'sink')
  return wrapped
endfunction


function! s:invoke(git_ls, ignore_submodule, options) abort
  let fzf_source = s:filemru_bin
  let exclude = expand('%')
  if empty(&l:buftype) && !empty(exclude)
    let fzf_source .= ' --exclude '.exclude
  endif

  if a:git_ls
    let fzf_source .= ' --git'
  endif

  if a:ignore_submodule
    let fzf_source .= ' --ignore-submodules'
  endif

  let colors = get(g:, 'fzf_filemru_colors', {'mru': 6, 'git': 3})
  for c in keys(colors)
    let cn = get(colors, c, '')
    if !cn
      continue
    endif
    let fzf_source .= printf(' --%s-color %d', c, cn)
  endfor

  let fzf_source .= ' --files'

  call fzf#vim#files('', s:wrap_options({
        \   'source': fzf_source,
        \   'options': a:options.' --ansi --nth=2',
        \ }))
endfunction


function! s:fzf_filemru(...) abort
  call s:invoke(
        \ get(g:, 'fzf_filemru_git_ls', 0),
        \ get(g:, 'fzf_filemru_ignore_submodule', 0),
        \ join(a:000, ' '))
endfunction


function! s:fzf_projectmru(...) abort
  call s:invoke(1, 1, join(a:000, ' '))
endfunction


command! -nargs=* FilesMru call s:fzf_filemru(<q-args>)
command! -nargs=* ProjectMru call s:fzf_projectmru(<q-args>)
command! -nargs=* -bang UpdateMru call s:cmd_update_mru(<bang>0, <q-args>)


if get(g:, 'fzf_filemru_bufwrite', 0)
  augroup fzf_filemru
    autocmd!
    autocmd BufWritePost * call s:update_mru([expand('%')])
  augroup END
endif
