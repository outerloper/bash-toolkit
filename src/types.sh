#!/bin/bash

bt-require utils.sh


$BT_GLOBAL_ASSOC TYPE_ARRAY
$BT_GLOBAL_ASSOC TYPE_ASK

TYPE_CURRENT=
TYPE_TABLE=
TYPE_ERROR=

RESULT=

# Get property $1 of current type. Type is determined by vars TYPE_TABLE and TYPE_CURRENT
type-get() { # rename _getCurrent
   RESULT=
   local property=${1:?"Missed property."}
   shift
   local returnRef=${1:-$property}
   -n "$@" && shift

   local resultRef="$TYPE_TABLE[$TYPE_CURRENT.$property]"
   local result="${!resultRef}"

   if -n "$result"
   then
      local fun=${result%%()}
      if ! -eq "$fun" "$result"
      then
         "$fun"
         result="$RESULT"
      fi
   else
      result="$1"
   fi

   eval "$returnRef="
   var-set "$returnRef" "$result"
}

type-def() {
   -eq "$1" '--help' &&
   echo -ne "Usage: $FUNCNAME TYPE_NAME BASE_TYPE OPTIONS...
Defines value type which can be used in ask-for command.
  TYPE_NAME           Name of defined type
  BASE_TYPE           Name of type from which settings will be derived

Options:
  --verify FUN        Name of a function verifying correctness of type definition. If not correct, error message should be assigned to variable RESULT.
  --desc DESC         Text to display in user prompt. Can be a function - 'funName()' then assign help text to RESULT var.
  --help HELP         Additional text to display in user prompt in parentheses. Can be a function - 'funName()' then assign help text to RESULT var.
  --validate FUN      Name of validation function which takes user input as argument. See 'Validation functions' below for more information.
  --pattern REGEXP    A value should match the regexp provided to be accepted.
  --process FUN       Name of a function executed if validation has been successful. Takes user input as argument. RESULT var value from this function will
                      be taken instead of raw user input.
  --maskInput YES_NO  If value is true/yes/1, user input won't be printed to screen.
  --optional YES_NO   If value is true/yes/1, empty input is acceptable.
  --default YES_NO    This value to use when --optional is set and user input is empty. Can be a function - 'funName()' then assign help text to RESULT var.
  --reuse YES_NO      If value is true/yes/1, previous variable value is the initial text and after providing invalid value, it is reused in next prompt.
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
  To raise validation error inside validation function, invoke 'validationMessage' function. Usage: validationMessage MSG_KEY DEFAULT_MSG [VALUES]
    MSG_KEY    Can be used in type-def/ask-for as option --<msg-key> with the value being message template which may contain printf % placeholders
    DEFAULT    Default message template which will be used when no --<msg-key> defined.
    VALUES     Values for printf % placeholders
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
      local typeSet=TYPE_ARRAY type=${typeSpec[0]}
   fi
   shift

   local base=$1
   if -z $base || matches $base '--*'
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
         var-set "$typeSet["$key"]" "$value"
         ;;
      *)
         echo "Unexpected: $1" >&2
         return
         ;;
      esac
   done

   if -n "$base"
   then
      for baseKey in ${!TYPE_ARRAY[@]}
      do
         option="${baseKey#"$base."}"
         if ! -eq "$baseKey" "$option"
         then
            key="$type.$option"
            local typeKeyRef="$typeSet[$key]"
            -n "${!typeKeyRef}" || var-set "$typeKeyRef" "${TYPE_ARRAY["$baseKey"]}"
         fi
      done
   fi
}


verifyEnum() {
   RESULT=
   local values
   type-get values
   -n "${values// /}" || RESULT="Enum values are undefined!"
}

verifyPath() {
   RESULT=
   local pathType
   type-get pathType
   -n "$pathType" || RESULT="Path type is undefined!"
}


helpEnum() {
   RESULT=
   local values
   type-get values
   RESULT="one of: $values"
}

