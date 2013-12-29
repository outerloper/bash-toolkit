#!/bin/bash

### scriptNameForHelp B 1 util function - print out all set parameters - for user's testing/debugging
# DONE B 3 enhanced support for autocompletion (complete command features and custom functions)
# DONE B 2 option names taken from IDs by default
# DONE B 2->3 empty completion for main parameter prints instant help
# NONE C 3->discarded display instant help when no suggestions available
# DONE B 1 Global option for on/off instant help
# DONE B 3 multiple-word prefixes 12/30/13 12:01 AM
# DONE B 2 autocompletion bug: quoted arguments not working 12/30/13 12:01 AM
# DONE A 2 instant help working wrong 12/30/13 12:24 AM
# TODO B 2 options_help - as param to functions - more straightforward
# TODO B 3 use assoc tables instead of multiple vars for setup
# TODO B 3 autocompletion enhancement: always display some suggestion ('foo', 'foo ' ?)
# TODO B 4 API for defining parameters
# TODO B 4 Change arity=1/N/n to type=bool|string?+*
# TODO C 2 '--' special argument as escape sequence for values beginning with '--'
# TODO C 2 arrays as default parameter values
# TODO C 2 information about default value in help
# TODO C 2 Type: string/int
# TODO C 3 instant warnings display
# TODO C 3 configuration validation
# TODO C 3 public function calls validation
# TODO C 4 Generalize main special parameter to positional parameters (eval set -- $items)
# TODO C 4 Short options support: -a -ab -a val
# IDEA Instant validation
# IDEA Mandatory options first

### SETTINGS ###

DISPLAY_INSTANT_HELP=yes

### UTILS ###

function error() {
   echo "$1" 1>&2
}

function isTrue() {
   case "$1" in
   1|[tT][rR][uU][eE]|[yY]|[yY][eE][sS]) return 0 ;;
   0|[fF][aA][lL][sS][eE]|[nN]|[nN][oO]|"") return 1 ;;
   esac
   error "Warning: Invalid boolean value. False assumed."
   return 1
}

function is() {
   [[ -n "$1" ]]
   return $?
}

function no() {
   [[ -z "$1" ]]
   return $?
}

function resultCode() {
   [[ $? -ne 0 ]] && return 0
   return 1
}

function _prepareProcessingArgs() {
   local currentOptionRef
   local currentOptionSwitch
   for currentOption in ${optionList[@]}
   do
      currentOptionRef="${optionListRef}_${currentOption}"
      _setCurrentOptionSwitch
      optionSwitches[$currentOptionSwitch]="${currentOption}"
      unusedOptions[$currentOption]="${currentOptionSwitch}"
   done
}

function _setCurrentOptionSwitch() {
   if is "${!currentOptionRef}"
   then
      currentOptionSwitch="--${!currentOptionRef}"
   else
      currentOptionSwitch="--${currentOption}"
   fi
}

function _extractArgs() {
    args=( "$@" )
}

### AUTOCOMPLETION ###

function enableAutocompletion() { # TODO command with more than 1 prefix element
   local scriptNameForHelpRef="${1}_help"
   local scriptNameForHelp="${!scriptNameForHelpRef}"
   if is "${scriptNameForHelp}"
   then
      local fn="argComp__${scriptNameForHelp}"
      complete -F "${fn}" "${scriptNameForHelp}"
      eval "${fn}() {
   _argsAutocompletion '$1' 1
}"
   fi
}

