#!/bin/bash

require ${HOME}/.bash-toolkit/core/src/utils.sh

### SETTINGS ###

DISPLAY_INSTANT_HELP=yes # TODO some prefix

### UTILS ###

function _prepareProcessingArgs() {
   local currentOptionSwitch
   for currentOption in ${ARGSPEC["$1.ARGS"]}
   do
      _setCurrentOptionSwitch
      optionSwitches[$currentOptionSwitch]="$currentOption"
      unusedOptions[$currentOption]="$currentOptionSwitch"
   done
}

function _setCurrentOptionSwitch() {
   if -n ${ARGSPEC["$1.$currentOption"]}
   then
      currentOptionSwitch="--${ARGSPEC["$1.$currentOption.name"]}"
   else
      currentOptionSwitch="--$currentOption"
   fi
}

function _extractArgs() {
    args=( "$@" )
}

### AUTOCOMPLETION ###

function _enableAutocompletion() {
   local fn="__argComp_$1"
   complete -F "$fn" "$1"
   eval $fn'() { _argsAutocompletion '$1' 1; }'
}

function _argsAutocompletion() {
   local from=${2:-1}
   local completedArgsCount
   (( completedArgsCount = COMP_CWORD - from ))
   local currentWord="${COMP_WORDS[COMP_CWORD]}"
   local compReply=()
   local currentOption=MAIN
   local currentOptionArgsCount=0
   local args=()
   _extractArgs "${COMP_WORDS[@]:$from:$completedArgsCount}"
   _getCompletion $1
   COMPREPLY=( $(compgen -W "${compReply[*]}" -- $currentWord) )
   -true "$DISPLAY_INSTANT_HELP" && (( ${#COMPREPLY[@]} > 1 )) && _displayInstantHelp $1
}

function _getCompletion() {
   declare -A unusedOptions=()
   declare -A optionSwitches=()
   _prepareProcessingArgs $1

   currentOption=MAIN
   currentOptionArgsCount=0
   _processArgsForCompletion

   _generateCompletions $1
}

function _processArgsForCompletion() {
   for arg in ${args[@]}
   do
      if -m "$arg" '^--.+'
      then
         currentOption="${optionSwitches[$arg]}"
         -n "$currentOption" && unset "unusedOptions[$currentOption]"
         currentOptionArgsCount=0
      else
         (( currentOptionArgsCount++ ))
      fi
   done
}

function _generateCompletions() {
   local currentOptionArity="${ARGSPEC["$1.$currentOption.arity"]}"
   local currentOptionRequired="${ARGSPEC["$1.$currentOption.required"]}"
   local currentOptionCompletion
   if -eq MAIN "$currentOption" && -false "$currentOptionRequired" || -z "$currentOptionArity" || -gt "$currentOptionArgsCount" 0
   then
      compReply=( "${compReply[@]}" ${unusedOptions[@]} )
   fi
   if -eq "$currentOptionArity" 1 && -eq "$currentOptionArgsCount" 0 || -ma "$currentOptionArity" '[Nn]'
   then
      currentOptionCompletion="${ARGSPEC["$1.$currentOption.comp"]}"
      compReply=( "${compReply[@]}" "$(_evaluateCompletion)" )
   fi
   if -z "${compReply[@]}"
   then
      compReply=( '–—' '—–' )
   fi
}

function _evaluateCompletion() {
   if -z "$currentOptionCompletion"
   then
      :
   elif -ma "$currentOptionCompletion" '[a-Z_-][0-Z_-]*\(\)'
   then
      compgen -F "${currentOptionCompletion//()}" 2>/dev/null
   elif -ma "$currentOptionCompletion" '-f|-d'
   then
      compgen "$currentOptionCompletion"
   else
      compgen -W "$currentOptionCompletion"
   fi
}

function _displayInstantHelp() {
   local currentOptionDesc="${ARGSPEC["$1.$currentOption.desc"]}"
   if -n "$currentOptionDesc"
   then
      local descPrefix
      if -eq MAIN "$currentOption"
      then
         argName="${ARGSPEC["$1.MAIN"]}"
         descPrefix="${argName:-main parameter}: "
      else
         _setCurrentOptionSwitch $1
         descPrefix="$currentOptionSwitch: "
      fi
      echo -en "\n\e[1;30m$descPrefix""$currentOptionDesc\e[0m" >&2
   fi
}

### GET ARGS ###

function getArgs() {
   local argListName=$1
   shift
   local args=( "$@" )
   _isHelpRequest $argListName && return 127

   declare -A unusedOptions
   declare -A optionSwitches
   _prepareProcessingArgs $argListName

   local currentOptionArgsCount=0
   local currentOptionArity
   local optionSwitch
   local first=1
   local currentOption
   local discardOption=''
   local resultCode=0
   declare -A usedOptions=()
   _initOption MAIN
   for arg in "${args[@]}"
   do
      if -m "$arg" '^--.+'
      then
         _handleOptionSwitch
      else
         _handleOptionParam
      fi
      first=''
   done
   _handleOptionWithoutParams $argListName
   _handleUnusedOptions $argListName
   return $resultCode
}

function _isHelpRequest() {
   for arg in ${args[@]}
   do
      if -eq --help "$arg"
      then
         printHelp $1
         return 0
      fi
   done
   return 1
}

function _handleOptionSwitch() {
   _handleOptionWithoutParams $argListName
   optionSwitch="$arg"
   _initOption ${optionSwitches[$optionSwitch]}
   -n $currentOption && unset "unusedOptions[$currentOption]"
   if -n "${usedOptions[$optionSwitch]}"
   then
      stderr "Duplicate usage of option $optionSwitch" # TODO
      discardOption=1
      resultCode=1
   fi
   usedOptions[$optionSwitch]=1
}

function _handleOptionParam() {
   if -n $discardOption
   then
      return 1;
   fi
   if -z "$currentOptionArity"
   then
      stderr "Unexpected value: $arg"
      resultCode=1
   else
      if -eq 1 "$currentOptionArity" && -gt $currentOptionArgsCount 0
      then
         stderr "Unexpected value: $arg"
         resultCode=1
      else
         set-var "$currentOption[$currentOptionArgsCount]" "$arg"
      fi
   fi
   (( ++currentOptionArgsCount ))
}

function _initOption() {
   currentOption="$1"
   currentOptionArgsCount=0
   currentOptionArity="${ARGSPEC["$argListName.$currentOption.arity"]}"
   if -n "$currentOption"
   then
      unset "$currentOption"
      eval $currentOption'=()'
      discardOption=''
   else
      stderr "Unknown option: $optionSwitch"
      discardOption=1
      resultCode=1
   fi
}

function _handleOptionWithoutParams() {
   if (( currentOptionArgsCount == 0 ))
   then
      if -n "$currentOptionArity" # if not flag, error
      then
         if -n $first
         then
            _handleMissingMainParameter $1
         else
            -z $discardOption && stderr "Missing required parameter for $optionSwitch"
            resultCode=1
         fi
      elif -neq MAIN "$currentOption" # if flag, assign 1 to value
      then
         unset $currentOption
         -z $discardOption && printf -v $currentOption "1"
      fi
   fi
}

function _handleMissingMainParameter() {
   unset $currentOption
   local currentOptionRequired="${ARGSPEC["$1.$currentOption.required"]}"
   if -true "$currentOptionRequired"
   then
      local currentOptionName="${ARGSPEC["$1.$currentOption"]}"
      currentOptionName="${currentOptionName:-main parameter}"
      stderr "Missing $currentOptionName."
      resultCode=1
   else
      local currentOptionDefault="${ARGSPEC["$1.$currentOption.default"]}"
      if -n "$currentOptionDefault"
      then
         printf -v $currentOption "$currentOptionDefault"
      fi
   fi
}

function _handleUnusedOptions() {
   for currentOption in ${!unusedOptions[@]}
   do
      optionRequired="${ARGSPEC["$1.$currentOption.required"]}"
      if -true "$optionRequired"
      then
         stderr "Missing mandatory option: ${unusedOptions[$currentOption]}"
         resultCode=1
      else
         set-var $currentOption ''
         currentOptionDefault="${ARGSPEC["$1.$currentOption.default"]}"
         if -n "$currentOptionDefault"
         then
            printf -v $currentOption -- $currentOptionDefault
         fi
      fi
   done
}

### PRINT HELP ###

function printHelp() {
   local optionUsageText

   local currentOption=MAIN
   local currentOptionName="${ARGSPEC["$1.$currentOption.name"]}"
   currentOptionName="${currentOptionName:-main parameter}"
   local currentOptionDescription="${ARGSPEC["$1.$currentOption.desc"]}"
   local currentOptionArity="${ARGSPEC["$1.$currentOption.arity"]}"
   local currentOptionRequired="${ARGSPEC["$1.$currentOption.required"]}"

   local scriptNameForHelp="${ARGSPEC["$1"]}"
   local scriptNameForHelp="${scriptNameForHelp:-$1}"
   local helpDescription="${ARGSPEC["$1.DESC"]}"
   if -n "$helpDescription"
   then
      echo "$helpDescription"
   fi

   echo "Usage:"
   _printCommandHelp $1
   if -n "$currentOptionArity" && -n "$currentOptionDescription"
   then
      echo "Parameters:"
      _modifyCurrentOptionDescription $1
      printf "  %-30s   %s\n" "<$currentOptionName>" "$currentOptionDescription"
   fi

   if -n "${ARGSPEC["$1.ARGS"]}"
   then
      echo "Options:"
      for currentOption in ${ARGSPEC["$1.ARGS"]}
      do
          if -neq "$currentOption" MAIN
          then
            _printOptionHelp $1
          fi
      done
   fi
}

function _printCommandHelp() {
   printf "  $scriptNameForHelp"
   if -n "$currentOptionArity"
   then
      local optionUsageText=""
      if -eq "$currentOptionArity" 1
      then
         optionUsageText="<$currentOptionName>"
      elif -ma "$currentOptionArity" '[Nn]'
      then
         optionUsageText="<$currentOptionName> [...]"
      fi
      if -false "$currentOptionRequired"
      then
         optionUsageText="[$optionUsageText]"
      fi
      printf " $optionUsageText"
   fi
   if -n "${ARGSPEC["$1.ARGS"]}"
   then
      printf " <options>..."
   fi
   echo
}

function _printOptionHelp() {
   local currentOptionSwitch
   _setCurrentOptionSwitch $1
   currentOptionArity="${ARGSPEC["$1.$currentOption.arity"]}"
   currentOptionRequired="${ARGSPEC["$1.$currentOption.required"]}"
   if -z "$currentOptionArity"
   then
      optionUsageText="$currentOptionSwitch"
   elif -eq "$currentOptionArity" 1
   then
      optionUsageText="$currentOptionSwitch <value>"
   elif -ma "$currentOptionArity" '[Nn]'
   then
      optionUsageText="$currentOptionSwitch <value> [...]"
   fi

   currentOptionDescription="${ARGSPEC["$1.$currentOption.desc"]}"
   if -true "$currentOptionRequired"
   then
      currentOptionDescription="REQUIRED. $currentOptionDescription"
   fi
   _modifyCurrentOptionDescription $1

   printf "  %-30s   %s\n" "$optionUsageText" "$currentOptionDescription"
}

function _modifyCurrentOptionDescription() {
   local currentOptionDefault="${ARGSPEC["$1.$currentOption.default"]}"
   if -n "$currentOptionDefault"
   then
      currentOptionDescription="${currentOptionDescription%.}. Default is: '$currentOptionDefault'"
   fi
}

### PRINT PARAMS ###

function printArgs() {
   local value

   for currentOption in MAIN ${ARGSPEC["$1.ARGS"]}
   do
      eval 'value=( "${'"$currentOption"'[*]}" )'
      if -n "${value[@]}"
      then
         printf "%16s: %s\n" "$currentOption" "'${value[@]}'"
      fi
   done
}

ARGSPEC=( # @global-assoc
    [argspec.DESC]='Adds a parameter definition for an executable. Run once for each parameter.'
    [argspec.ARGS]='for name required default arity desc comp'
    [argspec.MAIN.name]='id'
    [argspec.MAIN.desc]='Parameter ID. getArgs() creates variable with this name so it should be valid bash var id.'
    [argspec.MAIN.required]='yes'
    [argspec.MAIN.arity]='1'
    [argspec.for.desc]='Name of executable for which the parameter is added.'
    [argspec.for.required]='yes'
    [argspec.for.arity]='1'
    [argspec.name.desc]='Use this option if you want --parameter-name to be different from its ID.'
    [argspec.name.arity]='1'
    [argspec.required.desc]='Specify this flag when parameter is mandatory.'
    [argspec.default.desc]='Default value to use for the parameter when user does not provide one.'
    [argspec.default.arity]='1'
    [argspec.arity.desc]='No value means that the parameter is a flag. "1" means parameter has a value. "n" means multiple values.'
    [argspec.arity.arity]='1'
    [argspec.arity.comp]='1 n'
    [argspec.desc.desc]='Description displayed in --help mode.'
    [argspec.desc.arity]='1'
    [argspec.comp.desc]='Values for autocompletion or "fun()" - name of function printing such space-separated values.'
    [argspec.comp.arity]='n'
    [argspec-init.ARGS]='desc'
    [argspec-init.MAIN.desc]='Name of executable to initialize.'
    [argspec-init.MAIN.arity]='1'
    [argspec-init.MAIN.required]='yes'
    [argspec-init.desc.desc]='General description displayed in --help mode.'
    [argspec-init.desc.arity]='1'
)

function argspec() {
    local MAIN 'for' name required default arity desc comp
    if getArgs ${FUNCNAME[0]} "$@"
    then
       -n "$required" && ARGSPEC["$for.$MAIN.required"]="$required"
       -n "$default" && ARGSPEC["$for.$MAIN.default"]="$default"
       -n "$arity" && ARGSPEC["$for.$MAIN.arity"]="$arity"
       -n "$desc" && ARGSPEC["$for.$MAIN.desc"]="$desc"
       -n "$comp" && ARGSPEC["$for.$MAIN.comp"]="${comp[@]}"
       -n "$name" && ARGSPEC["$for.$MAIN.name"]="$name"
       [ "$MAIN" != MAIN ] && ! [[ " ${ARGSPEC["$for.ARGS"]} " =~ " $MAIN " ]] && ARGSPEC["$for.ARGS"]+="$MAIN "
    else
        return 1
    fi
}

function argspec-init() {
    local MAIN desc
    if getArgs ${FUNCNAME[0]} "$@"
    then
       -n "$desc" && ARGSPEC["$MAIN.DESC"]="$desc"
    else
        return 1
    fi
   _enableAutocompletion $MAIN
}

argspec-init argspec
argspec-init argspec-init --desc 'Initializes autocompletion and getArgs() function for executable of given name.'

# TODO --arity -> --type: 0 - flag, ? - opt-value, 1 - value, * - opt-list, + - list
# TODO add --value-type: int dir file...

function argspec-demo() {
   argspec MAIN --for greet --name phrase --arity 1 --comp hello salut privet ciao czesc ahoj --desc 'Greeting phrase.' --default Hello
   argspec times --for greet --arity 1 --desc 'How many times to greet.' --required
   argspec loud --for greet --desc 'Whether to greet with exclamation mark.'
   argspec persons --for greet --arity n --comp 'getNames()' --desc 'Who to greet.' --required
   argspec-init greet

   function getNames() { # example function for autocompletion
      echo john bob alice world
   }

   function greet() {
      local MAIN persons loud times
      if getArgs greet "$@" # quote $@ to properly handle arguments with spaces
      then
         printArgs greet # for debugging

         for (( i = 0; i < times; i++ )) { # custom logic start
            echo "$MAIN ${persons[@]}${loud:+!!}"
         } # custom logic end
      else
         return 1
      fi
   }

   echo -e "Execute:\n  declare -f argspec-demo\n  greet --help\nPlay with autocompletion by pressing <tab> while providing parameters for 'greet' command."
}
