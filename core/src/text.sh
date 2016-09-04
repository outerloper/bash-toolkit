#!/bin/bash

# Prints fragment of the file between lines "#begin [region-name]" and "#end [region-name]"
# 1st parameter is [region-name], 2nd parameter is file name
function echo-region() {
   local regionName="${1:?Missing region name}"
   local fileName="${2:?Missing input file name}"

   local beginTag="#begin $regionName"
   local endTag="#end $regionName"

   sed -n -e "/$beginTag/,/$endTag/ {/$beginTag/ d; /$endTag/ d; p}" <"$fileName"
}
export -f echo-region

# Deletes from the file its fragment between lines "#begin [region-name]" and "#end [region-name]"
# 1st parameter is [region-name], 2nd parameter is file name
function delete-region() {
   local regionName="${1:?Missing region name}"
   local fileName="${2:?Missing input file name}"

   local beginTag="#begin $regionName"
   local endTag="#end $regionName"

   sed -e "/$beginTag/,/$endTag/ d" <"$fileName"
}
export -f delete-region

# Appends to the file content from STDIN surrounded with lines "#begin [region-name]" and "#end [region-name]"
# 1st parameter is [region-name], 2nd parameter is file name
function set-region() {
   local regionName="${1:?Missing region name}"
   local fileName="${2:?Missing input file name}"

   local beginTag="#begin $regionName"
   local endTag="#end $regionName"

   tmp="$(mktemp)"
   sed -e "/$beginTag/,/$endTag/ d" <"$fileName" >"$tmp"
   cat "$tmp"
   echo "$beginTag"
   cat <&0
   echo "$endTag"
   rm "$tmp"
}
export -f set-region

# Replaces occurrences of $var placeholders with their values in the file provided as a first argument, called template. The result file is returned on STDOUT.
# If 2nd argument is provided, a file with this path is executed as a bash script and variable assignments in this file will be used for the template.
# The assignment should be in the form: var=val.
# If no 2nd argument, values will be taken from shell variables.
function render-template() {
   local templateFile="$1"
   local varDefsFile="$2"

   -nf "$templateFile" && stderr "Missing template file: $templateFile"

   local varDecl="^ *\([a-zA-Z_][a-zA-Z0-9_]*\)=.*"
   (
      declare -A vars

      if -n "$varDefsFile"
      then
          source "$varDefsFile"
          for var in $(sed -n -e "/$varDecl/ {s/$varDecl/\1/; p}" < "$varDefsFile")
          do
             vars["$var"]="${!var}"
          done
      fi
      declare neof=0
      while -eq $neof 0
      do
         read -r line
         neof=$?
         while -m "$line" '\$\{([a-zA-Z_][a-zA-Z0-9_]*)\}'
         do
            placeholder="${BASH_REMATCH[0]}"
            var="${BASH_REMATCH[1]}"
            if -n "$varDefsFile"
            then
                value="${vars[$var]}"
            else
                value="${!var}"
            fi
            line="${line//$placeholder/$value}"
         done
         echo "$line"
      done <"$templateFile"
   )
}
export -f render-template
