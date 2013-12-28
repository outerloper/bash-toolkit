#!/bin/bash

function readNotEmptyVar() {
   local var=${1:?'Missed variable name.'}
   local value
   local desc="${2:-$1}"
   local default=$3

   prompt="Provide ${desc}${default:+" (default is $default)"}: "
   while [[ -z "${value}" ]]
   do
      read -p "${prompt}" value
      if [[ -z "${value}" ]] && [[ -n "${default}" ]]
      then
         value="${default}"
      fi
   done
   printf -v ${var} -- "${value}"
}

function injectVars() {
   local varsFile=$1
   local tmpFile=tmp

   local varDecl="^\([a-Z_][a-Z0-9_]*\)=.*"
   source $(readlink -f "${varsFile}")
   cat <&0 > ${tmpFile}

   for var in $(sed -n -e "/${varDecl}/ p" < "${varsFile}" | sed -e "s/${varDecl}/\1/")
   do
      local escapedValue=$(echo ${!var} | sed -e 's/[\\&\/]/\\&/g')
      sed -e "s/\${${var}}/${escapedValue}/g" -e "s/\$${var}/${escapedValue}/g" < "${tmpFile}" > "${tmpFile}.tmp"
      mv "${tmpFile}.tmp" "${tmpFile}"
   done
   cat "${tmpFile}" >&1
   rm "${tmpFile}"
}
