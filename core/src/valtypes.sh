#!/bin/bash

require utils.sh

${BUSH_ASSOC} VALUE_TYPES
${BUSH_ASSOC} VALUE_ASK

TYPE_CURRENT=
TYPE_TABLE=
RESULT=

# Get property $1 of current type. Type is determined by vars TYPE_TABLE and TYPE_CURRENT
function type-get() { # rename _getCurrent
   RESULT=
   local property=${1:?"Missed property."}
   shift
   local returnRef=${1:-$property}
   shift

   local resultRef="$TYPE_TABLE[$TYPE_CURRENT.$property]}"
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
   -eq "$1" '--help' &&
   echo -ne "Defines value type which can be used in ask-for command.

Usage:
  $FUNCNAME <type> <base-type> [options...]

Parameters:
  <type>        Name of defined type
  <base-type>   Name of type from which settings will be derived
  options       In the form of: --option1 value1 --option2 --value2
    --verify        Name of a function verifying correctness of type definition. If not correct, error message should be assigned to variable RESULT.
    --desc          Text to display in user prompt. Can be a function - 'funName()' then assign help text to RESULT var.
    --help          Additional text to display in user prompt in parentheses. Can be a function - 'funName()' then assign help text to RESULT var.
    --validate      Name of validation function which takes user input as argument. See 'Validation functions' below for more information.
    --pattern       A value should match the regexp provided to be accepted.
    --process       Name of a function executed if validation has been successful. Takes user input as argument. RESULT var value from this function will
                    be taken instead of raw user input.
    --maskInput     If value is true/yes/1, user input won't be printed to screen.
    --optional      If value is true/yes/1, empty input is acceptable.
    --default       This value to use when --optional is set and user input is empty. Can be a function - 'funName()' then assign help text to RESULT var.
    --reuse         If value is true/yes/1, previous variable value is the initial text and after providing invalid value, it is reused in next prompt.
    Custom options:
      Any other option names are allowed as their values can be used in Custom functions described below to implement types behaviour and constraints.

Custom functions:
  If function is accepted as option value, the following rules apply in most cases:
  * If string result is expected from function, do not echo it but assign to RESULT global variable.
  * There is access to type definition by options from Custom functions. There is a statement: 'type-get <option> <var>' which assigns value of --<option>
    to <var>. If <var> is not specified, <option> is used as a variable name. E.g. 'type-get desc' assigns value of type's --desc to \$desc.
    If --desc value means a function which sets RESULT var, its value will be assigned to \$desc variable. It is recommended to declare such
    variables as local in custom functions.

Validation functions:
  To raise validation error inside --validator function, invoke 'validationMessage' function.
  Usage:
    validationMessage <msg-key> <default-msg> [<values>]
  Parameters:
    <msg-key>       Can be used in type-def/ask-for as option --<msg-key> with the value being message template which may contain printf % placeholders
    <default-msg>   Default message template which will be used when no --<msg-key> defined.
    <values>        Values for printf % placeholders
  Example:
    local min; type-get min
    validationMessage lessThanMinMessage 'Value must not be less than %s' '\$min'

Pre-defined type examples with parent types and example options:
  * enum, --values <string with space-separated values> --invalidEnumMessage
  * bool : enum, --invalidEnumMessage
  * int, --min --max --doesNotMatchPatternMessage --lessThanMinMessage --greaterThanMaxMessage
  * path, --pathType <dir|empty-dir|file|new> --root --dirNotEmpty --dirDoesNotExistMessage --pathOutOfRoot --dirExistsMessage --fileDoesNotExistMessage
  * dir : path --pathType dir
  * file : path --pathType file

Examples:
  type-def dir path --pathType dir
  type-def bool enum --values 'y n' --help 'y/n' --invalidEnumMessage 'Please type y or n'
" && return

   local typeSpec=${1:?"Missed type."}
   typeSpec=( ${typeSpec/./ } )
   if -n "${typeSpec[1]}"
   then
      local typeSet=${typeSpec[0]} type=${typeSpec[1]}
   else
      local typeSet=VALUE_TYPES type=${typeSpec[0]}
   fi
   shift

   local base=$1
   if -z $base || -like $base '--*'
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
      for baseKey in ${!VALUE_TYPES[@]}
      do
         option="${baseKey#"$base."}"
         if -neq "$baseKey" "$option"
         then
            key="$type.$option"
            local typeKeyRef="$typeSet[$key]"
            -n "${!typeKeyRef}" || set-var "$typeKeyRef" "${VALUE_TYPES["$baseKey"]}"
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
   -rlike "$value" "$pattern" || validationMessage doesNotMatchPatternMessage "Value must match the pattern '%s'" "$pattern"
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
      validationMessage greaterThanMaxMessage "Value must not be greater than %s" "$max"
      return
   fi
}

function validatePath() {
   local value="${1:?Missing value}"

   local root pathType realPath

   type-get root
   type-get pathType
   trail-slash root

   -rhas "$value" '/*' || value="$root""$value"
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

   -rhas "$realPath" "^$root" || validationMessage pathOutOfRoot "The path should exist in $root but '$value' does not" "$value"
}


function processPath() {
    RESULT=
    local value="${1:?Missing value}"

    local root pathType

    type-get root
    type-get pathType
    trail-slash root

    -rhas "$value" '/*' || value="$root""$value"

    RESULT="$(readlink -f "$value")"
    case "$pathType" in
    dir|empty-dir)
        trail-slash RESULT
    ;;
    esac
}

function ask-for() {
   -eq "$1" '--help' &&
   echo -ne "Asks user to provide a value of specified type.
Usage:
  $FUNCNAME <type> [<var-name>] [options...]
Parameters:
  <type>      Value type, defined by type-def. May not exist.
  <var-name>  User value will be assigned to the variable with this name. If not specified, <type> will be used as a variable name.
  options     See 'options' parameter of type-def command.
Examples:
  $FUNCNAME n
  $FUNCNAME int n
  $FUNCNAME int n --min 0 --max 10
" && return

   local type=${1:?'Missed type name.'}
   shift
   local name=$1
   if -z "$name" || -like $name '--*'
   then
      name=$type
   else
      shift
   fi

   VALUE_ASK=()
   type-def VALUE_ASK.$name $type "$@"

   local verify desc help reuse maskInput silent suggest default optional validate process prompt value

   TYPE_TABLE=VALUE_ASK
   TYPE_CURRENT=$name
   type-get verify
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
   type-get optional
   type-get validate
   type-get process

   : ${optional:=no}

   -true "$reuse" && suggest="${!name}"
   prompt="${desc:-"Provide $name"}${help:+" ($help)"}${default:+". Default is '$default'"}$PS2"
   while -z "$value"
   do
      -true $maskInput && silent="-s"
      read $silent -e -p "$prompt" -i "$suggest" value
      -true "$reuse" && suggest="$value"
      -n $silent && echo
      if -n "$value" && -n "$validate"
      then
         local validationMessage="$($validate "$value")"
         if -n "$validationMessage"
         then
            prompt="$validationMessage. Try again$PS2"
            value=''
            continue
         fi
      fi
      if -z "$value"
      then
         if -false "$optional"
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
   set-var $name "$value"
}

function type-print() {
    print-array VALUE_TYPES | grep "^$1"
}

VALUE_TYPES=(
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

type-def bool enum --values "y n" --help "y/n" --invalidEnumMessage "Please type 'y' or 'n'"
type-def dir path --pathType dir
type-def file path --pathType file

# TODO argspec for type-def, rename

