#!/bin/bash


function is-dir-empty() {
   local dir="${1:-.}"
   [ "${dir}" = "$(find "${dir}")" ]
}
export -f is-dir-empty


DIRHISTFILE=${HOME}/.dirstack
DIRHISTSIZE=20

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



complete -F f o
function f() {
   COMPREPLY=( dddddddddddddddd )

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
