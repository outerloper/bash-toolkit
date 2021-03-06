#!/bin/bash

bt-require utils.sh

### SETTINGS ###

PARAMS_DEF_CURRENT=
PARAMS_HELP_IN_AUTOCOMPLETION=yes
PARAMS_OPTION_DECL_COLUMNS=24
PARAMS_OPTION_DESC_INDENT=2
PARAMS_OPTION_DECL_INDENT="$(printf "%$((PARAMS_OPTION_DECL_COLUMNS + PARAMS_OPTION_DESC_INDENT))s" ' ')"

$BT_GLOBAL_ASSOC PARAM_DEFS


# Usage example. Execute this function to try out. Then:
# 1. To see how help is generated, execute: hello --help
# 2. To see how autocompletion works: Type 'hello' in command line and provide parameters to it helping yourself with <tab> key
# 3. To see get-args and print-args functions in action execute command from 3.
params-demo() {

   getNames() {
      echo Bob Alice World
   }
   params-for hello --desc 'Prints PHRASE in the way specified with OPTIONS.'
   param MAIN --name phrase --comp hello salut privet ciao czesc ahoj --default hello
   param persons --desc 'Who to greet.' --type list --comp 'getNames()' --required
   param times --desc 'How many times to greet.' --is-val isTimes --val-type 'int --min 0 --max 10' --default 3
   param loud --desc 'Whether to double exclamation mark.' --type flag
   params-end
   hello() {
       local phrase persons loud times isTimes
       get-args "$@" || return 1

       print-args
       for (( i = 0; i < times; i++ )) {
           var-capitalize phrase
           echo "$phrase ${persons[@]}!${loud:+!}"
       }
   }
}

# Usage (inside a function): get-args "$@"
# Validates parameters provided to a function and, if valid, populates variables with values or: prints help if --help option was provided.
# Returns non-zero code if parameters are invalid or help was requested. In such case function should return immediately.
get-args() {
   local paramsName="${FUNCNAME[1]}"
   local args=( "$@" )
   _params_isHelpRequest $paramsName && return 127

   declare -A unusedParams
   declare -A paramSwitches
   _params_loadDefinition $paramsName

   local currentParamArgsCount=0
   local currentParamType
   local paramSwitch
   local first=1
   local currentParam
   local currentParamVar
   local discardParam=''
   local resultCode=0
   declare -A usedParams=()
   _params_prepareForGetArgs MAIN
   for arg in "${args[@]}"
   do
      if matches "$arg" '--*'
      then
         _params_handleSwitch
      else
         _params_handleValue
      fi
      first=''
   done
   _params_handleSwitchWithoutValues $paramsName
   _params_handleUnused $paramsName
   return $resultCode
}

