#!/bin/bash
CACHE=${XDG_CACHE_HOME:-$HOME/.cache}
MRU_MAX=200
# MRU_FILE is a list of files that were selected in FZF through this script.
# Each line is 3 comma separated values of: timestamp, select count, file name
# The select count is used as a tie breaker for lines with the same timestamp.
MRU_FILE=$CACHE/fzf_filemru
DEFAULT_COMMAND="find . -path '*/\\.*' -prune -o -type f -print -o -type l -print 2> /dev/null | sed s/^..//"

if [ ! -d "$CACHE" ]; then
  mkdir -p "$CACHE"
fi

ignore_git_submodules=0
git_ls=0
print_files=0
exclude_file=""


update_mru() {
  # Update MRU_FILE with new selections.  New selections are moved to the top
  # of the file.
  SELECTION_PATHS=""
  for fn in "${@}"; do
    fn="$PWD/$fn"
    if [ -e "$fn" ]; then
      SELECTION_PATHS+="$fn,"
    fi
  done
  SELECTION_PATHS="${SELECTION_PATHS%,}"

  # Get the current contents.  cat'ing the file in the command below blanks the
  # file before awk can get to it.  I suspect witchcraft.
  CURRENT=$(cat $MRU_FILE)

  echo "$CURRENT" | awk -F',' '
    BEGIN {
      ts = systime()
      ts -= (ts % 120)
      lastfound = 1
      split("'$SELECTION_PATHS'", files, ",")
      for (i in files) {
        selections[files[i]] = 1
      }
    }

    ($3 in selections) { found[NR] = 1; lastfound++ } { lines[NR] = $0 }

    END {
      if (lastfound > 1) {
        for (line in found) {
          $0 = lines[line]; $1 = ts; $2 += 1; print $1","$2","$3
        }
      }
      else {
        for (sel in selections) {
          print ts",1,"sel;
        }
      }

      i = 1
      p = 1
      while (i <= NR && p <= '$MRU_MAX') {
        if (!(i in found)) {
          print lines[i];
          p++;
        }
        i++;
      }
    }' | sort -t, -k1 -k2 -g -r > $MRU_FILE
}


while [[ $# > 0 ]]; do
  case $1 in
    --exclude)
      exclude_file="$PWD/$2"
      shift
      ;;
    --files)
      print_files=1
      ;;
    --git)
      git_ls=1
      ;;
    --ignore-submodules)
      ignore_git_submodules=1
      ;;
    --update)
      shift
      update_mru $@
      exit $?
      ;;
  esac
  shift
done


GREP_EXCLUDE=""
git_root=$(git rev-parse --show-toplevel 2> /dev/null)
if [[ $ignore_git_submodules -eq 1 && -n "$git_root" && -e "$git_root/.gitmodules" ]]; then
  for p in $(awk '/path =/{ print $3 }' "$git_root/.gitmodules"); do
    p="$git_root/$p"
    GREP_EXCLUDE+="${p##$PWD/}|"
  done
fi


MRU=""
if [ -f "$MRU_FILE" ]; then
  files=$(cat "$MRU_FILE" | cut -d, -f3 | grep "^$PWD")
  for fn in $files; do
    if [ -e "$fn" ]; then
      cut_fn="${fn##$PWD/}"
      GREP_EXCLUDE+="${cut_fn}|"
      if [ "$fn" != "$exclude_file" ]; then
        MRU+="$cut_fn\n"
      fi
    fi
  done
fi
GREP_EXCLUDE="${GREP_EXCLUDE%|}"


if [[ $git_ls -eq 1 ]]; then
  for p in $(git ls-tree --name-only -r HEAD | grep -E -v "($GREP_EXCLUDE)"); do
    p="$git_root/$p"
    cut_fn="${p##$PWD/}"
    GREP_EXCLUDE+="${cut_fn}|"
    MRU+="${cut_fn}\n"
  done
  GREP_EXCLUDE="${GREP_EXCLUDE%|}"
fi

FIND_CMD=${FZF_DEFAULT_COMMAND:-$DEFAULT_COMMAND}
if [ -n "$GREP_EXCLUDE" ]; then
  FIND_CMD+=" | grep -E -v '($GREP_EXCLUDE)'"
fi


# Just find files and exit
if [ $print_files -eq 1 ]; then
  echo -n -e "$MRU"
  sh -c "$FIND_CMD"
  exit $?
fi


# Act as FZF and update FILE_MRU after selection is made
FIND_CMD="echo -n ""\$_FZF_MRU"" && $FIND_CMD"
SELECTIONS=($(exec env _FZF_MRU="$MRU" FZF_DEFAULT_COMMAND="$FIND_CMD" fzf))

if [ ${#SELECTIONS[@]} -eq 0 ]; then
  exit $?
fi

update_mru "${SELECTIONS[@]}"
echo "${SELECTIONS[@]}"
