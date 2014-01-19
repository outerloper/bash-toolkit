#!/bin/sh

argComplete() {
   local paramsListRef="${1}"
   local paramList="${!paramsListRef}"
   local wordsCount=$#
   [[ -z "${3}" ]] && (( wordsCount -= 1 )) # if still editing last word, do not count it
   shift
   local args=( ${@} )

   local argNameRef
   local switch
   local optUsagePosition
   local lastUsedOpt
   local lastUsedOptPosition=-1
   local cmpl
   local displayDesc
   local isExplicitOption

   local argsUsed
   local optionsCompletion
   local currentSwitch
   local result

   local first
echo "[$wordsCount]" 1>&2 # DEBUG
   for param in ${paramList[@]} # iterate through all defined options to generate completions
   do
      argNameRef="${paramsListRef}_${param}"
      switch="--${!argNameRef}"
      optUsagePosition=-1
      wordPos=-1
      for arg in ${args[@]} # iterate through all words in command to check if given arg used
      do
         (( wordPos++ ))
         if [[ "${arg}" == "${switch}" ]] # if option used
         then
            optUsagePosition="${wordPos}"
#            if (( wordPos + 1 == wordsCount ))
#            then
#               optionsCompletion+=" ${switch}"
#            fi
            displayDesc=1
            break
         fi
      done
      if [[ "${optUsagePosition}" == -1 ]] # if option not used yet, add it for completion
      then
         optionsCompletion+=" ${switch}"
         displayDesc=1
      elif [[ "${optUsagePosition}" > "${lastUsedOptPosition}" ]]
      then
         lastUsedOptPosition="${optUsagePosition}"
         lastUsedOpt="${param}"
      fi
      [[ -z "${first}" ]] && first=1
   done

   if [[ -z "${lastUsedOpt}" ]] # if no option used explicitly (--optname) yet
   then
      params=( ${paramList} )
      lastUsedOpt=${params}
   else
      isExplicitOption="1"
   fi

   if [[ -n "${lastUsedOpt}" ]] # if some option already used
   then
      argArityRef="${paramsListRef}_${lastUsedOpt}_arity"
      argArity="${!argArityRef}"
      (( argsUsed = wordsCount - lastUsedOptPosition - 1 ))
      if (( argsUsed <= 1 )) && [[ "${argArity}" == "1" ]] || [[ "${argArity}" == "n" ]] # completion for current option depending on param arity
      then
         argCmplRef="${paramsListRef}_${lastUsedOpt}_cmpl"
         result+=" ${!argCmplRef}"
         displayDesc=1
      fi
      argRequiredRef="${paramsListRef}_${lastUsedOpt}_required"
      argRequired="${!argRequiredRef}"
      if [[ "${argRequired}" == "1" ]] && (( argsUsed <= 1 )) && [[ -n "${isExplicitOption}" ]]
      then
         optionsCompletion=" ${lastUsedOpt}"
      fi
   fi
   argDescRef="${paramsListRef}_${lastUsedOpt}_desc"
   if (( lastUsedOptPosition + 1 == wordsCount )) && [[ -n "${!argDescRef}" ]] && [[ -n "${displayDesc}" ]] # print description to stderr
   then
      argNameRef="${paramsListRef}_${lastUsedOpt}"
      switch="--${!argNameRef}"
      echo -en "\n\e[1;30m${switch}: ${!argDescRef}\e[0m" >&2
   fi

   echo "${result}${optionsCompletion}"
}

