#!/bin/bash

# Prints fragment of the file between lines "#begin [region-name]" and "#end [region-name]"
# 1st parameter is [region-name], 2nd parameter is file name
function get-region() {
   local regionName="${1:?Missing region name}"
   local fileName="${2:?Missing input file name}"

   local beginTag="#begin $regionName"
   local endTag="#end $regionName"

   sed -n -e "/$beginTag/,/$endTag/ {/$beginTag/ d; /$endTag/ d; p}" <"$fileName"
}

# Prints file content appended with STDIN surrounded with lines "#begin [region-name]" and "#end [region-name]"
# 1st parameter is [region-name], 2nd parameter is file name
function set-region() {
   local regionName="${1:?Missing region name}"
   local fileName="${2:?Missing input file name}"

   local beginTag="#begin $regionName"
   local endTag="#end $regionName"

   sed -e "/$beginTag/,/$endTag/ d" <"$fileName"
   echo "$beginTag"
   cat <&0
   echo "$endTag"
}

# Prints file content without lines "#begin [region-name]" and "#end [region-name]" and content between them
# 1st parameter is [region-name], 2nd parameter is file name
function delete-region() {
   local regionName="${1:?Missing region name}"
   local fileName="${2:?Missing input file name}"

   local beginTag="#begin $regionName"
   local endTag="#end $regionName"

   sed -e "/$beginTag/,/$endTag/ d" <"$fileName"
}

# Replaces occurrences of $var placeholders with their values in the file provided as a first argument, called template. The result file is returned on STDOUT.
# If 2nd argument is provided, a file with this path is executed as a bash script and variable assignments in this file will be used for the template.
# The assignment should be in the form: var=val.
# If no 2nd argument, values will be taken from shell variables.
function render-template() {
   local templateFile="$1"
   local varDefsFile="$2"

   -nf "$templateFile" && err "Missing template file: $templateFile"

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
         while -rhas "$line" '\$\{([a-zA-Z_][a-zA-Z0-9_]*)\}'
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