# Usage (inside a function): print-args
# Function for debugging purposes to print variables set before by get-args
print-args() {
    local value paramsName="${FUNCNAME[1]}" var vars=()

    for currentParam in MAIN ${PARAM_DEFS["$paramsName.LIST"]}
    do
        var="${PARAM_DEFS["$paramsName.$currentParam.name"]}"
        if -n "$var"
        then
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

# Starts parameters definition for a function. Invoke "params-for --help" and "param --help" for more information.
params-for() {
    local 'function' desc
    get-args "$@" && {
        PARAMS_DEF_CURRENT="$function"
        PARAM_DEFS["$PARAMS_DEF_CURRENT.LIST"]=
        -n "$desc" && PARAM_DEFS["$PARAMS_DEF_CURRENT.DESC"]="$desc"
    }
}

# Defines parameter for a function. Invoke "param --help" for more information.
param() {
    : "${PARAMS_DEF_CURRENT?'Invoke params-for first to add parameter definition'}"
    local parameter name required default type valType desc comp isVal
    if get-args "$@"
    then
        -n "$required" && PARAM_DEFS["$PARAMS_DEF_CURRENT.$parameter.required"]="$required"
        -n "$default" && PARAM_DEFS["$PARAMS_DEF_CURRENT.$parameter.default"]="$default"
        -n "$desc" && PARAM_DEFS["$PARAMS_DEF_CURRENT.$parameter.desc"]="$desc"
        -n "$comp" && PARAM_DEFS["$PARAMS_DEF_CURRENT.$parameter.comp"]="${comp[@]}"
        -z "$name" && -eq "$parameter" MAIN && err 'MAIN parameter must have name specified.' && return 1
        -n "$name" && PARAM_DEFS["$PARAMS_DEF_CURRENT.$parameter.name"]="$name"
        -n "$isVal" && PARAM_DEFS["$PARAMS_DEF_CURRENT.$parameter.is-val"]="$isVal"
        -n "$type" && PARAM_DEFS["$PARAMS_DEF_CURRENT.$parameter.type"]="$type"
        -n "$valType" && PARAM_DEFS["$PARAMS_DEF_CURRENT.$parameter.val-type"]="$valType"
        ! -eq "$parameter" MAIN && ! contains " ${PARAM_DEFS["$PARAMS_DEF_CURRENT.LIST"]} " " MAIN " && PARAM_DEFS["$PARAMS_DEF_CURRENT.LIST"]+="$parameter "
    else
        return 1
    fi
}

# Invoke immediately after all parameters for a function are defined. Invoke "param --help" for more information
params-end() {
    -z "${PARAM_DEFS["$PARAMS_DEF_CURRENT.MAIN.name"]}" && {
        PARAM_DEFS["$PARAMS_DEF_CURRENT.MAIN.type"]=flag
    }
    _params_enableAutocompletion $PARAMS_DEF_CURRENT
    PARAMS_DEF_CURRENT=
}


### UTILS ###

_params_loadDefinition() {
   local currentParamSwitch
   for currentParam in ${PARAM_DEFS["$1.LIST"]}
   do
      currentParamSwitch="--$currentParam"
      paramSwitches[$currentParamSwitch]="$currentParam"
      unusedParams[$currentParam]="$currentParamSwitch"
   done
}

### AUTOCOMPLETION ###

_params_enableAutocompletion() {
   local fn="__paramsComp_$1"
   complete -F "$fn" "$1"
   eval $fn'() { _params_autocompletion '$1' 1; }'
}

_params_autocompletion() {
   local completedArgsCount
   (( completedArgsCount = COMP_CWORD - 1 )) || true
   local currentWord="${COMP_WORDS[COMP_CWORD]}"
   local suggestions=()
   local currentParam=MAIN
   local currentParamArgsCount=0
   local args=()

   args=( ${COMP_WORDS[@]:1:$completedArgsCount} )
   declare -A unusedParams=()
   declare -A paramSwitches=()
   _params_loadDefinition $1

   currentParam=MAIN
   currentParamArgsCount=0
   _params_prepareForAutocompletion

   _params_getSuggestions $1
   COMPREPLY=( $(compgen -W "${suggestions[*]}" -- $currentWord) ) || true
   is "$PARAMS_HELP_IN_AUTOCOMPLETION" && (( ${#COMPREPLY[@]} > 1 )) && _params_displayHelpInAutocompletion $1 "$currentWord" || true
}

_params_prepareForAutocompletion() {
   for arg in ${args[@]}
   do
      if matches "$arg" '--*'
      then
         currentParam="${paramSwitches[$arg]}"
         -n "$currentParam" && unset "unusedParams[$currentParam]"
         currentParamArgsCount=0
      else
         var-inc currentParamArgsCount
      fi
   done
}

_params_getSuggestions() {
   local currentParamType="${PARAM_DEFS["$1.$currentParam.type"]}"
   local currentParamRequired="${PARAM_DEFS["$1.$currentParam.required"]}"
   local currentParamIsVal="${PARAM_DEFS["$1.$currentParam.is-val"]}"
   local currentParamCompletion
   suggestions=( '–—' '—–' )
   if -eq MAIN "$currentParam" && ! is "$currentParamRequired" || -eq flag "$currentParamType" || ! -0 "$currentParamArgsCount" || -n "$currentParamIsVal"
   then
      suggestions=( "${suggestions[@]}" ${unusedParams[@]} )
   fi
   if ! -eq flag "$currentParamType" && -0 "$currentParamArgsCount" || -eq list "$currentParamType"
   then
      currentParamCompletion="${PARAM_DEFS["$1.$currentParam.comp"]}"
      suggestions=( "${suggestions[@]}" "$(_params_generateSuggestions)" )
   fi
}

_params_generateSuggestions() {
   if -z "$currentParamCompletion"
   then
      :
   elif matches-regex "$currentParamCompletion" '[a-zA-Z_-][0-9a-zA-Z_-]*\(\)'
   then
      compgen -F "${currentParamCompletion//()}" 2>/dev/null
   elif matches-regex "$currentParamCompletion" '-f|-d'
   then
      compgen "$currentParamCompletion"
   else
      compgen -W "$currentParamCompletion"
   fi || true
}

_params_displayHelpInAutocompletion() {
    local param="$currentParam"
    -eq "$2" -- && param="$2"
    local help="$(_params_printHelp "$1" "$param")"
    -n "$help" && echo -en "\n$help\n" >&2
}

### CAPTURING PARAMETER VALUES ###

_params_isHelpRequest() {
   for arg in ${args[@]}
   do
      if -eq --help "$arg"
      then
         _params_printHelp $1
         return 0
      fi
   done
   return 1
}

_params_handleSwitch() {
   _params_handleSwitchWithoutValues $paramsName
   paramSwitch="$arg"
   _params_prepareForGetArgs ${paramSwitches[$paramSwitch]}
   -n $currentParam && unset "unusedParams[$currentParam]"
   if -n "${usedParams[$paramSwitch]}"
   then
      err "Duplicate usage of $paramSwitch"
      discardParam=1
      resultCode=1
   fi
   usedParams[$paramSwitch]=1
}

_params_handleValue() {
    if -n $discardParam
    then
       return 1;
    fi
    if -eq flag "$currentParamType"
    then
        err "Unexpected value: $arg"
        resultCode=1
    else
        if ! -eq list "$currentParamType" && ! -0 $currentParamArgsCount
        then
            err "Unexpected value: $arg"
            resultCode=1
        else
            local currentParamValType="${PARAM_DEFS["$paramsName.$currentParam.val-type"]}"
            -n "$currentParamValType" && {
                local valSpec="$(sed 's/ / arg /' <<<"$currentParamValType"" ")"
                eval "ask-for $valSpec <<<'$arg' >/dev/null" || {
                    err "${paramSwitch:-"${currentParamVar^^}"}: $VALUE_ERROR"
                    resultCode=1
                }
            }
            var-set "$currentParamVar[$currentParamArgsCount]" "$arg"
        fi
    fi
    var-inc currentParamArgsCount
}

_params_prepareForGetArgs() {
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
          var-set $currentParamIsVal 1
      }
   else
      err "No such option: $paramSwitch"
      discardParam=1
      resultCode=1
   fi
}

_params_handleSwitchWithoutValues() {
   if (( currentParamArgsCount == 0 ))
   then
      if ! -eq flag "$currentParamType"
      then
         if -n $first
         then
            _params_handleMissingMainArg "$1"
         elif -n $currentParamIsVal
         then
            -n "$currentParamDefault" && var-set $currentParamVar "$currentParamDefault"
         else
            -z $discardParam && err "Missing required value for $paramSwitch"
            resultCode=1
         fi
      elif ! -eq MAIN "$currentParam" # if flag, assign 1 to value
      then
         unset "$currentParamVar"
         -z $discardParam && var-set $currentParamVar 1
      fi
   fi
}

_params_handleMissingMainArg() {
   unset "$currentParamVar"
   local currentParamRequired="${PARAM_DEFS["$1.$currentParam.required"]}"
   if is "$currentParamRequired"
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
         var-set $currentParamVar "$currentParamDefault"
      fi
   fi
}

_params_handleUnused() {
    for currentParam in ${!unusedParams[@]}
    do
        local paramRequired="${PARAM_DEFS["$1.$currentParam.required"]}"
        if is "$paramRequired"
        then
            err "Missing mandatory option: ${unusedParams[$currentParam]}"
            resultCode=1
        else
            local currentParamVar="${PARAM_DEFS["$1.$currentParam.name"]}"
            -z "$currentParamVar" && currentParamVar="$currentParam"
            var-set $currentParamVar ''
            local currentParamDefault="${PARAM_DEFS["$1.$currentParam.default"]}"
            -n "$currentParamDefault" && var-set $currentParamVar $currentParamDefault
        fi
    done
}

### PRINT HELP ###

_params_printHelp() {
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

    _params_printUsage $1
    -n "$helpDescription" && {
        if (( ${#helpDescription} >= "${COLUMNS-$(tput cols)}" ))
        then
            fmt -s -w "$COLUMNS" <<<"$helpDescription"
        else
            echo "$helpDescription"
        fi
    }
    -n "$printOnly" && echo
    -z "$printOnly" || -eq "$printOnly" MAIN && ! -eq flag "$currentParamType" && {
        _params_modifyOptionDescription $1
        -n "$currentParamDescription" || -eq MAIN "$printOnly" && _params_printOptionDescription "${currentParamName^^}" "$currentParamDescription"
    }
    -n "${PARAM_DEFS["$1.LIST"]}" && {
        -z "$printOnly" && echo "Options:"
        -eq "$printOnly" -- && printOnly=
        for currentParam in ${PARAM_DEFS["$1.LIST"]}
        do
            if ! -eq "$currentParam" MAIN && { -z "$printOnly" || -eq "$printOnly" "$currentParam" ;}
            then
                _params_printOptionHelp $1
            fi
        done
    }
}

_params_printUsage() {
   printf "Usage: $scriptNameForHelp"
   if ! -eq flag "$currentParamType"
   then
      local paramUsageText=""
      if -eq list "$currentParamType"
      then
         paramUsageText="${currentParamName^^}..."
      else
         paramUsageText="${currentParamName^^}"
      fi
      if ! is "$currentParamRequired"
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

_params_printOptionHelp() {
    local currentParamSwitch="--$currentParam"
    currentParamType="${PARAM_DEFS["$1.$currentParam.type"]}"
    currentParamRequired="${PARAM_DEFS["$1.$currentParam.required"]}"
    currentParamName="${PARAM_DEFS["$1.$currentParam.name"]}"
    currentParamIsVal="${PARAM_DEFS["$1.$currentParam.is-val"]}"
    -z "$currentParamName" && currentParamName="$currentParam"
    paramUsageText="$currentParamSwitch"
    if ! -eq flag "$currentParamType"
    then
        local optionValue="${currentParamName^^}"
        -eq "$currentParamType" list && optionValue+="..."
        -n "$currentParamIsVal" && optionValue="[$optionValue]"
        paramUsageText+=" $optionValue"
    fi

    currentParamDescription="${PARAM_DEFS["$1.$currentParam.desc"]}"
    if is "$currentParamRequired"
    then
        currentParamDescription="REQUIRED. $currentParamDescription"
    fi
    _params_modifyOptionDescription $1

    _params_printOptionDescription "$paramUsageText" "$currentParamDescription"
}

_params_printOptionDescription() {
    local optionDecl="  $1  " optionDesc="$2" optionDeclOverflow
    if (( ${#optionDecl} > PARAMS_OPTION_DECL_COLUMNS))
    then
        local tmp="$optionDecl"
        optionDecl="${tmp:0:$((PARAMS_OPTION_DECL_COLUMNS))}"
        optionDeclOverflow="${tmp:$((PARAMS_OPTION_DECL_COLUMNS))}"
    fi
    if (( PARAMS_OPTION_DECL_COLUMNS + ${#optionDeclOverflow} + ${#optionDesc} >= COLUMNS )) && (( PARAMS_OPTION_DECL_COLUMNS + 36 < COLUMNS ))
    then
        printf "%-$((PARAMS_OPTION_DECL_COLUMNS))s" "$optionDecl"
        fmt -s -w "$(( COLUMNS - PARAMS_OPTION_DECL_COLUMNS - PARAMS_OPTION_DESC_INDENT ))" <<<"$optionDeclOverflow$optionDesc" | sed "2,$ s/^/$PARAMS_OPTION_DECL_INDENT/"
    else
        printf "%-$((PARAMS_OPTION_DECL_COLUMNS))s%s\n" "$optionDecl" "$optionDeclOverflow$optionDesc"
    fi
}

_params_modifyOptionDescription() {
    local currentParamDefault="${PARAM_DEFS["$1.$currentParam.default"]}"
    if -n "$currentParamDefault"
    then
        -n "$currentParamDescription" && currentParamDescription="${currentParamDescription%.}. "
        currentParamDescription="$currentParamDescription""Default is: '$currentParamDefault'."
    fi
}


### INITIALIZATION ###

PARAM_DEFS=(
    [param.DESC]='Adds a named PARAMETER for a function which can be then provided from command line with --PARAMETER switch. First "params-for FUN" must be invoked where FUN is the function name. After all parameters are defined, invoke "params-end".'
    [param.LIST]='name required default type desc comp is-val val-type'
    [param.MAIN.name]='parameter'
    [param.MAIN.required]='yes'
    [param.is-val.desc]='If specified, allows providing param without value but when value is provided, var with this name is set to 1.'
    [param.is-val.name]='isVal'
    [param.name.desc]='Name of variable corresponding to this --PARAMETER. Default is PARAMETER.'
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
    [params-for.desc.desc]='General description for a function displayed in --help mode.'
)

_params_enableAutocompletion param
_params_enableAutocompletion params-for
params-for params-end --desc 'Initializes autocompletion for executable of given name.'
params-end