helpInt() {
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


validationMessage() {
   local messageKey=${1:?Missed validation message key.}
   shift
   local defaultMessage="${1:?Missed default validation message.}"
   shift

   local message

   type-get $messageKey message
   printf "${message:-"$defaultMessage"}" "$@"
}


validateEnum() {
   local value="${1:?Missing value}"

   local values

   type-get values
   grep " $value " <<<" $values " >/dev/null
   if (( $? != 0 ))
   then
      validationMessage invalidEnumMessage "Value must be one of: %s" "$values"
   fi
}

validatePattern() {
   local value="${1:?Missing value}"

   local pattern

   type-get pattern
   -n "$pattern" || return
   matches-regex "$value" "$pattern" || validationMessage doesNotMatchPatternMessage "Value must match the pattern '%s'" "$pattern"
}

validateInt() {
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

validatePath() {
   local value="${1:?Missing value}"

   local root pathType realPath

   type-get root
   type-get pathType
   var-remove-trailing-slash root

   contains-regex "$value" '/*' || value="$root/$value"
   realPath=$(realpath -m "$value")

   if -n "$value"
   then
      case "$pathType" in
      dir|empty-dir)
         var-remove-trailing-slash realPath
         if ! -d "$value"
         then
            validationMessage dirDoesNotExistMessage "Directory '%s' does not exist" "$value"
            return
         fi
         if -eq empty-dir "$pathType" && ! -E "$value"
         then
            validationMessage dirNotEmptyMessage "Directory '%s' is not empty" "$value"
            return
         fi
      ;;
      file)
         if ! -f "$realPath"
         then
            validationMessage fileDoesNotExistMessage "File '%s' does not exist" "$realPath"
            return
         fi
      ;;
      new)
         local parent=$(dirname "$realPath")
         if ! -d "$parent"
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
         err "Unsupported file type: '$pathType'"
      ;;
      esac
   fi

   contains-regex "$realPath" "^$root" || validationMessage pathOutOfRoot "The path should exist in $root but '$value' does not" "$value"
}


processPath() {
    RESULT=
    local value="${1:?Missing value}"

    local root pathType

    type-get root
    type-get pathType
    var-remove-trailing-slash root

    contains-regex "$value" '/*' || value="$root/$value"

    RESULT="$(readlink -f "$value")"
    case "$pathType" in
    dir|empty-dir)
        var-remove-trailing-slash RESULT
    ;;
    esac
}

ask-for() {
   -eq "$1" '--help' &&
   echo -ne "Usage: $FUNCNAME TYPE VAR OPTIONS...
Asks user to provide a value of TYPE and assigns it to VAR. When input from STDIN, validation errors are stored in TYPE_ERROR var.
Parameters:
  TYPE      Value type, defined by type-def. May not exist.
  VAR_NAME  User value will be assigned to the variable with this name. If not specified, <type> will be used as a variable name.
  OPTIONS   See 'options' parameter of type-def command.
Examples:
  $FUNCNAME n
  $FUNCNAME int n
  $FUNCNAME int n --min 0 --max 10
" && return

   local type=${1:?'Missed type name.'}
   shift
   local name=$1
   if -z "$name" || matches $name '--*'
   then
      name=$type
   else
      shift
   fi

   TYPE_ERROR=
   TYPE_ASK=()
   type-def TYPE_ASK.$name $type "$@"

   local verify desc help reuse maskInput silent suggest default optional validate process batch prompt value

   TYPE_TABLE=TYPE_ASK
   TYPE_CURRENT=$name
   type-get verify
   if -n "$verify"
   then
      $verify
      if -n "$RESULT"
      then
         err "$RESULT"
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
   ! -t 0
   batch=$?

   : ${optional:=no}

   is "$reuse" && suggest="${!name}"
   prompt="${desc:-"Provide $name"}${help:+" ($help)"}${default:+". Default is '$default'"}$PS2"
   while -z "$value"
   do
      is $maskInput && silent="-s"
      read $silent -e -p "$prompt" -i "$suggest" value
      is "$reuse" && suggest="$value"
      -n $silent && ! -0 $batch && echo
      if -n "$value" && -n "$validate"
      then
         local validationMessage="$($validate "$value")"
         if -n "$validationMessage"
         then
            prompt="$validationMessage."
            value=''
            if -0 "$batch"
            then
                eval "$name="
                TYPE_ERROR="$prompt"
                echo "$prompt"
                return 1
            else
                prompt+=" Try again$PS2"
                continue
            fi
         fi
      fi
      if -z "$value"
      then
         if ! is "$optional"
         then
            prompt="Non empty value is required."
            if -0 "$batch"
            then
                eval "$name="
                TYPE_ERROR="$prompt"
                echo "$prompt"
                return 1
            else
                prompt+=" Try again$PS2"
            fi
         elif -n "$default"
         then
            value="$default"
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
   var-set $name "$value"
}

type-print() {
    array-print TYPE_ARRAY | grep "^$1"
}



TYPE_ARRAY=(
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
