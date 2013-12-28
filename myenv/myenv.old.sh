#!/bin/bash


### ENV RC START

green="\033[0;32m"
red="\033[1;31m"
yellow="\033[1;33m"
white="\033[1;37m"
blue="\033[1;34m"
noColor="\033[1;0m"

debug() { echo -e "${blue}${1:-OK}${noColor}" 1>&2; }
stdErr() { echo -e "${red}${1}${noColor}" 1>&2; }
echoOk() { echo -e "${green}${1:-OK}${noColor}"; }
echoError() { echo -e "${red}${1:-ERROR}${noColor}"; }
echoWarning() { echo -e "${yellow}${1:-WARNING}${noColor}"; }
echoInfo() { echo -e "${1}"; }
prompt() { echo -n -e "${yellow}${1:-WARNING}${noColor}"; }
confirm() {
   prompt "${1:-Are you sure?} [y/n] ";
   while true
   do
      read answer
      [[ "$answer" == y ]] && return 0
      [[ "$answer" == n ]] && return 1
      prompt "Please answer y or n: "
   done
}
_em() { echo -n -e "${white}"; }
em_() { echo -n -e "${noColor}"; }

ok() { return $?; }

HELP_ASSET_KEY=help
DESCRIPTION_ASSET_KEY=description
AUTOCOMPLETER_ASSET_KEY=autocompleter
RUNNER_ASSET_KEY=script
ALL_ASSETS_PATTERN="${HELP_ASSET_KEY}|${DESCRIPTION_ASSET_KEY}|${AUTOCOMPLETER_ASSET_KEY}"
ALL_ASSETS_LIST="${HELP_ASSET_KEY} ${DESCRIPTION_ASSET_KEY} ${AUTOCOMPLETER_ASSET_KEY}"
INTERNAL_INIT_FILE_NAME=env.init.sh
INTERNAL_RC_FILE_NAME=env.rc.sh
CUSTOM_INIT_FILE_NAME=custom.init.sh
CUSTOM_RC_FILE_NAME=custom.rc.sh

renameFunction() {
   if [[ ! $(type -t "${1}") == "function" ]]
   then
      echoError "No such function: ${1}"
   fi
   if [ -z "${2}" ]
   then
      echoError "Missed 2nd argument."
   fi
   local oldName="$(declare -f "$1")"
   local newName="${2}${oldName#$1}"
   eval "${newName}"
   unset -f "${oldName}"
}

absolutePath() {
   readlink -f "${1}"
   if ok
   then
      return 0
   else
      stdErr "Unknown absolute path for '${1}'"
      return 1
   fi
}

listAllCommands() {
   local suffix="\.${RUNNER_ASSET_KEY}\.sh\$"
   result=( $("ls" "${ENV_HOME}" | grep "${suffix}" | sed -e "s/${suffix}//") ) && echo "${result[@]}"
}

listDirNames() {
   pushd "${1:-.}" > /dev/null 2> /dev/null
   if ok
   then
      "ls" -d */ 2> /dev/null | sed -e 's/\/$//'
      popd > /dev/null 2> /dev/null
   fi
}

getCommandScript() {
   script="${ENV_HOME}/${CMD}.${1:-$RUNNER_ASSET_KEY}.sh"
   echo "${script}"
   [ -x "${script}" ]
}

env_rc() {
   script="${ENV_HOME}/${CUSTOM_RC_FILE_NAME}" && [ -f "${script}" ] && source "${script}"
}

### ENV RC END



### ENV INIT START

env_autocompleter() {
   COMPREPLY=( $(compgen -W "$(env_compreply $@)" -- "${COMP_WORDS[COMP_CWORD]}") )
}

env_compreply() {
   local numWords="${COMP_CWORD}"
   if [[ "${numWords}" -eq 1 ]]
   then
      listAllCommands
   else
      CMD=${COMP_WORDS[1]}
      script=$(getCommandScript "${AUTOCOMPLETER_ASSET_KEY}") && "${script}" "${COMP_WORDS[@]:2}"
   fi
}

env_init() {
   complete -F env_autocompleter "${ENV}"
   export PS1="(${ENV})${PS1}"
   script="${ENV_HOME}/${CUSTOM_INIT_FILE_NAME}" && [ -f "${script}" ] && source "${script}"
   echo "Welcome to '$ENV' environment. For usage info run: $ENV help"
}

