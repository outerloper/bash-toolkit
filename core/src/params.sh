#!/bin/bash

require utils.sh

### SETTINGS ###

PARAM_DEF_CURRENT=
PARAM_DEFS_DISPLAY_INSTANT_HELP=yes

### UTILS ###

function _prepareProcessingArgs() {
   local currentParamSwitch
   for currentParam in ${PARAM_DEFS["$1.LIST"]}
   do
      _setCurrentParamSwitch $1
      paramSwitches[$currentParamSwitch]="$currentParam"
      unusedParams[$currentParam]="$currentParamSwitch"
   done
}

function _setCurrentParamSwitch() {
   if -n ${PARAM_DEFS["$1.$currentParam.name"]}
   then
      currentParamSwitch="--${PARAM_DEFS["$1.$currentParam.name"]}"
   else
      currentParamSwitch="--$currentParam"
   fi
}

function _extractArgs() {
    args=( "$@" )
}

### AUTOCOMPLETION ###

function _enableAutocompletion() {
   local fn="__paramsComp_$1"
   complete -F "$fn" "$1"
   eval $fn'() { _argsAutocompletion '$1' 1; }'
}

function _argsAutocompletion() {
   local completedArgsCount
   (( completedArgsCount = COMP_CWORD - 1 ))
   local currentWord="${COMP_WORDS[COMP_CWORD]}"
   local compReply=()
   local currentParam=MAIN
   local currentParamArgsCount=0
   local args=()
   _extractArgs "${COMP_WORDS[@]:1:$completedArgsCount}"
   _getCompletion $1
   COMPREPLY=( $(compgen -W "${compReply[*]}" -- $currentWord) )
   -true "$PARAM_DEFS_DISPLAY_INSTANT_HELP" && (( ${#COMPREPLY[@]} > 1 )) && _displayInstantHelp $1 "$currentWord"
}

function _getCompletion() {
   declare -A unusedParams=()
   declare -A paramSwitches=()
   _prepareProcessingArgs $1

   currentParam=MAIN
   currentParamArgsCount=0
   _processArgsForCompletion

   _generateCompletions $1
}

function _processArgsForCompletion() {
   for arg in ${args[@]}
   do
      if -has "$arg" '--*'
      then
         currentParam="${paramSwitches[$arg]}"
         -n "$currentParam" && unset "unusedParams[$currentParam]"
         currentParamArgsCount=0
      else
         (( currentParamArgsCount++ ))
      fi
   done
}

function _generateCompletions() {
   local currentParamType="${PARAM_DEFS["$1.$currentParam.type"]}"
   local currentParamRequired="${PARAM_DEFS["$1.$currentParam.required"]}"
   local currentParamIsValue="${PARAM_DEFS["$1.$currentParam.isValue"]}"
   local currentParamCompletion
   compReply=( '–—' '—–' )
   if -eq MAIN "$currentParam" && -false "$currentParamRequired" || -eq flag "$currentParamType" || -gt "$currentParamArgsCount" 0 || -n "$currentParamIsValue"
   then
      compReply=( "${compReply[@]}" ${unusedParams[@]} )
   fi
   if -neq flag "$currentParamType" && -eq "$currentParamArgsCount" 0 || -eq list "$currentParamType"
   then
      currentParamCompletion="${PARAM_DEFS["$1.$currentParam.comp"]}"
      compReply=( "${compReply[@]}" "$(_evaluateCompletion)" )
   fi
}

function _evaluateCompletion() {
   if -z "$currentParamCompletion"
   then
      :
   elif -rlike "$currentParamCompletion" '[a-Z_-][0-Z_-]*\(\)'
   then
      compgen -F "${currentParamCompletion//()}" 2>/dev/null
   elif -rlike "$currentParamCompletion" '-f|-d'
   then
      compgen "$currentParamCompletion"
   else
      compgen -W "$currentParamCompletion"
   fi
}

function _displayInstantHelp() {
    local param="$currentParam"
    -eq "$2" -- && param="$2"
    local help="$(printHelp "$1" "$param")"
    -n "$help" && echo -en "\n$help\n" >&2
}
### GET ARGS ###

function getArgs() {
   local paramsName=$1
   shift
   local args=( "$@" )
   _isHelpRequest $paramsName && return 127

   declare -A unusedParams
   declare -A paramSwitches
   _prepareProcessingArgs $paramsName

   local currentParamArgsCount=0
   local currentParamType
   local paramSwitch
   local first=1
   local currentParam
   local discardParam=''
   local resultCode=0
   declare -A usedParams=()
   _initParamForGetArgs MAIN
   for arg in "${args[@]}"
   do
      if -has "$arg" '--*'
      then
         _handleParamSwitch
      else
         _handleParamParam
      fi
      first=''
   done
   _handleParamWithoutArgs $paramsName
   _handleUnusedParams $paramsName
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

function _handleParamSwitch() {
   _handleParamWithoutArgs $paramsName
   paramSwitch="$arg"
   _initParamForGetArgs ${paramSwitches[$paramSwitch]}
   -n $currentParam && unset "unusedParams[$currentParam]"
   if -n "${usedParams[$paramSwitch]}"
   then
      stderr "Duplicate usage of $paramSwitch"
      discardParam=1
      resultCode=1
   fi
   usedParams[$paramSwitch]=1
}

function _handleParamParam() { # TODO ParamValue
   if -n $discardParam
   then
      return 1;
   fi
   if -eq flag "$currentParamType"
   then
      stderr "Unexpected value: $arg"
      resultCode=1
   else
      if -neq list "$currentParamType" && -gz $currentParamArgsCount
      then
         stderr "Unexpected value: $arg"
         resultCode=1
      else
         set-var "$currentParam[$currentParamArgsCount]" "$arg"
      fi
   fi
   (( ++currentParamArgsCount ))
}

function _initParamForGetArgs() {
   currentParam="$1"
   currentParamArgsCount=0
   currentParamType="${PARAM_DEFS["$paramsName.$currentParam.type"]}"
   currentParamIsValue="${PARAM_DEFS["$paramsName.$currentParam.isValue"]}"
   currentParamDefault="${PARAM_DEFS["$paramsName.$currentParam.default"]}"
   if -n "$currentParam"
   then
      unset "$currentParam"
      eval $currentParam'=()'
      discardParam=''
      -n "$currentParamIsValue" && {
          unset "$currentParamIsValue"
          set-var $currentParamIsValue 1
      }
   else
      stderr "Unknown param: $paramSwitch"
      discardParam=1
      resultCode=1
   fi
}

function _handleParamWithoutArgs() {
   if (( currentParamArgsCount == 0 ))
   then
      if -neq flag "$currentParamType"
      then
         if -n $first
         then
            _handleMissingMainArg $1
         elif -n $currentParamIsValue ;then
            -n "$currentParamDefault" && set-var $currentParam "$currentParamDefault"
         else
            -z $discardParam && stderr "Missing required value for $paramSwitch"
            resultCode=1
         fi
      elif -neq MAIN "$currentParam" # if flag, assign 1 to value
      then
         unset $currentParam
         -z $discardParam && set-var $currentParam "1"
      fi
   fi
}

function _handleMissingMainArg() {
   unset $currentParam
   local currentParamRequired="${PARAM_DEFS["$1.$currentParam.required"]}"
   if -true "$currentParamRequired"
   then
      local currentParamName="${PARAM_DEFS["$1.$currentParam"]}"
      currentParamName="${currentParamName:-MAIN parameter}"
      stderr "Missing $currentParamName."
      resultCode=1
   else
      local currentParamDefault="${PARAM_DEFS["$1.$currentParam.default"]}"
      if -n "$currentParamDefault"
      then
         set-var $currentParam "$currentParamDefault"
      fi
   fi
}

function _handleUnusedParams() {
   for currentParam in ${!unusedParams[@]}
   do
      paramRequired="${PARAM_DEFS["$1.$currentParam.required"]}"
      if -true "$paramRequired"
      then
         stderr "Missing mandatory ${unusedParams[$currentParam]}"
         resultCode=1
      else
         set-var $currentParam ''
         currentParamDefault="${PARAM_DEFS["$1.$currentParam.default"]}"
         -n "$currentParamDefault" && set-var $currentParam $currentParamDefault
      fi
   done
}

### PRINT HELP ###

function printHelp() {
    local paramUsageText

    local currentParam=MAIN
    local currentParamName="${PARAM_DEFS["$1.$currentParam.name"]}"
    currentParamName="${currentParamName:-MAIN}"
    local currentParamDescription="${PARAM_DEFS["$1.$currentParam.desc"]}"
    local currentParamType="${PARAM_DEFS["$1.$currentParam.type"]}"
    local currentParamRequired="${PARAM_DEFS["$1.$currentParam.required"]}"
    local scriptNameForHelp="${PARAM_DEFS["$1"]}"
    local scriptNameForHelp="${scriptNameForHelp:-$1}"
    local helpDescription="${PARAM_DEFS["$1.DESC"]}"
    local printOnly="$2"
    local helpFormat="  %-22s   %s\n"

    _printUsage $1
    -n "$helpDescription" && {
        echo "$helpDescription"
    }
    -n "$printOnly" && echo
    -z "$printOnly" || -eq "$printOnly" MAIN && -neq flag "$currentParamType" && {
        _modifyParamDescription $1
        -n "$currentParamDescription" && printf "$helpFormat" "${currentParamName^^}" "$currentParamDescription"
    }
    -n "${PARAM_DEFS["$1.LIST"]}" && {
        -z "$printOnly" && echo "Options:"
        -eq "$printOnly" -- && printOnly=
        for currentParam in ${PARAM_DEFS["$1.LIST"]}
        do
            if -neq "$currentParam" MAIN && { -z "$printOnly" || -eq "$printOnly" "$currentParam" ;}
            then
                _printParamHelp $1
            fi
        done
    }
}

function _printUsage() {
   printf "Usage: $scriptNameForHelp"
   if -neq flag "$currentParamType"
   then
      local paramUsageText=""
      if -eq list "$currentParamType"
      then
         paramUsageText="${currentParamName^^}..."
      else
         paramUsageText="${currentParamName^^}"
      fi
      if -false "$currentParamRequired"
      then
         paramUsageText="[$paramUsageText]"
      fi
      printf " $paramUsageText"
   fi
   if -n "${PARAM_DEFS["$1.LIST"]}"
   then
      printf " OPTIONS..."
   fi
   echo
}

function _printParamHelp() {
   local currentParamSwitch
   _setCurrentParamSwitch $1
   currentParamType="${PARAM_DEFS["$1.$currentParam.type"]}"
   currentParamRequired="${PARAM_DEFS["$1.$currentParam.required"]}"
   if -eq flag "$currentParamType"
   then
      paramUsageText="$currentParamSwitch"
   elif -eq list "$currentParamType"
   then
      paramUsageText="$currentParamSwitch ${currentParam^^}..."
   else
      paramUsageText="$currentParamSwitch ${currentParam^^}"
   fi

   currentParamDescription="${PARAM_DEFS["$1.$currentParam.desc"]}"
   if -true "$currentParamRequired"
   then
      currentParamDescription="REQUIRED. $currentParamDescription"
   fi
   _modifyParamDescription $1

   printf "$helpFormat" "$paramUsageText" "$currentParamDescription"
}

function _modifyParamDescription() {
    local currentParamDefault="${PARAM_DEFS["$1.$currentParam.default"]}"
    if -n "$currentParamDefault"
    then
        -n "$currentParamDescription" && currentParamDescription="${currentParamDescription%.}. "
        currentParamDescription="$currentParamDescription""Default is: '$currentParamDefault'."
    fi
}

### PRINT PARAMS ###

function printArgs() {
   local value

   for currentParam in MAIN ${PARAM_DEFS["$1.LIST"]}
   do
      eval 'value=( "${'"$currentParam"'[*]}" )'
      if -n "${value[@]}"
      then
         printf "%16s: %s\n" "$currentParam" "'${value[@]}'"
      fi
   done
}

PARAM_DEFS=(
    [param.DESC]='Adds a PARAMETER definition for an executable.'
    [param.LIST]='name required default type desc comp isValue'
    [param.MAIN.name]='parameter'
    [param.MAIN.required]='yes'
    [param.isValue.desc]='If specified, allows providing param without value but when value is provided, var with this name is set to 1.'
    [param.isValue.name]='is-value'
    [param.name.desc]='Use this param if you want parameter switch name to be different from its ID.'
    [param.required.desc]='Specify this flag when parameter is mandatory.'
    [param.required.type]='flag'
    [param.default.desc]='Default value to use for the parameter when user does not provide one.'
    [param.type.desc]='One of: flag, value, list.'
    [param.type.default]='value'
    [param.type.comp]='flag value list'
    [param.desc.desc]='Description for --help mode.'
    [param.comp.desc]='Values for autocompletion or "fun()": name of function printing such space-separated values or "-f": file or "-d": dir completion.'
    [param.comp.type]='list'
    [params-for.DESC]='Starts parameter definitions for FUNCTION.'
    [params-for.LIST]='desc'
    [params-for.MAIN.name]='function'
    [params-for.MAIN.required]='yes'
    [params-for.desc.desc]='General description displayed in --help mode.'
)

function param() {
    : "${PARAM_DEF_CURRENT?'Invoke params-for first to add parameter definition'}"
    local MAIN param name required default type desc comp isValue
    if getArgs ${FUNCNAME[0]} "$@"
    then
        param="$MAIN"
       -n "$required" && PARAM_DEFS["$PARAM_DEF_CURRENT.$param.required"]="$required"
       -n "$default" && PARAM_DEFS["$PARAM_DEF_CURRENT.$param.default"]="$default"
       -n "$desc" && PARAM_DEFS["$PARAM_DEF_CURRENT.$param.desc"]="$desc"
       -n "$comp" && PARAM_DEFS["$PARAM_DEF_CURRENT.$param.comp"]="${comp[@]}"
       -z "$name" && -eq "$param" MAIN && stderr 'MAIN parameter must have name specified.' && return 1
       -n "$name" && PARAM_DEFS["$PARAM_DEF_CURRENT.$param.name"]="$name"
       -n "$isValue" && PARAM_DEFS["$PARAM_DEF_CURRENT.$param.isValue"]="$isValue"
       -n "$type" && PARAM_DEFS["$PARAM_DEF_CURRENT.$param.type"]="$type"
       -neq "$param" MAIN && ! -has " ${PARAM_DEFS["$PARAM_DEF_CURRENT.LIST"]} " " MAIN " && PARAM_DEFS["$PARAM_DEF_CURRENT.LIST"]+="$param "
    else
        return 1
    fi
}

function params-for() {
    local MAIN desc
    getArgs ${FUNCNAME[0]} "$@" && {
        PARAM_DEF_CURRENT="$MAIN"
        -n "$desc" && PARAM_DEFS["$PARAM_DEF_CURRENT.DESC"]="$desc"
    }
}

function params-end() {
    -z "${PARAM_DEFS["$PARAM_DEF_CURRENT.MAIN.name"]}" && {
        PARAM_DEFS["$PARAM_DEF_CURRENT.MAIN.type"]=flag
    }
    _enableAutocompletion $PARAM_DEF_CURRENT
    PARAM_DEF_CURRENT=
}

params-for param
params-end
params-for params-for
params-end
params-for params-end --desc 'Initializes autocompletion for executable of given name.'
params-end

# TODO add --value: int dir file... validate & completion --validator function

function params-demo() {

   function getNames() { # example function for autocompletion
      echo john bob alice world
   }

   params-for greet --desc 'Prints PHRASE in the way specified with OPTIONS.'
   param MAIN --name phrase --comp hello salut privet ciao czesc ahoj --default Hello
   param persons --desc 'Who to greet.' --type list --comp 'getNames()' --required
   param times --desc 'How many times to greet.' --is-value isTimes --default 10
   param loud --desc 'Whether to put exclamation mark.' --type flag
   params-end
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
params-demo

$BUSH_ASSOC PARAM_DEFS
