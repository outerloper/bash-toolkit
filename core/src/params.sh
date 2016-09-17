#!/bin/bash

require utils.sh

### SETTINGS ###

PARAMS_DISPLAY_INSTANT_HELP=yes
PARAMS_CURRENT_DEF=

### UTILS ###

function _prepareProcessingArgs() {
   local currentOptionSwitch
   for currentOption in ${PARAMS["$1.ARGS"]}
   do
      _setCurrentOptionSwitch $1
      optionSwitches[$currentOptionSwitch]="$currentOption"
      unusedOptions[$currentOption]="$currentOptionSwitch"
   done
}

function _setCurrentOptionSwitch() {
   if -n ${PARAMS["$1.$currentOption.name"]}
   then
      currentOptionSwitch="--${PARAMS["$1.$currentOption.name"]}"
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
   -true "$PARAMS_DISPLAY_INSTANT_HELP" && (( ${#COMPREPLY[@]} > 1 )) && _displayInstantHelp $1
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
      if -has "$arg" '--*'
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
   local currentOptionType="${PARAMS["$1.$currentOption.type"]}"
   local currentOptionRequired="${PARAMS["$1.$currentOption.required"]}"
   local currentOptionIsValue="${PARAMS["$1.$currentOption.isValue"]}"
   local currentOptionCompletion
   compReply=( '–—' '—–' )
   if -eq MAIN "$currentOption" && -false "$currentOptionRequired" || -eq flag "$currentOptionType" || -gt "$currentOptionArgsCount" 0 || -n "$currentOptionIsValue"
   then
      compReply=( "${compReply[@]}" ${unusedOptions[@]} )
   fi
   if -eq value "$currentOptionType" && -eq "$currentOptionArgsCount" 0 || -eq list "$currentOptionType"
   then
      currentOptionCompletion="${PARAMS["$1.$currentOption.comp"]}"
      compReply=( "${compReply[@]}" "$(_evaluateCompletion)" )
   fi
}

function _evaluateCompletion() {
   if -z "$currentOptionCompletion"
   then
      :
   elif -rlike "$currentOptionCompletion" '[a-Z_-][0-Z_-]*\(\)'
   then
      compgen -F "${currentOptionCompletion//()}" 2>/dev/null
   elif -rlike "$currentOptionCompletion" '-f|-d'
   then
      compgen "$currentOptionCompletion"
   else
      compgen -W "$currentOptionCompletion"
   fi
}

function _displayInstantHelp() {
   local currentOptionDesc="${PARAMS["$1.$currentOption.desc"]}"
   if -n "$currentOptionDesc"
   then
      local descPrefix
      if -eq MAIN "$currentOption"
      then
         argName="${PARAMS["$1.MAIN"]}"
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
   local paramsName=$1
   shift
   local args=( "$@" )
   _isHelpRequest $paramsName && return 127

   declare -A unusedOptions
   declare -A optionSwitches
   _prepareProcessingArgs $paramsName

   local currentOptionArgsCount=0
   local currentOptionType
   local optionSwitch
   local first=1
   local currentOption
   local discardOption=''
   local resultCode=0
   declare -A usedOptions=()
   _initOptionForGetArgs MAIN
   for arg in "${args[@]}"
   do
      if -has "$arg" '--*'
      then
         _handleOptionSwitch
      else
         _handleOptionParam
      fi
      first=''
   done
   _handleOptionWithoutArgs $paramsName
   _handleUnusedOptions $paramsName
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
   _handleOptionWithoutArgs $paramsName
   optionSwitch="$arg"
   _initOptionForGetArgs ${optionSwitches[$optionSwitch]}
   -n $currentOption && unset "unusedOptions[$currentOption]"
   if -n "${usedOptions[$optionSwitch]}"
   then
      stderr "Duplicate usage of option $optionSwitch"
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
   if -eq flag "$currentOptionType"
   then
      stderr "Unexpected value: $arg"
      resultCode=1
   else
      if -eq value "$currentOptionType" && -gz $currentOptionArgsCount
      then
         stderr "Unexpected value: $arg"
         resultCode=1
      else
         set-var "$currentOption[$currentOptionArgsCount]" "$arg"
      fi
   fi
   (( ++currentOptionArgsCount ))
}

function _initOptionForGetArgs() {
   currentOption="$1"
   currentOptionArgsCount=0
   currentOptionType="${PARAMS["$paramsName.$currentOption.type"]}"
   currentOptionIsValue="${PARAMS["$paramsName.$currentOption.isValue"]}"
   currentOptionDefault="${PARAMS["$paramsName.$currentOption.default"]}"
   if -n "$currentOption"
   then
      unset "$currentOption"
      eval $currentOption'=()'
      discardOption=''
      -n "$currentOptionIsValue" && {
          unset "$currentOptionIsValue"
          set-var $currentOptionIsValue 1
      }
   else
      stderr "Unknown option: $optionSwitch"
      discardOption=1
      resultCode=1
   fi
}

function _handleOptionWithoutArgs() {
   if (( currentOptionArgsCount == 0 ))
   then
      if -neq flag "$currentOptionType"
      then
         if -n $first
         then
            _handleMissingMainArg $1
         elif -n $currentOptionIsValue ;then
            -n "$currentOptionDefault" && set-var $currentOption "$currentOptionDefault"
         else
            -z $discardOption && stderr "Missing required parameter for $optionSwitch"
            resultCode=1
         fi
      elif -neq MAIN "$currentOption" # if flag, assign 1 to value
      then
         unset $currentOption
         -z $discardOption && set-var $currentOption "1"
      fi
   fi
}

function _handleMissingMainArg() {
   unset $currentOption
   local currentOptionRequired="${PARAMS["$1.$currentOption.required"]}"
   if -true "$currentOptionRequired"
   then
      local currentOptionName="${PARAMS["$1.$currentOption"]}"
      currentOptionName="${currentOptionName:-main parameter}"
      stderr "Missing $currentOptionName."
      resultCode=1
   else
      local currentOptionDefault="${PARAMS["$1.$currentOption.default"]}"
      if -n "$currentOptionDefault"
      then
         set-var $currentOption "$currentOptionDefault"
      fi
   fi
}

function _handleUnusedOptions() {
   for currentOption in ${!unusedOptions[@]}
   do
      optionRequired="${PARAMS["$1.$currentOption.required"]}"
      if -true "$optionRequired"
      then
         stderr "Missing mandatory option: ${unusedOptions[$currentOption]}"
         resultCode=1
      else
         set-var $currentOption ''
         currentOptionDefault="${PARAMS["$1.$currentOption.default"]}"
         -n "$currentOptionDefault" && set-var $currentOption $currentOptionDefault
      fi
   done
}

### PRINT HELP ###

function printHelp() {
   local optionUsageText

   local currentOption=MAIN
   local currentOptionName="${PARAMS["$1.$currentOption.name"]}"
   currentOptionName="${currentOptionName:-MAIN}"
   local currentOptionDescription="${PARAMS["$1.$currentOption.desc"]}"
   local currentOptionType="${PARAMS["$1.$currentOption.type"]}"
   local currentOptionRequired="${PARAMS["$1.$currentOption.required"]}"

   local scriptNameForHelp="${PARAMS["$1"]}"
   local scriptNameForHelp="${scriptNameForHelp:-$1}"
   local helpDescription="${PARAMS["$1.DESC"]}"
   if -n "$helpDescription"
   then
      echo "$helpDescription"
   fi

   echo "Usage:"
   _printCommandHelp $1
   if -neq flag "$currentOptionType" && -n "$currentOptionDescription"
   then
      echo "Parameters:"
      _modifyCurrentOptionDescription $1
      printf "  %-30s   %s\n" "<$currentOptionName>" "$currentOptionDescription"
   fi

   if -n "${PARAMS["$1.ARGS"]}"
   then
      echo "Options:"
      for currentOption in ${PARAMS["$1.ARGS"]}
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
   if -neq flag "$currentOptionType"
   then
      local optionUsageText=""
      if -eq value "$currentOptionType"
      then
         optionUsageText="<$currentOptionName>"
      elif -eq list "$currentOptionType"
      then
         optionUsageText="<$currentOptionName> [...]"
      fi
      if -false "$currentOptionRequired"
      then
         optionUsageText="[$optionUsageText]"
      fi
      printf " $optionUsageText"
   fi
   if -n "${PARAMS["$1.ARGS"]}"
   then
      printf " <options>..."
   fi
   echo
}

function _printOptionHelp() {
   local currentOptionSwitch
   _setCurrentOptionSwitch $1
   currentOptionType="${PARAMS["$1.$currentOption.type"]}"
   currentOptionRequired="${PARAMS["$1.$currentOption.required"]}"
   if -eq flag "$currentOptionType"
   then
      optionUsageText="$currentOptionSwitch"
   elif -eq value "$currentOptionType"
   then
      optionUsageText="$currentOptionSwitch <value>"
   elif -eq list "$currentOptionType"
   then
      optionUsageText="$currentOptionSwitch <value> [...]"
   fi

   currentOptionDescription="${PARAMS["$1.$currentOption.desc"]}"
   if -true "$currentOptionRequired"
   then
      currentOptionDescription="REQUIRED. $currentOptionDescription"
   fi
   _modifyCurrentOptionDescription $1

   printf "  %-30s   %s\n" "$optionUsageText" "$currentOptionDescription"
}

function _modifyCurrentOptionDescription() {
   local currentOptionDefault="${PARAMS["$1.$currentOption.default"]}"
   if -n "$currentOptionDefault"
   then
      currentOptionDescription="${currentOptionDescription%.}. Default is: '$currentOptionDefault'"
   fi
}

### PRINT PARAMS ###

function printArgs() {
   local value

   for currentOption in MAIN ${PARAMS["$1.ARGS"]}
   do
      eval 'value=( "${'"$currentOption"'[*]}" )'
      if -n "${value[@]}"
      then
         printf "%16s: %s\n" "$currentOption" "'${value[@]}'"
      fi
   done
}

PARAMS=(
    [param.DESC]='Adds a parameter definition for an executable.'
    [param.ARGS]='param name required default type desc comp isValue'
    [param.MAIN.desc]='Parameter ID. getArgs() creates variable with this name so it should be valid bash var id.'
    [param.MAIN.required]='yes'
    [param.isValue.desc]='If specified, allows providing option without value but when value is provided, var with this name is set to 1.'
    [param.isValue.name]='is-value'
    [param.name.desc]='Use this option if you want --parameter-name to be different from its ID.'
    [param.required.desc]='Specify this flag when parameter is mandatory.'
    [param.required.type]='flag'
    [param.default.desc]='Default value to use for the parameter when user does not provide one.'
    [param.type.desc]='No value means that the parameter is a flag. "1" means parameter has a value. "n" means multiple values.'
    [param.type.default]='value'
    [param.type.comp]='flag value list'
    [param.desc.desc]='Description displayed in --help mode.'
    [param.comp.desc]='Values for autocompletion or "fun()" - name of function printing such space-separated values or -f file or -d dir completion.'
    [param.comp.type]='list'
    [params-for.DESC]='Initializes autocompletion for executable of given name.'
    [params-for.ARGS]='desc'
    [params-for.MAIN.desc]='Name of executable to initialize.'
    [params-for.MAIN.required]='yes'
    [params-for.desc.desc]='General description displayed in --help mode.'
)

function param() {
    : "${PARAMS_CURRENT_DEF?'Invoke params-for first to add parameter definition'}"
    local MAIN name required default type desc comp isValue
    if getArgs ${FUNCNAME[0]} "$@"
    then
       -n "$required" && PARAMS["$PARAMS_CURRENT_DEF.$MAIN.required"]="$required"
       -n "$default" && PARAMS["$PARAMS_CURRENT_DEF.$MAIN.default"]="$default"
       -n "$type" && PARAMS["$PARAMS_CURRENT_DEF.$MAIN.type"]="$type"
       -n "$desc" && PARAMS["$PARAMS_CURRENT_DEF.$MAIN.desc"]="$desc"
       -n "$comp" && PARAMS["$PARAMS_CURRENT_DEF.$MAIN.comp"]="${comp[@]}"
       -n "$name" && PARAMS["$PARAMS_CURRENT_DEF.$MAIN.name"]="$name"
       -n "$isValue" && PARAMS["$PARAMS_CURRENT_DEF.$MAIN.isValue"]="$isValue"
       [ "$MAIN" != MAIN ] && ! [[ " ${PARAMS["$PARAMS_CURRENT_DEF.ARGS"]} " =~ " MAIN " ]] && PARAMS["$PARAMS_CURRENT_DEF.ARGS"]+="$MAIN "
    else
        return 1
    fi
}

function params-for() {
    local MAIN desc
    getArgs ${FUNCNAME[0]} "$@" && {
        PARAMS_CURRENT_DEF="$MAIN"
        -n "$desc" && PARAMS["$PARAMS_CURRENT_DEF.DESC"]="$desc"
    }
}

function params-end() {
    _enableAutocompletion $PARAMS_CURRENT_DEF
    PARAMS_CURRENT_DEF=
}

params-for params-end --desc 'Initializes autocompletion for executable of given name.'

# TODO add --value: int dir file... validate & completion --validator function

function params-demo() {
   params-for greet --desc 'Demo for params.sh'
   param MAIN --desc 'Greeting phrase.' --name phrase --comp hello salut privet ciao czesc ahoj --default Hello
   param times --desc 'How many times to greet.' --is-value isTimes --default 10
   param loud --desc 'Whether to put exclamation mark.' --type flag
   param persons --desc 'Who to greet.' --type list --comp 'getNames()' --required
   params-end

   function getNames() { # example function for autocompletion
      echo john bob alice world
   }

   function greet() {
      local MAIN persons loud times isTimes
      if getArgs greet "$@" # quote $@ to properly handle arguments with spaces
      then
         printArgs greet # for debugging

         echo "<$isTimes>"

         for (( i = 0; i < times; i++ )) { # custom logic start
            echo "$MAIN ${persons[@]}${loud:+!!}"
         } # custom logic end
      else
         return 1
      fi
   }

   echo -e "Execute:\n  declare -f params-demo\n  greet --help\nPlay with autocompletion by pressing <tab> while providing parameters for 'greet' command."
}

$BUSH_ASSOC PARAMS
