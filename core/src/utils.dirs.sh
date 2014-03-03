#!/bin/bash


function is-dir-empty() {
   local dir="${1:-.}"
   [ "${dir}" = "$(find "${dir}")" ]
}
export -f is-dir-empty


DIRHISTFILE=${HOME}/.dir_history
DIRHISTSIZE=40

function _dirs-ensure-history-exists() {
   if ! [ -f "${DIRHISTFILE}" ]
   then
      _dirs-init-empty-history #TODO test when missing file, cd - returns no completion results (with no empty line)
   fi
}

function _dirs-history-print() {
   _dirs-ensure-history-exists
   nl -w 5 "${DIRHISTFILE}"
}

function _dirs-init-empty-history() {
   echo -n > "${DIRHISTFILE}"
}

function _dirs-history-fetch() {
   _dirs-ensure-history-exists
   local nr=${1:-'$'}
   sed -n "${nr} p" < "${DIRHISTFILE}"
}

function _dirs-history-add-pwd() {
   _dirs-ensure-history-exists
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
      _dirs-init-empty-history
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
      COMPREPLY=( '-NR[<tab>]' '-REGEX<tab>' '--REGEX<tab>' )
      if is-num "${arg:1}"
      then
         local pattern="^\s*${arg:1}\s*\s"
         COMPREPLY=( "$(chdir -- | sed -n "/${pattern}/ {s/${pattern}//; p}")" )
      else
         local phrase
         local completeIfOne
         if [ "${arg:1:1}" = "-" ]
         then
            phrase="${arg:2}"
         else
            phrase="${arg:1}"
            completeIfOne=1 # TODO test this
         fi
         local lines=$(chdir -- | grep "${phrase}" | wc -l)
         if [ "${lines}" = "1" ] && [ "${completeIfOne}" ]
         then
            COMPREPLY=( "$(chdir -- | grep "${phrase}" | sed "s/^\s*\w*\s*//")" )
         else
            for line in "$(chdir -- | g -i "${phrase}")"
            do
               echo -ne "\n${line}"
            done
         fi
      fi
   else
      _cd
   fi
}
