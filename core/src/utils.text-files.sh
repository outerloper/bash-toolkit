#!/bin/bash


function echo-region() {
   local regionName="${1:?Missing region name}"
   local fileName="${2:?Missing input file name}"

   local beginTag="#begin ${regionName}"
   local endTag="#end ${regionName}"

   sed -n -e "/${beginTag}/,/${endTag}/ {/${beginTag}/ d; /${endTag}/ d; p}" <"${fileName}"
}
export -f echo-region

function delete-region() {
   local regionName="${1:?Missing region name}"
   local fileName="${2:?Missing input file name}"

   local beginTag="#begin ${regionName}"
   local endTag="#end ${regionName}"

   sed -e "/${beginTag}/,/${endTag}/ d" <"${fileName}"
}
export -f delete-region

function set-region() {
   local regionName="${1:?Missing region name}"
   local fileName="${2:?Missing input file name}"

   local beginTag="#begin ${regionName}"
   local endTag="#end ${regionName}"

   tmp="$(mktemp)"
   sed -e "/${beginTag}/,/${endTag}/ d" <"${fileName}" > "${tmp}"
   cat "${tmp}"
   echo "${beginTag}"
   cat <&0
   echo "${endTag}"
   rm "${tmp}"
}
export -f set-region

function render-template() {
   local varDefsFile="$(mktemp)"
   declare -A vars
   cat <&0 >"${varDefsFile}"
   local varDecl="^\([a-Z_][a-Z0-9_]*\)=.*"
   (
      source "${varDefsFile}"
      for var in $(sed -n -e "/${varDecl}/ {s/${varDecl}/\1/; p}" < "${varDefsFile}")
      do
         vars[$var]="${!var}"
      done
      while read -r line
      do
         while [[ "${line}" =~ \$\{([a-Z_][a-Z0-9_]*)\} ]]
         do
            placeholder=${BASH_REMATCH[0]}
            value=${vars[${BASH_REMATCH[1]}]}
            line=${line//${placeholder}/${value}}
         done
         echo "${line}"
      done <"${1}"
   )
   rm "${varDefsFile}"
}
export -f render-template
