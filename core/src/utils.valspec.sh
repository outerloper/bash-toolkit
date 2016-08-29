#!/bin/bash
# TODO test this
# Get property $1 of current type. Type is determined by vars VALSPEC_CURRENT and TYPE_CURRENT
function type-get() {
   RESULT=
   local property=${1:?"Missed property."}
   shift
   local returnRef=${1:-${property}}
   shift

   local resultRef="${VALSPEC_CURRENT}[${TYPE_CURRENT}.${property}]}"
   local result="${!resultRef}"

   if [[ "${result}" ]]
   then
      local fun=${result%%()}
      if [[ "${fun}" != "${result}" ]]
      then
         "${fun}"
         result="${RESULT}"
      fi
   else
      result="$1"
   fi

   eval "${returnRef}="
   printf -v ${returnRef} -- "${result}"
}

function type-def() {
   local typeSpec=${1:?"Missed type."}
   typeSpec=( ${typeSpec/./ } )
   if [[ "${typeSpec[1]}" ]]
   then
      local typeSet=${typeSpec[0]} type=${typeSpec[1]}
   else
      local typeSet=TYPESPEC type=${typeSpec[0]}
   fi
   shift

   local base=${1}
   if [ -z ${base} ] || [[ ${base} =~ --.* ]]
   then
      base=
   else
      shift
   fi

   local key option value baseKey

   while [[ "$1" ]]
   do
      case $1 in
      --*)
         option=$1
         shift
         key="${type}.${option#--}"
         value="${1:?"Missed '${option}' option value"}"
         shift
         printf -v "${typeSet}["${key}"]" -- "${value}"
         ;;
      *)
         echo "Unexpected: $1" >&2
         return
         ;;
      esac
   done

   if [[ "${base}" ]]
   then
      for baseKey in ${!TYPESPEC[@]}
      do
         option="${baseKey#"${base}."}"
         if [[ "${baseKey}" != "${option}" ]]
         then
            key="${type}.${option}"
            local typeKeyRef="${typeSet}[${key}]"
            [[ "${!typeKeyRef}" ]] || printf -v "${typeKeyRef}" -- "${TYPESPEC["${baseKey}"]}"
         fi
      done
   fi
}


function verifyEnum() {
   RESULT=
   local values
   type-get values
   [[ "${values// /}" ]] || RESULT="Enum values are undefined!"
}

function verifyPath() {
   RESULT=
   local pathType
   type-get pathType
   [[ "${pathType}" ]] || RESULT="Path type is undefined!"
}


function helpEnum() {
   RESULT=
   local values
   type-get values
   RESULT="one of: ${values}"
}

function helpInt() {
   RESULT=
   local min max
   type-get min
   type-get max
   if [[ "${min}" ]]
   then
      if [[ "${max}" ]]
      then
         RESULT="${min}-${max}"
      else
         RESULT="min: ${min}"
      fi
   elif [[ "${max}" ]]
   then
      RESULT="max: ${max}"
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

   type-get ${messageKey} message
   printf "${message:-"${defaultMessage}"}" "$@"
}


function validateEnum() {
   local value="${1:?Missing value}"

   local values

   type-get values
   grep " ${value} " <<<" ${values} " >/dev/null
   if (( $? != 0 ))
   then
      validationMessage invalidEnumMessage "Value must be one of: %s" "${values}"
   fi
}

function validatePattern() {
   local value="${1:?Missing value}"

   local pattern

   type-get pattern
   [[ "${pattern}" ]] || return

   egrep "^${pattern}$" <<<"${value}" >/dev/null
   if (( $? != 0 ))
   then
      validationMessage doesNotMatchPatternMessage "Value must match the pattern '%s'" "${pattern}"
   fi
}

function validateInt() {
   local value="${1:?Missing value}"

   local min max

   message=$(validatePattern "${value}")
   if [[ "${message}" ]]
   then
      echo "${message}"
      return
   fi

   type-get min
   if [[ "${min}" ]] && (( value < min ))
   then
      validationMessage lessThanMinMessage "Value must not be less than %s" "${min}"
      return
   fi

   type-get max
   if [[ "${max}" ]] && (( value > max ))
   then
      validationMessage greaterThanMaxMessage message "Value must not be greater than %s" "${max}"
      return
   fi
}

