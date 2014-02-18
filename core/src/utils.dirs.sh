#!/bin/bash


function is-dir-empty() {
   local dir="${1:-.}"
   [ "${dir}" = "$(find "${dir}")" ]
}
export -f is-dir-empty


DIRHISTFILE=${HOME}/.dirstack
DIRHISTSIZE=50

function _dirs-history-print() {
   nl -w 5 "${DIRHISTFILE}"
}

function _dirs-history-clear() {
   echo -n > "${DIRHISTFILE}"
}

function _dirs-history-fetch() {
   local nr=${1:-'$'}
   sed -n "${nr} p" < "${DIRHISTFILE}"
}

function _dirs-history-add-pwd() {
   local dir="$(dirs +0)"
   grep -v "^${dir}\$" <"${DIRHISTFILE}" | tail "-$((DIRHISTSIZE - 1))" | sponge "${DIRHISTFILE}"
   echo "${dir}" >>"${DIRHISTFILE}"
}


function chdir() {
   [ "${1}" == "--help" ] && {
      \cd --help 2>&1 | sed '1 d'
      echo "       or: cd -c"
      echo "Options:
  -P   Do not follow symbolic links
  -L   Follow symbolic links (default)
  -c   Clear dir history
Special values for dir:
  -    Go to previous directory
  --   Print dir history
  -N   Go to dir with given number in history
"
      return 127
   }

   [ "${1}" == "--" ] && {
      _dirs-history-print
      return 0
   }

   [ "${1}" == "-c" ] && {
      _dirs-history-clear
      return 0
   }

   local option="${1}"
   local dir="${1-"~"}"
   if [[ "${dir}" =~ ^-[0-9]+$ ]]
   then
      dir="$(_dirs-history-fetch "${dir:1}")"
      is "${dir}" || {
         error 'No dir with such number in history'
         return 1
      }
      option=''
   else
      dir="${2:-"~"}"
   fi
   local tildeExpandedDir="${dir/\~/$HOME}"
   \cd ${option} "${tildeExpandedDir}" || return $?
   _dirs-history-add-pwd
   return 0
}
export -f chdir


complete -o nospace -F histdir-tab-completion cd
function histdir-tab-completion() {
   local cword=${#COMP_WORDS[@]}
   local arg=${COMP_WORDS[1]}
   if (( COMP_CWORD == 1 )) && (( cword == 2 )) && [[ "${arg}" =~ ^- ]]
   then
      COMPREPLY=( '-NR[<tab>]' '-REGEX<tab>' )
      if is-num "${arg:1}"
      then
         local pattern="^\s*${arg:1}\s*\s"
         COMPREPLY=( "$(chdir -- | sed -n "/${pattern}/ {s/${pattern}//; p}")" )
      else
         local lines=$(chdir -- | grep "${arg:1}" | wc -l)
         if [ "${lines}" = "1" ]
         then
            COMPREPLY=( "$(chdir -- | grep "${arg:1}" | sed "s/^\s*\w*\s*//")" )
         else
            chdir -- | g "${arg:1}" | while read line
            do
               echo -ne "\n${line}"
            done
         fi
      fi
   else
      _cd
   fi
}