### ENV INIT END



env_main() {
   export CMD="${1}"
   if [ $# -eq 0 ] || ! getCommandScript > /dev/null
   then
      echoWarning "No valid specified command. Type '${ENV} help' for help."
      return 1
   fi
   if [[ "${@: -1}" =~ -h|--help ]]
   then
      "${ENV}" "${HELP_ASSET_KEY}" ${@:1:$#-1}
      return 0
   fi
   "$(getCommandScript)" ${@:2}
}



### COMMAND MANAGEMENT CODE START

command_addCommand() {
   local script=$(getCommandScript "${1}")
   if [ -f "${script}" ]
   then
      echoWarning "Command ${CMD} already exists."
      return 1
   else
      echo -e "#!/bin/bash\n\n" > "${script}" &&
      chmod u+x "${script}"
      return $?
   fi
}

command_deleteCommandAsset() {
   asset="$1"
   local script=$(getCommandScript "${asset}") &&
   if [ -f "${script}" ]
   then
      rm "${script}"
      return $?
   fi
}

command_deleteCommand() {
   if ! command_deleteCommandAsset
   then
      return 1
   fi
   for asset in ${ALL_ASSETS_PATTERN}
   do
      command_deleteCommandAsset "${asset}" > /dev/null
   done
   return 0
}

command_editCommand() {
   local script=$(getCommandScript "${1}") &&
   if [ ! -f "${script}" ]
   then
      echo -e "#!/bin/bash\n
# echo \"\"" > "${script}" &&
      chmod u+x "${script}"
   fi
   ${EDITOR:-vim} "${script}"
}

command_editSpecial() {
   script="${ENV_HOME}/${1}" &&
   if [ ! -f "${script}" ]
   then
      echo -e "#!/bin/bash\n
# echo \"\"" > "${script}"
   fi
   ${EDITOR:-vim} "${script}"
}

command_runAdd() {
   if [ $# -ne 1 ]
   then
      echoError "Wrong number of parameters."
      return 1
   fi
   CMD="$1"
   command_addCommand &&
   command_editCommand
   if ok
   then
      echoOk "'${CMD}' command added successfuly"
   fi
}

command_runEdit() {
   if [ $# -lt 1 ]
   then
      echoError "Parameters required."
      return 1
   fi
   CMD="$1"
   if [ $# -gt 2 ]
   then
      echoError "Too many parameters."
      return 1
   fi
   local asset="$2"
   if [ $# -eq 2 ]
   then
      if [[ ! "${asset}" =~ ${ALL_ASSETS_PATTERN} ]]
      then
         echoError "2nd parameter has wrong value."
         return 1
      fi
   fi
   if ! getCommandScript
   then
      echoError "Command ${CMD} does not exist."
      return 1
   fi
   command_editCommand "${asset}"
   if ! ok
   then
      echoError "Something went wrong"
   fi
}

command_runDelete() {
   if [ $# -le 1 ]
   then
      echoError "Parameters required."
      return 1
   fi
   CMD="$1"
   if [ $# -ge 2 ]
   then
      echoError "Too many parameters."
      return 1
   fi
   local cmdAssetKey="$2"
   if [ $# -eq 2 ]
   then
      if [[ ! "${cmdAssetKey}" =~ "${CMD_ALL_ASSETS_PATTEN}" ]]
      then
         echoError "2nd parameter has wrong value."
         return 1
      fi
   fi
   if ! getCommandScript "${cmdAssetKey}"
   then
      echoWarning "Nothing to delete."
      return 1
   fi
   if confirm
   then
      if [ -n "${cmdAssetKey}" ]
      then
         command_deleteCommandAsset "${cmdAssetKey}" &&
         echoOk "'${CMD}' $2 deleted successfully."
      else
         command_deleteCommand &&
         echoOk "'${CMD}' command deleted successfuly."
      fi
      if ok
      then
         echoOk "Command"
      fi
   fi
}

command_runner() {
   action="$1"
   shift
   case "${action}" in
      add)
         command_runAdd $@
         return $?
      ;;
      edit)
         command_runEdit $@
         return $?
      ;;
      delete)
         command_runDelete $@
         return $?
      ;;
      init)
         command_editSpecial "${CUSTOM_INIT_FILE_NAME}"
         return $?
      ;;
      rc)
         command_editSpecial "${CUSTOM_RC_FILE_NAME}"
         return $?
      ;;
      *)
         echoError "No valid action specified."
         return 127
      ;;
   esac
}

### COMMAND MANAGEMENT CODE END



### COMMAND MANAGEMENT ASSETS START

command_autocompleter() {
   if [ $# -eq 1 ]
   then
      echo "add edit delete init rc"
   elif [[ "$1" =~ edit|delete ]]
   then
      if [ $# -eq 2 ]
      then
         listAllCommands
      fi
      if [ $# -eq 3 ]
      then
         echo "${ALL_ASSETS_LIST}"
      fi
   fi
}

command_help() {
   echo "   add <command>             add new command"
   echo "   edit <command> [<asset>]  edit existing command or its asset (one of: ${ALL_ASSETS_LIST})"
   echo "   delete <command>          delete existing command"
   echo "   init                      edit file which is executed when environment shell is initialized"
   echo "   rc                        edit file which is executed for every bash script invoked within a shell"
}

command_description() {
   echo "Add, remove or configure commands."
}

### COMMAND MANAGEMENT ASSETS END



### HELP CODE START

help_runner() {
   CMD="$1"
   if [ -z "${1}" ]
   then
      echoInfo "Usages:"
      for CMD in $(listAllCommands)
      do
         printf "  ${white}${ENV} %-15s${noColor}" "$CMD"
         if descScript="$(getCommandScript "${DESCRIPTION_ASSET_KEY}")"
         then
            ${descScript}
         else
            echo
        fi
      done
      return 0
   fi
   if ! getCommandScript > /dev/null
   then
      echoInfo "No such command: ${CMD}."
      return 127
   fi
   descScript=$(getCommandScript "${DESCRIPTION_ASSET_KEY}") && {
      helpText="$(${descScript} $@)" 2> /dev/null
   }
   helpScript=$(getCommandScript "${HELP_ASSET_KEY}") && {
      [ -n "${helpText}" ] && helpText="${helpText}\n"
      helpText="${helpText}$(${helpScript} $@)" 2> /dev/null
   }
   if [ -z "${helpText}" ]
   then
      echoInfo "No help available for '${CMD}'."
   else
      echoInfo "${helpText}"
   fi
}

### HELP CODE END



### HELP ASSETS START

help_autocompleter() {
   listAllCommands
}

help_help() {
   echo "Usage: ${ENV} help <command>"
}

help_description() {
   echo "Displays detailed help about command specified"
}

### HELP ASSETS END



### INSTALLER START

thisScriptName="$(basename "$0")"

useSnippet() {
   sed -n -e "/### $1 START/,/### $1 END/ p" <"$2" | sed -e "/### $1 START/ d" -e "/### $1 END/ d"
}

useFunction() {
   targetFunctionName=${2:-$1}
   renameFunction "${1}" "${targetFunctionName}" && declare -f "${targetFunctionName}"
}

mixinFunction() {
   declare -f "${1}" | sed -e '1,2 d' -e '$ d'
}

installer_printUsage() {
   echoInfo "Usage:
${thisScriptName} name [basedir] [loader]
    name     Name of your environment to be created.
    basedir  Directory where to create environment's home directory. Default: current directory.
    loader   Bash script where to place function loading your environment. Default: ~/.bash_profile.
${thisScriptName} -h|--help         Display help.\n"
}

installer_doHelp() {
   echo "${thisScriptName} - creates named customizable bash environment."
   installer_printUsage
}

installer_install() {
   ENV="${1}"
   envPath="${2:-"."}"
   envLoadScript="${3:-$HOME/.bash_profile}"

   if [ -z "${ENV}" ]
   then
      echo "Missing environment name. For additional information run: $(basename $0) -h"
      return 127
   fi

   ENV_HOME="${envPath}/${ENV}" &&
   echoInfo "Installing environment '${ENV}' in '${ENV_HOME}'..." &&
   mkdir -p ${ENV_HOME} &&
   ENV_HOME=$(absolutePath "${envPath}/${ENV}") &&

   thisFile="$(absolutePath "${BASH_SOURCE}")" &&
   initFile="${ENV_HOME}/${INTERNAL_INIT_FILE_NAME}" &&
   rcFile="${ENV_HOME}/${INTERNAL_RC_FILE_NAME}" &&
   envLoadScriptSectionHeader="### $ENV SETUP: (do not edit line below)" &&

   printf "Save environment loader in '$envLoadScript'... " &&
   envLoadScript=$(absolutePath "${envLoadScript}") &&
   sed -e "/${envLoadScriptSectionHeader}/,+1 d" -e "/^$/d" < "${envLoadScript}" > "${envLoadScript}.tmp" &&
   mv "${envLoadScript}.tmp" "${envLoadScript}" &&

   echo -e "\n${envLoadScriptSectionHeader}
${ENV}() { bash --rcfile '${rcFile}' --init-file '${initFile}'; }
" >> "${envLoadScript}" &&
   echoOk &&

   printf "Prepare environment's initializer script... " &&

   echo -e "#!/bin/bash\n
" > "${rcFile}" &&
   useSnippet "ENV RC" "${thisFile}" >> "${rcFile}" &&
   echo env_rc >> "${rcFile}" &&
   chmod u+x "${rcFile}" &&

   echo -e "#!/bin/bash\n
export ENV=\"${ENV}\"
export ENV_HOME=\"${ENV_HOME}\"
export BASH_ENV=\"${rcFile}\"\n
source ${rcFile}\n" >"${initFile}" &&
   useSnippet "ENV INIT" "${thisFile}" >> "${initFile}" &&
   useFunction env_main "${ENV}" >> "${initFile}" &&
   echo env_init >> "${initFile}" &&
   chmod u+x "${initFile}" &&
   echoOk &&

   printf "Prepare built-in commands... " &&

   CMD=command &&
   command_deleteCommandAsset &&
   command_addCommand &&
   useSnippet "COMMAND MANAGEMENT CODE" "${thisFile}" >> "$(getCommandScript)" &&
   echo 'command_runner $@' >> "$(getCommandScript)" &&
   command_deleteCommandAsset "${AUTOCOMPLETER_ASSET_KEY}" &&
   command_addCommand "${AUTOCOMPLETER_ASSET_KEY}" &&
   mixinFunction command_autocompleter >> "$(getCommandScript "${AUTOCOMPLETER_ASSET_KEY}")" &&
   command_deleteCommandAsset "${HELP_ASSET_KEY}" &&
   command_addCommand "${HELP_ASSET_KEY}" &&
   mixinFunction command_help >> "$(getCommandScript "${HELP_ASSET_KEY}")" &&
   command_deleteCommandAsset "${DESCRIPTION_ASSET_KEY}" &&
   command_addCommand "${DESCRIPTION_ASSET_KEY}" &&
   mixinFunction command_description >> "$(getCommandScript "${DESCRIPTION_ASSET_KEY}")" &&

   CMD=help &&
   command_deleteCommandAsset &&
   command_addCommand &&
   useSnippet "HELP CODE" "${thisFile}" >> "$(getCommandScript)" &&
   echo 'help_runner $@' >> "$(getCommandScript)" &&
   command_deleteCommandAsset "${AUTOCOMPLETER_ASSET_KEY}" &&
   command_addCommand "${AUTOCOMPLETER_ASSET_KEY}" &&
   mixinFunction help_autocompleter >> "$(getCommandScript "${AUTOCOMPLETER_ASSET_KEY}")" &&
   command_deleteCommandAsset "${HELP_ASSET_KEY}" &&
   command_addCommand "${HELP_ASSET_KEY}" &&
   mixinFunction help_help >> "$(getCommandScript "${HELP_ASSET_KEY}")" &&
   command_deleteCommandAsset "${DESCRIPTION_ASSET_KEY}" &&
   command_addCommand "${DESCRIPTION_ASSET_KEY}" &&
   mixinFunction help_description >> "$(getCommandScript "${DESCRIPTION_ASSET_KEY}")" &&
   echoOk &&
   echoOk "Environment '${ENV}' installed successfully!" &&
   echoInfo "To enable it, run: source ${envLoadScript}
To activate it, run: ${ENV}" &&
   return 0

   echoError
   echoError "Something went wrong. Installing environment not completed."
   return 1
}

### INSTALLER END



### MAIN

case "${1}" in
   -h|--help)
      installer_doHelp
      exit $?
      ;;
   *)
      installer_install $@
      exit $?
      ;;
esac