function validatePath() {
   local value="${1:?Missing value}"

   local root pathType

   type-get root
   type-get pathType

   [[ "${value}" = /* ]] || value="${root}${value}"

   if [[ "${value}" ]]
   then
      case "${pathType}" in
      dir|empty-dir)
         if ! [[ -d "${value}" ]]
         then
            validationMessage dirDoesNotExistMessage "Directory '%s' does not exist" "${value}"
            return
         fi
         if [[ "${pathType}" == empty-dir ]] && ! is-dir-empty "$(readlink -f "${value}")"
         then
            validationMessage dirNotEmptyMessage "Directory '%s' is not empty" "${value}"
            return
         fi
      ;;
      file)
         local realPath=$(realpath -m "${value}")
         if ! [[ -f "${realPath}" ]]
         then
            validationMessage fileDoesNotExistMessage "File '%s' does not exist" "${realPath}"
            return
         fi
      ;;
      new)
         local realPath=$(realpath -m "${value}")
         local parent=$(dirname "${realPath}")
         if ! [[ -d "${parent}" ]]
         then
            validationMessage dirDoesNotExistMessage "Directory '%s' does not exist" "${parent}"
            return
         fi
         if [[ -e "${realPath}" ]]
         then
            validationMessage dirExistsMessage "'%s' already exists" "${realPath}"
            return
         fi
      ;;
      *)
         error "Unsupported file type: '${pathType}'"
      ;;
      esac
   fi
}


function processPath() {
   RESULT=
   local value="${1:?Missing value}"
   [[ "${value}" = /* ]] || value="${root}${value}"

   RESULT="$(readlink -f "${value}")"
}

function ask-for() {
   local type=${1:?'Missed type name.'}
   shift
   local name=${1}
   if [[ -z "${name}" ]] || [[ ${name} =~ --.* ]]
   then
      name=${type}
   else
      shift
   fi

   VALSPEC_ASK=()
   type-def VALSPEC_ASK.${name} ${type} "$@"

   local verify desc help reuse maskInput silent default required validate process prompt value

   VALSPEC_CURRENT=VALSPEC_ASK
   TYPE_CURRENT=${name}
   type-get verify verify
   if [[ "${verify}" ]]
   then
      ${verify}
      if [[ "${RESULT}" ]]
      then
         error "${RESULT}"
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

   prompt="${desc:-"Provide ${name}"}${help:+" (${help})"}${default:+". Default is '${default}'"}${PS2}"
   while [ -z "${value}" ]
   do
      is-true ${maskInput} && silent="-s"
      read ${silent} -e -p "${prompt}" -i "${suggest}" value
      [[ ${silent} ]] && echo
      if [[ "${value}" ]] && [[ "${validate}" ]]
      then
         local validationMessage="$(${validate} "${value}")"
         if [[ "${validationMessage}" ]]
         then
            prompt="${validationMessage}. Try again${PS2}"
            suggest=''
            is-true "${reuse}" && suggest="${value}"
            value=''
            continue
         fi
      fi
      if [ -z "${value}" ]
      then
         if is-true "${required}"
         then
            prompt="Non empty value is required. Try again${PS2}"
         elif [[ "${default}" ]]
         then
            value="${default}" "${value}"
         else
            eval "${name}="
            return
         fi
      fi
   done
   if [[ "${process}" ]] && [[ "${value}" ]]
   then
      ${process} "${value}"
      value="${RESULT}"
   fi
   printf -v ${name} -- "${value}"
}


declare -A TYPESPEC=(
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

type-def bool enum --values "y n" --help "y/n" --desc "Please confirm" --invalidEnumMessage "Please type 'y' or 'n'"
type-def dir path --pathType dir
type-def file path --pathType file

declare -A VALSPEC_ASK=()
