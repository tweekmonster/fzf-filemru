# FZF File MRU

This is a Vim plugin that tracks your most recently and frequently used files
while using the [fzf.vim](https://github.com/junegunn/fzf.vim) plugin.

This plugin provides the `FilesMru` command, which is basically a pass-through
to the `Files` command.  So, all you really need to do is use `FilesMru`
instead of `Files`.

When using `FilesMru`, FZF will display files like usual, except your most
recently used files (matching the working directory) will appear before all
other files.

MRU files are tracked in `$XDG_CACHE_HOME/fzf_filemru`.  A timestamp (rounded
to 2 minute intervals) and selection count is used to determine recency and
frequency.


## Example Usage

```vim
nnoremap <c-p> :FilesMru<cr>
```


## Requirements

- [fzf.vim](https://github.com/junegunn/fzf.vim)
- bash
- gawk


## Options

Option | Description
------ | -----------
`g:fzf_filemru_bufwrite` | Update the MRU on `BufWritePost`.  This can be useful if you want your most saved files to appear near the top of the results.  Default: `0`


## Command Line

You can use `bin/filemru.sh` directly from the command line.  It will act as
[fzf](https://github.com/junegunn/fzf) for finding files, but will update the
MRU with your file selections.  This is currently not useful in the shell on
its own.


### Command Line Switches

Switch | Description
------ | -----------
--files | Just find files with MRU files displayed first and exit.
--update | Updates the MRU with the files specified after this switch.  The files must be relative to the current directory.
