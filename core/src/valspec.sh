#!/bin/bash
# TODO test this
# Get property $1 of current type. Type is determined by vars VALSPEC_CURRENT and TYPE_CURRENT
function type-get() {
   RESULT=
   local property=${1:?"Missed property."}
   shift
   local returnRef=${1:-$property}
   shift

   local resultRef="$VALSPEC_CURRENT[$TYPE_CURRENT.$property]}"
   local result="${!resultRef}"

   if -n "$result"
   then
      local fun=${result%%()}
      if -neq "$fun" "$result"
      then
         "$fun"
         result="$RESULT"
      fi
   else
      result="$1"
   fi

   eval "$returnRef="
   set-var $returnRef "$result"
}

function type-def() {
   local typeSpec=${1:?"Missed type."}
   typeSpec=( ${typeSpec/./ } )
   if -n "${typeSpec[1]}"
   then
      local typeSet=${typeSpec[0]} type=${typeSpec[1]}
   else
      local typeSet=TYPESPEC type=${typeSpec[0]}
   fi
   shift

   local base=$1
   if -z $base || -m $base '--.*'
   then
      base=
   else
      shift
   fi

   local key option value baseKey

   while -n "$1"
   do
      case $1 in
      --*)
         option=$1
         shift
         key="$type.${option#--}"
         value="${1:?"Missed '$option' option value"}"
         shift
         set-var "$typeSet["$key"]" "$value"
         ;;
      *)
         echo "Unexpected: $1" >&2
         return
         ;;
      esac
   done

   if -n "$base"
   then
      for baseKey in ${!TYPESPEC[@]}
      do
         option="${baseKey#"$base."}"
         if -neq "$baseKey" "$option"
         then
            key="$type.$option"
            local typeKeyRef="$typeSet[$key]"
            -n "${!typeKeyRef}" || set-var "$typeKeyRef" "${TYPESPEC["$baseKey"]}"
         fi
      done
   fi
}


function verifyEnum() {
   RESULT=
   local values
   type-get values
   -n "${values// /}" || RESULT="Enum values are undefined!"
}

function verifyPath() {
   RESULT=
   local pathType
   type-get pathType
   -n "$pathType" || RESULT="Path type is undefined!"
}


function helpEnum() {
   RESULT=
   local values
   type-get values
   RESULT="one of: $values"
}

function helpInt() {
   RESULT=
   local min max
   type-get min
   type-get max
   if -n "$min"
   then
      if -n "$max"
      then
         RESULT="$min-$max"
      else
         RESULT="min: $min"
      fi
   elif -n "$max"
   then
      RESULT="max: $max"
   else
      RESULT="number"
   fi
}


function validationMessage() {
   local messageKey=${1:?Missed validation message key.}
   shift
   local defaultMessage="${1:?Missed default validation message.}"
   shift

   local message

   type-get $messageKey message
   printf "${message:-"$defaultMessage"}" "$@"
}


function validateEnum() {
   local value="${1:?Missing value}"

   local values

   type-get values
   grep " $value " <<<" $values " >/dev/null
   if (( $? != 0 ))
   then
      validationMessage invalidEnumMessage "Value must be one of: %s" "$values"
   fi
}

function validatePattern() {
   local value="${1:?Missing value}"

   local pattern

   type-get pattern
   -n "$pattern" || return

   egrep "^$pattern$" <<<"$value" >/dev/null
   if (( $? != 0 ))
   then
      validationMessage doesNotMatchPatternMessage "Value must match the pattern '%s'" "$pattern"
   fi
}

function validateInt() {
   local value="${1:?Missing value}"

   local min max

   message=$(validatePattern "$value")
   if -n "$message"
   then
      echo "$message"
      return
   fi

   type-get min
   if -n "$min" && (( value < min ))
   then
      validationMessage lessThanMinMessage "Value must not be less than %s" "$min"
      return
   fi

   type-get max
   if -n "$max" && (( value > max ))
   then
      validationMessage greaterThanMaxMessage message "Value must not be greater than %s" "$max"
      return
   fi
}

