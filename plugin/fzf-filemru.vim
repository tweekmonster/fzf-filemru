if exists('g:fzf_filemru_loaded') | finish | endif
let g:fzf_filemru_loaded = 1

let s:filemru_bin = resolve(printf('%s/../bin/filemru.sh', expand('<sfile>:p:h')))
let s:ignore_patterns = '\.git/\|\_^/tmp/'


function! s:update_mru(files)
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
function! s:filemru_sink(lines)
  call s:update_mru(a:lines)
  if exists('s:common_sink')
    call s:common_sink(a:lines)
  endfor
endfunction


function! s:fzf_filemru(dir, ...)
  if !exists('s:common_sink')
    " Grab a reference to fzf.vim's s:common_sink
    let default_opts = fzf#vim#wrap({})
    let s:common_sink = get(default_opts, 'sink*')
  endif

  let fzf_source = s:filemru_bin
  let buffer_file = expand('%')
  if empty(&l:buftype) && !empty(&l:filetype) && !empty(buffer_file)
    let fzf_source .= ' --exclude '.buffer_file
  endif
  let fzf_source .= ' --files'
  let options = {
        \   'source': fzf_source,
        \   'sink*': function('s:filemru_sink'),
        \ }
  if get(g:, 'fzf_filemru_nosort', 0)
    let options['options'] = '--no-sort'
  endif
  let extra = extend(copy(get(g:, 'fzf_layout', g:fzf#vim#default_layout)), options)
  call fzf#vim#files(a:dir, extra)
endfunction


command! -nargs=? -complete=dir FilesMru call s:fzf_filemru(<q-args>)


if get(g:, 'fzf_filemru_bufwrite', 0)
  augroup fzf_filemru
    autocmd!
    autocmd BufWritePost * call s:update_mru([expand('%')])
  augroup END
endif
