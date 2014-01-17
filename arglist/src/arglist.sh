#!/bin/bash

source "$(dirname ${BASH_SOURCE})/../../core/src/utils.sh"

### SETTINGS ###

DISPLAY_INSTANT_HELP=yes

### UTILS ###

function _setOptionList() {
   local optionSpecDecl=$(declare -p $1)
   optionSpecDecl=${optionSpecDecl#"declare -A $1='"}
   optionSpecDecl=${optionSpecDecl%"'"}
   eval "optionSpec=${optionSpecDecl}"
   declare -A optionMap=()
   local option
   for key in ${!optionSpec[@]}
   do
      option=${key/.*/}
      optionMap[$option]=1
   done
   unset optionMap[main]
   unset optionMap[help]
   for key in ${!optionMap[@]}
   do
      optionList+=" ${key}"
   done
}

function _prepareProcessingArgs() {
   local currentOptionSwitch
   for currentOption in ${optionList[@]}
   do
      _setCurrentOptionSwitch
      optionSwitches[$currentOptionSwitch]="${currentOption}"
      unusedOptions[$currentOption]="${currentOptionSwitch}"
   done
}

function _setCurrentOptionSwitch() {
   if is ${optionSpec["${currentOption}"]}
   then
      currentOptionSwitch="--${optionSpec["${currentOption}"]}"
   else
      currentOptionSwitch="--${currentOption}"
   fi
}

function _extractArgs() {
    args=( "$@" )
}

### AUTOCOMPLETION ###

function enableAutocompletion() { # TODO command with more than 1 prefix element
   declare -A optionSpec=()
   local optionList
   _setOptionList $1
   local scriptNameForHelp=${optionSpec["help"]}
   if is "${scriptNameForHelp}"
   then
      local fn="__argComp_${scriptNameForHelp}"
      complete -F "${fn}" "${scriptNameForHelp}"
      eval ${fn}'() { _argsAutocompletion '$1' 1; }'
   fi
}

function _argsAutocompletion() {
   declare -A optionSpec=()
   local optionList
   _setOptionList $1
   local from=${2:-1}
   local completedArgsCount
   (( completedArgsCount = COMP_CWORD - from ))
   local currentWord="${COMP_WORDS[COMP_CWORD]}"
   local compReply=()
   local currentOption=main
   local currentOptionArgsCount=0
   local args=()
   _extractArgs "${COMP_WORDS[@]:${from}:${completedArgsCount}}"
   _getCompletion
   COMPREPLY=( $(compgen -W "${compReply[*]}" -- ${currentWord}) )
   is-true "${DISPLAY_INSTANT_HELP}" && (( ${#COMPREPLY[@]} > 1 )) && _displayInstantHelp
}

function _getCompletion() {
   declare -A unusedOptions=()
   declare -A optionSwitches=()
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
   local currentOptionArity="${optionSpec["${currentOption}.arity"]}"
   local currentOptionRequired="${optionSpec["${currentOption}.required"]}"
   local currentOptionCompletion
   if [[ "${currentOption}" == main ]] && ! is-true "${currentOptionRequired}" || no "${currentOptionArity}" || (( currentOptionArgsCount > 0 ))
   then
      compReply=( "${compReply[@]}" ${unusedOptions[@]} )
   fi
   if [[ "${currentOptionArity}" == "1" ]] && (( currentOptionArgsCount == 0 )) || [[ "${currentOptionArity}" =~ ^(n|N)$ ]]
   then
      currentOptionCompletion="${optionSpec["${currentOption}.comp"]}"
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
   local currentOptionDesc="${optionSpec["${currentOption}.desc"]}"
   if is "${currentOptionDesc}"
   then
      local descPrefix
      if [[ "${currentOption}" == main ]]
      then
         argName="${optionSpec["main"]}"
         descPrefix="${argName:-main parameter}: "
      else
         _setCurrentOptionSwitch
         descPrefix="${currentOptionSwitch}: "
      fi
      echo -en "\n\e[1;30m${descPrefix}${currentOptionDesc}\e[0m" >&2
   fi
}

### GET ARGS ###

function getArgs() {
   declare -A optionSpec=()
   local optionList
   local optionListName=$1
   _setOptionList ${optionListName}
   shift
   local args=( "$@" )
   _isHelpRequest ${optionListName} && return 127

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
   declare -A usedOptions=()
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
         printHelp $1
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
   currentOptionArity="${optionSpec["${currentOption}.arity"]}"
   if is "${currentOption}"
   then
      unset "${currentOption}"
      eval ${currentOption}'=()'
      discardOption=''
   else
      error "Unknown option: ${optionSwitch}."
      discardOption=1
      resultCode=1
   fi
}

function _handleOptionWithoutParams() {
   if (( currentOptionArgsCount == 0 ))
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
   unset ${currentOption}
   local currentOptionRequired="${optionSpec["${currentOption}.required"]}"
   if is-true "${currentOptionRequired}"
   then
      local currentOptionName="${optionSpec["${currentOption}"]}"
      local currentOptionName="${currentOptionName:-main parameter}"
      error "Missing ${currentOptionName}."
      resultCode=1
   else
      local currentOptionDefault="${optionSpec["${currentOption}.default"]}"
      if is "${currentOptionDefault}"
      then
         printf -v ${currentOption} "${currentOptionDefault}"
      fi
   fi
}

function _handleUnusedOptions() {
   for currentOption in ${!unusedOptions[@]}
   do
      optionRequired="${optionSpec["${currentOption}.required"]}"
      if is-true "${optionRequired}"
      then
         error "Missing mandatory option: ${unusedOptions[${currentOption}]}."
         resultCode=1
      else
         printf -v ${currentOption} -- ''
         currentOptionDefault="${optionSpec["${currentOption}.default"]}"
         if is "${currentOptionDefault}"
         then
            printf -v ${currentOption} -- ${currentOptionDefault}
         fi
      fi
   done
}

### PRINT HELP ###

function printHelp() {
   if no ${optionList}
   then
      declare -A optionSpec=()
      local optionList
      _setOptionList $1
   fi

   local optionUsageText

   local currentOption=main
   local currentOptionName="${optionSpec["${currentOption}"]}"
   local currentOptionName="${currentOptionName:-main parameter}"
   local currentOptionDescription="${optionSpec["${currentOption}.desc"]}"
   local currentOptionArity="${optionSpec["${currentOption}.arity"]}"
   local currentOptionRequired="${optionSpec["${currentOption}.required"]}"

   local scriptNameForHelp="${optionSpec["help"]}"
   local scriptNameForHelp="${scriptNameForHelp:-<this-command>}"
   local helpDescription="${optionSpec["help.desc"]}"
   if is "${helpDescription}"
   then
      echo "${helpDescription}"
   fi

   echo "Usage:"
   _printCommandHelp
   if is "${currentOptionArity}" && is "${currentOptionDescription}"
   then
      echo "Parameters:"
      _modifyCurrentOptionDescription
      printf "  %-30s   %s\n" "<${currentOptionName}>" "${currentOptionDescription}"
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
   if is "${currentOptionArity}"
   then
      local optionUsageText=""
      if [[ "${currentOptionArity}" == "1" ]]
      then
         optionUsageText="<${currentOptionName}>"
      elif [[ "${currentOptionArity}" =~ ^(n|N)$ ]]
      then
         optionUsageText="<${currentOptionName}> [...]"
      fi
      if ! is-true "${currentOptionRequired}"
      then
         optionUsageText="[${optionUsageText}]"
      fi
      printf " ${optionUsageText}"
   fi
   if is "${optionList}"
   then
      printf " <options>..."
   fi
   echo
}

function _printOptionHelp() {
   local currentOptionSwitch
   _setCurrentOptionSwitch
   currentOptionArity="${optionSpec["${currentOption}.arity"]}"
   currentOptionRequired="${optionSpec["${currentOption}.required"]}"
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

   currentOptionDescription="${optionSpec["${currentOption}.desc"]}"
   if is-true "${currentOptionRequired}"
   then
      currentOptionDescription="REQUIRED. ${currentOptionDescription}"
   fi
   _modifyCurrentOptionDescription

   printf "  %-30s   %s\n" "${optionUsageText}" "${currentOptionDescription}"
}

function _modifyCurrentOptionDescription() {
   local currentOptionDefault="${optionSpec["${currentOption}.default"]}"
   if is "${currentOptionDefault}"
   then
      currentOptionDescription="${currentOptionDescription%.}. Default is '${currentOptionDefault}'."
   fi
}

### PRINT PARAMS ###

function printArgs() {
   declare -A optionSpec=()
   local optionList
   _setOptionList $1
   local value

   optionList=( main ${optionList} )
   for currentOption in ${optionList[@]}
   do
      eval 'value=( "${'"${currentOption}"'[*]}" )'
      if is "${value[@]}"
      then
         printf "%16s: %s\n" "${currentOption}" "'${value[@]}'"
      fi
   done
}


### EXAMPLE/DEMO ###
# 1. execute: ARGLIST_DEMO=1; ./arglist.sh
# 2. execute: greet --help
# 3. basing on help displayed in 2. play with 'greet' command to see arglist in action

if is "${ARGLIST_DEMO}"
then
   declare -A options=( # note associative array should be visible inside the executable thet it supports
      ["help"]='greet'
      ["help.desc"]='This is arglist.sh demo.'
      ["main"]='phrase'
      ["main.required"]=no
      ["main.arity"]=1
      ["main.comp"]='hello salut privet ciao serwus ahoj'
      ["main.desc"]='Greeting phrase.'
      ["main.default"]='Hello'
      ["times"]=times
      ["times.arity"]=1
      ["times.required"]=yes
      ["times.desc"]='How many times to greet.'
      ["loud"]=loud
      ["loud.desc"]='Whether to greet loudly.'
      ["persons.arity"]=n
      ["persons.required"]=yes
      ["persons.desc"]='Persons to greet.'
      ["persons.comp"]='john bob alice world'
   )
   enableAutocompletion options

   function greet() {
      local main persons loud times # declare used variables for clarity or IDE support
      if getArgs options "$@" # remember to quote $@, otherwise quoted arguments with spaces inside will not work properly
      then
         printArgs options # for development purpose or verbose mode

         for (( i = 0; i < times; i++)) {
            echo "${main} ${persons[@]}${loud:+!!}"
         }
      else
         return 1 # parameters misusage should return with error code
      fi
   }
fi
