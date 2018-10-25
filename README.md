# FZF File MRU

Vim plugin that tracks your most recently and frequently used files
while using the [fzf.vim](https://github.com/junegunn/fzf.vim) plugin.

![Sweet FZF MRU GIF](https://cloud.githubusercontent.com/assets/111942/14758993/2dcf6748-08e0-11e6-9b0a-3f4d33d5c87c.gif)

This plugin provides the `FilesMru` and `ProjectMru` commands, which are
basically a pass-throughs to the `Files` command.  So, all you really need to
do is use `FilesMru` instead of `Files`.

When using `FilesMru` or `ProjectMru`, FZF will display files like usual,
except your most recently used files (matching the working directory) will
appear before all other files.

`ProjectMru` does the same thing as `FilesMru` except that it uses
`git ls-tree` to display files after MRU files (and before other found files),
and ignores repository submodule directories.

`UpdateMru` is a utility command that allows you to manually update the MRU.

MRU files are tracked in `$XDG_CACHE_HOME/fzf_filemru`.  A timestamp (rounded
to 2 minute intervals) and selection count is used to determine recency and
frequency.


## Example Usage

```vim
nnoremap <c-p> :FilesMru --tiebreak=end<cr>
```

The MRU list is updated when a file is saved or selected from the FZF menu.
Though not recommended, you could update the MRU list when a file is opened by
other means with the following script:

```vim
augroup custom_filemru
  autocmd!
  autocmd BufWinEnter * UpdateMru
augroup END
```


## Requirements

- [fzf.vim](https://github.com/junegunn/fzf.vim)
- bash
- awk
- GNU or MacOS `date` (supporting the `%s` format option)


# Command Usage

The commands ignore the original `directory` argument and instead takes flags
that are passed FZF.  Run `fzf --help` to see what flags you can pass.  A
decent flag to use is `--tiebreak=index` which uses the initial order of the
listed file as a secondary sort.  `--tiebreak=end` will do a better job of
sorting filename matches first.


## Options

- `g:fzf_filemru_bufwrite` - Update the MRU on `BufWritePost`.  This can be
  useful if you want your most saved files to appear near the top of the
  results.  Default: `0`
- `g:fzf_filemru_git_ls` - Use `git ls-tree` to display repo files before other
  files that are found with the the finder command.  Always enabled for
  `ProjectMru`.  Default: `0`
- `g:fzf_filemru_ignore_submodule` - Ignore git submodule directories.  Always
  enabled for `ProjectMru`.  Default: `0`
- `g:fzf_filemru_colors` - Colors for file prefixes.  Uses the xterm 256
  [color palette][colors].  Default: `{'mru': 6, 'git': 3}`.

**Note:** Even if git submodule files are ignored, they can still appear in the
MRU.


## Command Line

You can use `bin/filemru.sh` directly from the command line.  It will act as
[fzf](https://github.com/junegunn/fzf) for finding files, but will update the
MRU with your file selections.  This is currently not useful in the shell on
its own.


### Command Line Switches

- `--exclude` - Exclude a file from MRU output.  Must be relative to the
  current directory.
- `--files` | Just find files with MRU files displayed first and exit.
- `--update` | Updates the MRU with the files specified after this switch.  The
  files must be relative to the current directory.
- `--git` | Use `git ls-tree` to display repo files after MRU files, but before
  other found files.
- `--ignore-submodules` | Ignore git submodule directories.
- `--mru-color` | Color for the MRU prefix.
- `--git-color` | Color for the Git prefix.


[colors]: https://upload.wikimedia.org/wikipedia/en/1/15/Xterm_256color_chart.svg