argParse() {
   local paramListRef="${1}"
   local paramSwitch
   shift
   local paramList=${!paramListRef}
   local args=( ${@} )
   local param
   local arg
   local paramDefaultRef
   local paramDefault
   local paramArityRef
   local paramRequiredRef

   declare -A usedParams
   declare -A unusedParams
   declare -A switches

   for param in ${paramList}
   do
      paramNameRef="${paramListRef}_${param}"
      paramSwitch="--${!paramNameRef}"
      switches[$paramSwitch]="${param}"
      paramDefaultRef="${paramNameRef}_default"
      paramDefault=${!paramDefaultRef}
      if [[ -n "${paramDefault}" ]] # param has default value
      then
         unset ${param}
         printf -v ${param} -- ${paramDefault}
      else
         paramArityRef="${paramNameRef}_arity"
         paramRequiredRef="${paramNameRef}_required"
         if [[ -n ${!paramArityRef} ]]
         then
            if [[ -n "${paramRequiredRef}" ]] # param is not flag
            then
               unusedParams[$paramSwitch]=1
            fi
         else
            unset "${param}"
         fi
      fi
   done

   local paramArgsCount=0
   local paramArity
   local switch
   local first=1
   local last

   unset param

   for arg in ${args[@]} # process command line arguments
   do
      if [[ "${arg}" =~ ^--.+ ]] # if param switch
      then
         if [[ ${paramArgsCount} -eq 0 ]] && [[ -z "${first}" ]] # if no args for previous param
         then
            if [[ -n "${paramArity}" ]] # if not flag, error
            then
               echo "Missing arguments for option ${switch}." >&2
               return 1
            else # if flag, assign 1 to value
               unset ${param}
               printf -v ${param} "1"
            fi
         fi
         switch="${arg}"
         if [[ "${switch}" == "--help" ]]
         then
            argHelp "${paramListRef}"
            return 127
         fi
         param=${switches[$switch]}
         if [[ -z "${param}" ]]
         then
            echo "Unknown option: ${switch}." >&2
            return 1
         fi
         paramArityRef="${paramListRef}_${param}_arity"
         paramArity=${!paramArityRef}
         paramArgsCount=0
         unset "unusedParams[${switch}]"
         if [[ -n "${usedParams[$switch]}" ]]
         then
            echo "Duplicate usage of option ${switch}." >&2
            return 1
         fi
         usedParams[$switch]=1
         unset "${param}"
         eval "${param}=()"
      else
         if [[ -n "${first}" ]]
         then
            params=( ${paramList} )
            param=${params}
            if [[ -z "${param}" ]]
            then
               echo "This command takes no arguments." >&2
               return 1
            fi
            paramNameRef="${paramListRef}_${param}"
            switch="--${!paramNameRef}"
            paramArityRef="${paramListRef}_${param}_arity"
            paramArity=${!paramArityRef}
            paramArgsCount=0
            unset "unusedParams[${switch}]"
            usedParams[$switch]=1
            unset "${param}"
            eval "${param}=()"
         fi

         if [[ -z "${paramArity}" ]] # if flag
         then
            echo "Arguments for flag ${switch} are not allowed." >&2
            return 1
         else
            if [[ "${paramArity}" == "1" ]] && [[ ${paramArgsCount} -gt 0 ]] # if more than 1 arg for unary param
            then
               echo "Too many arguments for option ${switch}." >&2
               return 1
            fi

            printf -v "${param}[${paramArgsCount}]" -- "${arg}" # -- for not handling $arg as printf option
         fi
         (( paramArgsCount++ ))
      fi
      first=
   done

   if [[ -n "${param}" ]] && [[ ${paramArgsCount} -eq 0 ]] # if not flag and no args for last param, error
   then
      if [[ -n "${paramArity}" ]] # if not flag, error
      then
         echo "Missing arguments for option ${switch}." >&2
         return 1
      else # if flag, assign 1 to value
         unset ${param}
         printf -v ${param} "1"
      fi
   fi

   if [[ -n "${!unusedParams[@]}" ]]
   then
      echo "Missed option(s): ${!unusedParams[@]}." >&2
      return 1
   fi
}

argHelp() {
   local executable="${1}"
   local paramListRef="${2}"
   local text="${3}"
   local paramList=${!paramListRef}
   local paramUsage

   if [[ -n "${text}" ]]
   then
      echo "${text}"
   fi
   echo "Usage:
  ${executable} <params> ...
Params:"
   for param in ${paramList}
   do
      local paramNameRef="${paramListRef}_${param}"
      local paramArityRef="${paramNameRef}_arity"
      local paramArity="${!paramArityRef}"
      local paramSwitch="--${!paramNameRef}"
      if [[ -z "${paramArity}" ]]
      then
         paramUsage="${paramSwitch}"
      elif [[ "${paramArity}" == "1" ]]
      then
         paramUsage="${paramSwitch} <value>"
      elif [[ "${paramArity}" == "n" ]]
      then
         paramUsage="${paramSwitch} <values> ..."
      fi
      local paramDescRef="${paramNameRef}_desc"
      local paramDesc="${!paramDescRef}"
      printf "  %-24s   %s\n" "${paramUsage}" "${paramDesc}"
   done
}

params="m t f d"
params_m="main"
params_m_arity=""
params_m_desc="Specify main argument"
params_m_cmpl="main1 main2 main3 main333"
params_f="from"
params_f_arity=""
params_f_desc="Specify from"
params_f_cmpl="from-me from-you from-him"
params_t="to"
params_t_arity="1"
params_t_desc="Specify to"
params_t_cmpl="to-you to-us to-them"
params_t_required="1"
params_d="todo"
params_d_arity="n"
params_d_desc="Specify TODO"
params_d_cmpl="too doo d"
params_d_default="foo"

#complete -F myComplete o

argCompgen() {
   local from=${2:-1}
   local isNewWord=
   [[ ${#COMP_WORDS[@]} > COMP_CWORD ]] && newWord=1
   COMPREPLY=( $(compgen -W "$(argComplete $1 ${COMP_WORDS[@]:$from} $isNewWord)" -- ${COMP_WORDS[COMP_CWORD]}) )
}

myComplete() {
   argCompgen params
}

argComp() { # TODO command with more than 1 prefix element
   local prefix="${1}"
   local fn="argComp__${prefix}"
   complete -F "${fn}" "${prefix}"
   eval "${fn}() {
      argCompgen '${2}'
   }"
}

argComp o params

o() {
   if [[ $1 == "--help" ]]
   then
      argHelp "${BASH_SOURCE}" params "Some file"
      return 0
   fi
   argParse params "${@:1}"
   if [[ $? -ne 0 ]]
   then
      return 1
   fi

   echo "f: ${f}"
   echo "t: ${t}"
   echo "d: ${d[@]}"
}

# TODO underscore var to prevent names collisions