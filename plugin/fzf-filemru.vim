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


" Update MRU and pass-through to s:common_sink
function! s:filemru_sink(lines) abort
  let selections = []
  for l in a:lines
    let l = substitute(l, '^\(\s*\S\+\s*\)', '', '')
    call add(selections, l)
  endfor
  call s:update_mru(selections)
  if exists('s:common_sink')
    call s:common_sink(selections)
  endfor
endfunction


function! s:invoke(git_ls, ignore_submodule, options) abort
  if !exists('s:common_sink')
    " Grab a reference to fzf.vim's s:common_sink
    let s:common_sink = get(fzf#vim#wrap({}), 'sink*')
  endif

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
  let options = {
        \   'source': fzf_source,
        \   'sink*': function('s:filemru_sink'),
        \   'options': a:options.' --ansi --nth=2',
        \ }
  let extra = extend(copy(get(g:, 'fzf_layout', g:fzf#vim#default_layout)), options)
  call fzf#vim#files('', extra)
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


if get(g:, 'fzf_filemru_bufwrite', 0)
  augroup fzf_filemru
    autocmd!
    autocmd BufWritePost * call s:update_mru([expand('%')])
  augroup END
endif