function validatePath() {
   local value="${1:?Missing value}"

   local root pathType realPath

   type-get root
   type-get pathType
   trail-slash root

   -m "$value" '/*' || value="$root""$value"
   realPath=$(realpath -m "$value")

   if -n "$value"
   then
      case "$pathType" in
      dir|empty-dir)
         trail-slash realPath
         if -nd "$value"
         then
            validationMessage dirDoesNotExistMessage "Directory '%s' does not exist" "$value"
            return
         fi
         if -eq empty-dir "$pathType" && -ned "$(readlink -f "$value")"
         then
            validationMessage dirNotEmptyMessage "Directory '%s' is not empty" "$value"
            return
         fi
      ;;
      file)
         if -nf "$realPath"
         then
            validationMessage fileDoesNotExistMessage "File '%s' does not exist" "$realPath"
            return
         fi
      ;;
      new)
         local parent=$(dirname "$realPath")
         if -nd "$parent"
         then
            validationMessage dirDoesNotExistMessage "Directory '%s' does not exist" "$parent"
            return
         fi
         if -e "$realPath"
         then
            validationMessage dirExistsMessage "'%s' already exists" "$realPath"
            return
         fi
      ;;
      *)
         stderr "Unsupported file type: '$pathType'"
      ;;
      esac
   fi

   -m "$realPath" "^$root" || validationMessage pathOutOfRoot "The path should exist in $root but '$value' does not" "$value"
}


function processPath() {
    RESULT=
    local value="${1:?Missing value}"

    local root pathType

    type-get root
    type-get pathType
    trail-slash root

    -m "$value" '/*' || value="$root""$value"

    RESULT="$(readlink -f "$value")"
    case "$pathType" in
    dir|empty-dir)
        trail-slash RESULT
    ;;
    esac
}

# $1 - type, $2 - var name
function ask-for() {
   local type=${1:?'Missed type name.'}
   shift
   local name=$1
   if -z "$name" || -m $name '--.*'
   then
      name=$type
   else
      shift
   fi

   VALSPEC_ASK=()
   type-def VALSPEC_ASK.$name $type "$@"

   local verify desc help reuse maskInput silent default required validate process prompt value

   VALSPEC_CURRENT=VALSPEC_ASK
   TYPE_CURRENT=$name
   type-get verify verify
   if -n "$verify"
   then
      $verify
      if -n "$RESULT"
      then
         stderr "$RESULT"
         return 1
      fi
   fi
   type-get desc
   type-get help
   type-get reuse
   type-get maskInput
   type-get default
   type-get required
   type-get validate
   type-get process

   : ${required:=1}

   prompt="${desc:-"Provide $name"}${help:+" ($help)"}${default:+". Default is '$default'"}$PS2"
   while -z "$value"
   do
      -true $maskInput && silent="-s"
      read $silent -e -p "$prompt" -i "$suggest" value
      -n $silent && echo
      if -n "$value" && -n "$validate"
      then
         local validationMessage="$($validate "$value")"
         if -n "$validationMessage"
         then
            prompt="$validationMessage. Try again$PS2"
            suggest=''
            -true "$reuse" && suggest="$value"
            value=''
            continue
         fi
      fi
      if -z "$value"
      then
         if -true "$required"
         then
            prompt="Non empty value is required. Try again$PS2"
         elif -n "$default"
         then
            value="$default" "$value"
         else
            eval "$name="
            return
         fi
      fi
   done
   if -n "$process" && -n "$value"
   then
      $process "$value"
      value="$RESULT"
   fi
   printf -v $name -- "$value"
}


TYPESPEC=( # @global-assoc
   [list]='val enum int path'

   [val.validate]='validatePattern'

   [enum.verify]='verifyEnum'
   [enum.help]='helpEnum()'
   [enum.validate]='validateEnum'

   [int.help]='helpInt()'
   [int.validate]='validateInt'
   [int.pattern]='-?[0-9]+'
   [int.doesNotMatchPatternMessage]='Invalid number format'

   [path.verify]='verifyPath'
   [path.validate]='validatePath'
   [path.process]='processPath'

   [password.maskInput]='yes'
)
TYPE_CURRENT=
VALSPEC_CURRENT=
RESULT=

type-def bool enum --values "y n" --help "y/n" --invalidEnumMessage "Please type 'y' or 'n'"
type-def dir path --pathType dir
type-def file path --pathType file

VALSPEC_ASK=() # @global-assoc     TODO required?