#!/bin/bash

bt-require keymap.sh


DIRS_HISTORY_FILE="$BT_CONFIG/dirs.history"
DIRS_HISTORY_SIZE=50

_dirs_historyPrint() {
   touch "$DIRS_HISTORY_FILE"
   nl -w 5 "$DIRS_HISTORY_FILE"
}

_dirs_historyFetch() {
   touch "$DIRS_HISTORY_FILE"
   local nr=${1:-'$'}
   ! -0 "$nr" && sed -n "$nr p" < "$DIRS_HISTORY_FILE"
}

_dirs_historyAddPwd() {
   touch "$DIRS_HISTORY_FILE"
   local dir="$(dirs +0)"
   grep -v "^$dir\$" <"$DIRS_HISTORY_FILE" | tail "-$((DIRS_HISTORY_SIZE - 1))" | sponge "$DIRS_HISTORY_FILE"
   echo "$dir" >>"$DIRS_HISTORY_FILE"
}


function chdir() {
    is-help "$1" && {
       \cd --help 2>&1
       echo "
Bash Toolkit extension to the standard cd Options:
  -c   Clear dir history
  --   Print dir history
  -N   Go to the dir with index N in history (press <tab> after typing - to use autocompletion)
"
       return
   }
   [[ "$1" == "--" ]] && {
       _dirs_historyPrint;
       return 0
   }
   [[ "$1" == "-c" ]] && {
       _dirs_initEmptyHistory; # TODO
       return 0
   }
   local option="$1";
   local dir="${1-"~"}";
   if [[ "$dir" =~ ^-[0-9]+$ ]]
   then
       dir="$(_dirs_historyFetch "${dir:1}")";
       -n "$dir" || {
           err 'No dir with such index in history.';
           return 1
       };
       option='';
   elif ! [[ "$dir" =~ ^-.+ ]]
   then
       option='';
   else
       dir="${2:-"~"}";
   fi
   local tildeExpandedDir="${dir/\~/$HOME}";
   \cd $option "$tildeExpandedDir" || return $?;
   _dirs_historyAddPwd;
   return 0
}

_histdir-tab-completion() {
   local cword=${#COMP_WORDS[@]}
   local arg=${COMP_WORDS[1]}
   if (( COMP_CWORD == 1 )) && (( cword == 2 )) && [[ "$arg" =~ ^- ]]
   then
      COMPREPLY=( '-NR<tab>' '-REGEX<tab>' )
      if is-uint "${arg:1}"
      then
         local pattern="^\s*${arg:1}\s*\s"
         COMPREPLY=( "$(chdir -- | sed -n "/$pattern/ {s/$pattern//; p}")" )
      else
         local phrase
         local completeIfOne
         if [[ "${arg:1:1}" = "-" ]]
         then
            phrase="${arg:2}"
         else
            phrase="${arg:1}"
            completeIfOne=1
         fi
         local lines=$(chdir -- | grep -i "$phrase" | wc -l)
         if [[ "$lines" = "1" ]] && [[ "$completeIfOne" ]]
         then
            COMPREPLY=( "$(chdir -- | grep "$phrase" | sed "s/^\s*\w*\s*//")" )
         else
            for line in "$(chdir -- | grep -E --color=always -i "$phrase")"
            do
                echo -ne "\n$line"
            done
         fi
      fi
   fi
}


keymap-macro-def filter-dir-history @clear-line 'cd -' @end-of-line '\t'
keymap-bind filter-dir-history Alt-PgUp Alt-PgDown Ctrl-PgUp Ctrl-PgDown

alias cd=chdir
complete -o nospace -o dirnames -F _histdir-tab-completion cd
