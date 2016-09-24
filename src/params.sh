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
      currentParamSwitch="--$currentParam"
      paramSwitches[$currentParamSwitch]="$currentParam"
      unusedParams[$currentParam]="$currentParamSwitch"
   done
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
      if -like "$arg" '--*'
      then
         currentParam="${paramSwitches[$arg]}"
         -n "$currentParam" && unset "unusedParams[$currentParam]"
         currentParamArgsCount=0
      else
         inc currentParamArgsCount
      fi
   done
}

function _generateCompletions() {
   local currentParamType="${PARAM_DEFS["$1.$currentParam.type"]}"
   local currentParamRequired="${PARAM_DEFS["$1.$currentParam.required"]}"
   local currentParamIsVal="${PARAM_DEFS["$1.$currentParam.is-val"]}"
   local currentParamCompletion
   compReply=( '–—' '—–' )
   if -eq MAIN "$currentParam" && -false "$currentParamRequired" || -eq flag "$currentParamType" || -gz "$currentParamArgsCount" || -n "$currentParamIsVal"
   then
      compReply=( "${compReply[@]}" ${unusedParams[@]} )
   fi
   if -neq flag "$currentParamType" && -ez "$currentParamArgsCount" || -eq list "$currentParamType"
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

function get-args() {
   local paramsName="${FUNCNAME[1]}"
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
   local currentParamVar
   local discardParam=''
   local resultCode=0
   declare -A usedParams=()
   _initParamForGetArgs MAIN
   for arg in "${args[@]}"
   do
      if -like "$arg" '--*'
      then
         _handleParamSwitch
      else
         _handleParamValue
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
      err "Duplicate usage of $paramSwitch"
      discardParam=1
      resultCode=1
   fi
   usedParams[$paramSwitch]=1
}

function _handleParamValue() {
    if -n $discardParam
    then
       return 1;
    fi
    if -eq flag "$currentParamType"
    then
        err "Unexpected value: $arg"
        resultCode=1
    else
        if -neq list "$currentParamType" && -gz $currentParamArgsCount
        then
            err "Unexpected value: $arg"
            resultCode=1
        else
            local currentParamValType="${PARAM_DEFS["$paramsName.$currentParam.val-type"]}"
            -n "$currentParamValType" && {
                local valSpec="$(sed 's/ / arg /' <<<"$currentParamValType"" ")"
                eval "ask-for $valSpec <<<'$arg' >/dev/null" || {
                    err "$paramSwitch: $VALUE_ERROR"
                    resultCode=1
                }
            }
            set-var "$currentParamVar[$currentParamArgsCount]" "$arg"
        fi
    fi
    inc currentParamArgsCount
}

function _initParamForGetArgs() {
   currentParam="$1"
   currentParamArgsCount=0
   currentParamType="${PARAM_DEFS["$paramsName.$currentParam.type"]}"
   currentParamIsVal="${PARAM_DEFS["$paramsName.$currentParam.is-val"]}"
   currentParamDefault="${PARAM_DEFS["$paramsName.$currentParam.default"]}"
   currentParamVar="${PARAM_DEFS["$paramsName.$currentParam.name"]}"
   -z "$currentParamVar" && currentParamVar="$currentParam"

   if -n "$currentParam"
   then
      unset "$currentParamVar"
      eval $currentParamVar'=()'
      discardParam=''
      -n "$currentParamIsVal" && {
          unset "$currentParamIsVal"
          set-var $currentParamIsVal 1
      }
   else
      err "No such option: $paramSwitch"
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
            _handleMissingMainArg "$1"
         elif -n $currentParamIsVal ;then
            -n "$currentParamDefault" && set-var $currentParamVar "$currentParamDefault"
         else
            -z $discardParam && err "Missing required value for $paramSwitch"
            resultCode=1
         fi
      elif -neq MAIN "$currentParam" # if flag, assign 1 to value
      then
         unset "$currentParamVar"
         -z $discardParam && set-var $currentParamVar 1
      fi
   fi
}

function _handleMissingMainArg() {
   unset "$currentParamVar"
   local currentParamRequired="${PARAM_DEFS["$1.$currentParam.required"]}"
   if -true "$currentParamRequired"
   then
      local currentParamName="${PARAM_DEFS["$1.$currentParam.name"]}"
      currentParamName="${currentParamName:-MAIN}"
      currentParamName="${currentParamName^^}"
      err "Missing $currentParamName parameter."
      resultCode=1
   else
      local currentParamDefault="${PARAM_DEFS["$1.$currentParam.default"]}"
      if -n "$currentParamDefault"
      then
         set-var $currentParamVar "$currentParamDefault"
      fi
   fi
}

function _handleUnusedParams() {
    for currentParam in ${!unusedParams[@]}
    do
        local paramRequired="${PARAM_DEFS["$1.$currentParam.required"]}"
        if -true "$paramRequired"
        then
            err "Missing mandatory option: ${unusedParams[$currentParam]}"
            resultCode=1
        else
            local currentParamVar="${PARAM_DEFS["$1.$currentParam.name"]}"
            -z "$currentParamVar" && currentParamVar="$currentParam"
            set-var $currentParamVar ''
            local currentParamDefault="${PARAM_DEFS["$1.$currentParam.default"]}"
            -n "$currentParamDefault" && set-var $currentParamVar $currentParamDefault
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
        -n "$currentParamDescription" || -eq MAIN "$printOnly" && printf "$helpFormat" "${currentParamName^^}" "$currentParamDescription"
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
   local currentParamSwitch="--$currentParam"
   currentParamType="${PARAM_DEFS["$1.$currentParam.type"]}"
   currentParamRequired="${PARAM_DEFS["$1.$currentParam.required"]}"
   currentParamName="${PARAM_DEFS["$1.$currentParam.name"]}"
   -z "$currentParamName" && currentParamName="$currentParam"
   if -eq flag "$currentParamType"
   then
      paramUsageText="$currentParamSwitch"
   elif -eq list "$currentParamType"
   then
      paramUsageText="$currentParamSwitch ${currentParamName^^}..."
   else
      paramUsageText="$currentParamSwitch ${currentParamName^^}"
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

function print-args() {
    local value paramsName="${FUNCNAME[1]}" var vars=()

    for currentParam in MAIN ${PARAM_DEFS["$paramsName.LIST"]}
    do
        var="${PARAM_DEFS["$paramsName.$currentParam.name"]}"
        if -n "$var" ;then
            vars+=( "$var" )
        else
            vars+=( "$currentParam" )
        fi
        var="${PARAM_DEFS["$paramsName.$currentParam.is-val"]}"
        -n "$var" && vars+=( "$var" )
    done
    for currentParam in MAIN "${vars[@]}"
    do
        local cmd='value=( "${'"$currentParam"'[*]}" )'
        eval "$cmd"
        if -n "${value[@]}"
        then
           printf "%10s=%s\n" "$currentParam" "'${value[@]}'"
        fi
    done
}

PARAM_DEFS=(
    [param.DESC]='Adds a PARAMETER definition for an executable.'
    [param.LIST]='name required default type desc comp is-val val-type'
    [param.MAIN.name]='parameter'
    [param.MAIN.required]='yes'
    [param.is-val.desc]='If specified, allows providing param without value but when value is provided, var with this name is set to 1.'
    [param.is-val.name]='isVal'
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
    [param.val-type.desc]='Type of parameter value. Can contain own options when quoted e.g. "int --min 4 --max 10"'
    [param.val-type.name]='valType'
    [params-for.DESC]='Starts parameter definitions for FUNCTION.'
    [params-for.LIST]='desc'
    [params-for.MAIN.name]='function'
    [params-for.MAIN.required]='yes'
    [params-for.desc.desc]='General description displayed in --help mode.'
)

function param() {
    : "${PARAM_DEF_CURRENT?'Invoke params-for first to add parameter definition'}"
    local parameter name required default type valType desc comp isVal
    if get-args "$@"
    then
        -n "$required" && PARAM_DEFS["$PARAM_DEF_CURRENT.$parameter.required"]="$required"
        -n "$default" && PARAM_DEFS["$PARAM_DEF_CURRENT.$parameter.default"]="$default"
        -n "$desc" && PARAM_DEFS["$PARAM_DEF_CURRENT.$parameter.desc"]="$desc"
        -n "$comp" && PARAM_DEFS["$PARAM_DEF_CURRENT.$parameter.comp"]="${comp[@]}"
        -z "$name" && -eq "$parameter" MAIN && err 'MAIN parameter must have name specified.' && return 1
        -n "$name" && PARAM_DEFS["$PARAM_DEF_CURRENT.$parameter.name"]="$name"
        -n "$isVal" && PARAM_DEFS["$PARAM_DEF_CURRENT.$parameter.is-val"]="$isVal"
        -n "$type" && PARAM_DEFS["$PARAM_DEF_CURRENT.$parameter.type"]="$type"
        -n "$valType" && PARAM_DEFS["$PARAM_DEF_CURRENT.$parameter.val-type"]="$valType"
        -neq "$parameter" MAIN && ! -has " ${PARAM_DEFS["$PARAM_DEF_CURRENT.LIST"]} " " MAIN " && PARAM_DEFS["$PARAM_DEF_CURRENT.LIST"]+="$parameter "
    else
        return 1
    fi
}

function params-for() {
    local 'function' desc
    get-args "$@" && {
        PARAM_DEF_CURRENT="$function"
        PARAM_DEFS["$PARAM_DEF_CURRENT.LIST"]=
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

_enableAutocompletion param
_enableAutocompletion params-for
params-for params-end --desc 'Initializes autocompletion for executable of given name.'
params-end

# TODO add --value: int dir file... validate & completion --validator function

function params-demo() {
   echo "Execute: declare -f params-demo"
   echo "Execute: greet --help"
   echo "Play with autocompletion by pressing <tab> while providing parameters for 'hello'."
   function getNames() {
      echo Bob Alice World
   }
   params-for hello --desc 'Prints PHRASE in the way specified with OPTIONS.'
   param MAIN --name phrase --comp hello salut privet ciao czesc ahoj --default hello
   param persons --desc 'Who to greet.' --type list --comp 'getNames()' --required
   param times --desc 'How many times to greet.' --is-val isTimes --val-type 'int --min 0 --max 10' --default 3
   param loud --desc 'Whether to double exclamation mark.' --type flag
   params-end
   function hello() {
       local phrase persons loud times isTimes
       get-args "$@" || return 1
       print-args
       for (( i = 0; i < times; i++ )) {
           capitalize phrase
           echo "$phrase ${persons[@]}!${loud:+!}"
       }
   }
}

$BUSH_ASSOC PARAM_DEFS