function _argsAutocompletion() {
   local optionListRef=$1
   local optionList=${!optionListRef}
   local from=${2:-1}
   local completedArgsCount
   (( completedArgsCount = COMP_CWORD - from ))
   local currentWord="${COMP_WORDS[COMP_CWORD]}"
   local compReply=()
   local args=()
   local currentOption=main
   local currentOptionArgsCount=0
   _extractArgs "${COMP_WORDS[@]:${from}:${completedArgsCount}}"
   _getCompletion
   COMPREPLY=( $(compgen -W "${compReply[*]}" -- ${currentWord}) )
   isTrue "${DISPLAY_INSTANT_HELP}" && (( ${#COMPREPLY[@]} > 1 )) && _displayInstantHelp
}

function _getCompletion() {
   declare -A unusedOptions
   declare -A optionSwitches
   _prepareProcessingArgs

   currentOption=main
   currentOptionArgsCount=0
   _processArgsForCompletion

   _generateCompletions
}

function _processArgsForCompletion() {
   for arg in ${args[@]}
   do
      if [[ "${arg}" =~ ^--.+ ]]
      then
         currentOption="${optionSwitches[${arg}]}"
         is "${currentOption}" && unset "unusedOptions[${currentOption}]"
         currentOptionArgsCount=0
      else
         (( currentOptionArgsCount++ ))
      fi
   done
}

function _generateCompletions() {
   local currentOptionArityRef="${optionListRef}_${currentOption}_arity"
   local currentOptionArity="${!currentOptionArityRef}"
   local currentOptionRequiredRef="${optionListRef}_${currentOption}_required"
   local currentOptionRequired="${!currentOptionRequiredRef}"
   local currentOptionCompletionRef
   local currentOptionCompletion
   if [[ "${currentOption}" == main ]] && ! isTrue "${currentOptionRequired}" || no "${currentOptionArity}" || (( currentOptionArgsCount > 0 ))
   then
      compReply=( "${compReply[@]}" ${unusedOptions[@]} )
   fi
   if [[ "${currentOptionArity}" == "1" ]] && (( currentOptionArgsCount == 0 )) || [[ "${currentOptionArity}" =~ ^(n|N)$ ]]
   then
      currentOptionCompletionRef="${optionListRef}_${currentOption}_completion"
      currentOptionCompletion="${!currentOptionCompletionRef}"
      compReply=( "${compReply[@]}" "$(_evaluateCompletion)" )
   fi
}

function _evaluateCompletion() {
   if no "${currentOptionCompletion}"
   then
      :
   elif [[ "${currentOptionCompletion}" =~ ^[a-Z_-][0-Z_-]*\(\)$ ]]
   then
      compgen -F "${currentOptionCompletion//()}" 2>/dev/null # 2>/dev/null because stderr prints warning
   elif [[ "${currentOptionCompletion}" =~ ^(-f|-d)$ ]]
   then
      compgen "${currentOptionCompletion}"
   else
      compgen -W "${currentOptionCompletion}"
   fi
}

function _displayInstantHelp() {
   local currentOptionDescRef="${optionListRef}_${currentOption}_description"
   if is "${!currentOptionDescRef}"
   then
      local descPrefix
      if [[ "${currentOption}" == main ]]
      then
         argNameRef="${optionListRef}_main"
         descPrefix="${!argNameRef:-main parameter}: "
      else
         _setCurrentOptionSwitch
         descPrefix="${currentOptionSwitch}: "
      fi
      echo -en "\n\e[1;30m${descPrefix}${!currentOptionDescRef}\e[0m" >&2
   fi
}

### GET ARGS ###

function getArgs() {
   local optionListRef=$1
   local optionList=${!optionListRef}
   shift
   local args=( "$@" )
   _isHelpRequest && return 127

   declare -A unusedOptions
   declare -A optionSwitches
   _prepareProcessingArgs

   local currentOptionArgsCount=0
   local currentOptionArity
   local optionSwitch
   local first=1
   local currentOption
   local discardOption=''
   local resultCode=0
   declare -A usedOptions
   _initOption main
   for arg in "${args[@]}"
   do
      if [[ "${arg}" =~ ^--.+ ]]
      then
         _handleOptionSwitch
      else
         _handleOptionParam
      fi
      first=''
   done
   _handleOptionWithoutParams
   _handleUnusedOptions
   return ${resultCode}
}

function _isHelpRequest() {
   for arg in ${args[@]}
   do
      if [[ "${arg}" == "--help" ]]
      then
         printHelp "${optionListRef}"
         return 0
      fi
   done
   return 1
}

function _handleOptionSwitch() {
   _handleOptionWithoutParams
   optionSwitch="${arg}"
   _initOption ${optionSwitches[$optionSwitch]}
   is ${currentOption} && unset "unusedOptions[${currentOption}]"
   if is "${usedOptions[$optionSwitch]}"
   then
      error "Duplicate usage of option ${optionSwitch}."
      discardOption=1
      resultCode=1
   fi
   usedOptions[$optionSwitch]=1
}

function _handleOptionParam() {
   if is ${discardOption}
   then
      return 1;
   fi
   if no "${currentOptionArity}"
   then
      error "Unexpected value: ${arg}."
      resultCode=1
   else
      if [[ "${currentOptionArity}" == "1" ]] && (( currentOptionArgsCount > 0 ))
      then
         error "Unexpected value: ${arg}."
         resultCode=1
      else
         printf -v "${currentOption}[${currentOptionArgsCount}]" -- "${arg}"
      fi
   fi
   (( ++currentOptionArgsCount ))
}

function _initOption() {
   currentOption="$1"
   currentOptionArgsCount=0
   currentOptionArityRef="${optionListRef}_${currentOption}_arity"
   currentOptionArity=${!currentOptionArityRef}
   if no "${currentOption}"
   then
      error "Unknown option: ${optionSwitch}."
      discardOption=1
      resultCode=1
   fi
   discardOption=''
   unset "${currentOption}"
   eval "${currentOption}=()"
}

function _handleOptionWithoutParams() {
   if (( currentOptionArgsCount == 0 )) # if no args for previous option
   then
      if is "${currentOptionArity}" # if not flag, error
      then
         if is ${first}
         then
            _handleMissingMainParameter
         else
            no ${discardOption} && error "Missing required parameter for ${optionSwitch}."
            resultCode=1
         fi
      elif [[ "${currentOption}" != main ]] # if flag, assign 1 to value
      then
         unset ${currentOption}
         no ${discardOption} && printf -v ${currentOption} "1"
      fi
   fi
}

function _handleMissingMainParameter() {
   local mainOptionRequiredRef="${optionListRef}_main_required"
   if isTrue "${!mainOptionRequiredRef}"
   then
      local mainOptionNameRef="${optionListRef}_main"
      local mainOptionName="${!mainOptionNameRef:-main parameter}"
      error "Missing ${mainOptionName}."
      resultCode=1
   fi
}

function _handleUnusedOptions() {
   for currentOption in ${!unusedOptions[@]}
   do
      optionRequiredRef="${optionListRef}_${currentOption}_required"
      optionRequired=${!optionRequiredRef}
      if isTrue "${optionRequired}"
      then
         error "Missing mandatory option: ${unusedOptions[${currentOption}]}."
         resultCode=1
      else
         unset ${currentOption}
         optionDefaultRef="${optionListRef}_${currentOption}_default"
         optionDefault=${!optionDefaultRef}
         if is "${optionDefault}"
         then
            printf -v ${currentOption} -- ${optionDefault}
         fi
      fi
   done
}

### PRINT HELP ###

function printHelp() {
   local optionListRef="$1"
   local optionList=${!optionListRef}
   local optionUsageText

   local mainOptionNameRef="${optionListRef}_main"
   local mainOptionName="${!mainOptionNameRef:-main parameter}"
   local mainOptionDescriptionRef="${optionListRef}_main_description"
   local mainOptionDescription="${!mainOptionDescriptionRef}"
   local mainOptionArityRef="${optionListRef}_main_arity"
   local mainOptionArity="${!mainOptionArityRef}"
   local mainOptionRequiredRef="${optionListRef}_main_required"
   local mainOptionRequired="${!mainOptionRequiredRef}"

   local scriptNameForHelpRef="${optionListRef}_help"
   local scriptNameForHelp="${!scriptNameForHelpRef:-<this-command>}"
   local helpDescriptionRef="${optionListRef}_help_description"
   local helpDescription="${!helpDescriptionRef}"
   if is "${helpDescription}"
   then
      echo "${helpDescription}"
   fi

   echo "Usage:"
   _printCommandHelp
   if is "${mainOptionArity}" && is "${mainOptionDescription}"
   then
      echo "Parameters:"
      printf "  %-30s   %s\n" "<${mainOptionName}>" "${mainOptionDescription}"
   fi

   if is "${optionList}"
   then
      echo "Options:"
      for currentOption in ${optionList}
      do
         _printOptionHelp
      done
   fi
}

function _printCommandHelp() {
   printf "  ${scriptNameForHelp}"
   if is "${mainOptionArity}"
   then
      local mainOptionUsageText=""
      if [[ "${mainOptionArity}" == "1" ]]
      then
         mainOptionUsageText="<${mainOptionName}>"
      elif [[ "${mainOptionArity}" =~ ^(n|N)$ ]]
      then
         mainOptionUsageText="<${mainOptionName}> [...]"
      fi
      if ! isTrue "${mainOptionRequired}"
      then
         mainOptionUsageText="[${mainOptionUsageText}]"
      fi
      printf " ${mainOptionUsageText}"
   fi
   if is "${optionList}"
   then
      printf " <options>..."
   fi
   echo
}

function _printOptionHelp() {
   local currentOptionRef="${optionListRef}_${currentOption}"
   local currentOptionArityRef="${currentOptionRef}_arity"
   local currentOptionArity="${!currentOptionArityRef}"
   local currentOptionSwitch
   _setCurrentOptionSwitch
   local currentOptionRequiredRef="${optionListRef}_${currentOption}_required"
   local currentOptionRequired="${!currentOptionRequiredRef}"
   if no "${currentOptionArity}"
   then
      optionUsageText="${currentOptionSwitch}"
   elif [[ "${currentOptionArity}" == "1" ]]
   then
      optionUsageText="${currentOptionSwitch} <value>"
   elif [[ "${currentOptionArity}" =~ ^(n|N)$ ]]
   then
      optionUsageText="${currentOptionSwitch} <value> [...]"
   fi
   local currentOptionDescriptionRef="${currentOptionRef}_description"
   local currentOptionDescription="${!currentOptionDescriptionRef}"
   if isTrue "${currentOptionRequired}"
   then
      currentOptionDescription="REQUIRED. ${currentOptionDescription}"
   fi
   printf "  %-30s   %s\n" "${optionUsageText}" "${currentOptionDescription}"
}

### PRINT PARAMS ###

function printArgs() {
   local optionListRef=$1
   local optionList=( main ${!optionListRef} )
   local value
   for currentOption in ${optionList[@]}
   do
      eval 'value=( "${'"${currentOption}"'[*]}" )'
      if is "${value[@]}"
      then
         printf "%16s: %s\n" "${currentOption}" "'${value[@]}'"
      fi
   done
}
