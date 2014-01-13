#!/bin/bash

function realpath() {
   readlink -f "${1:-.}"
}

function isTrue() {
   case "$1" in
   1|[tT][rR][uU][eE]|[yY]|[yY][eE][sS]) return 0 ;;
   0|[fF][aA][lL][sS][eE]|[nN]|[nN][oO]|"") return 1 ;;
   esac
   alert "Warning: Invalid boolean value. False assumed."
   return 1
}

function is() {
   [[ -n "$1" ]]
}

function no() {
   [[ -z "$1" ]]
}

function isNum() {
   [ -n "$1" ] && [ -z "${1//[0-9]}" ]
}

function isInt() {
   if [ -z "$1" ] || [ "$1" = "-" ]
   then
      return 1
   fi
   local v="$1"
   v="${v##-}"
   v="${v//[0-9]}"
   [ -z "$v" ]
}

function isUtf() {
   [[ "${LANG}" == *UTF-8 ]]
}

nc="\033[0m"
underscore="\033[4m"
black="\033[30m"
Red="\033[31m"
Green="\033[32m"
Yellow="\033[33m"
Blue="\033[34m"
Magenta="\033[35m"
Cyan="\033[36m"
gray="\033[37m"
Gray="\033[1;30m"
red="\033[1;31m"
green="\033[1;32m"
yellow="\033[1;33m"
blue="\033[1;34m"
magenta="\033[1;35m"
cyan="\033[1;36m"
white="\033[1;37m"
BLACK="\033[40m"
RED="\033[41m"
GREEN="\033[42m"
YELLOW="\033[43m"
BLUE="\033[44m"
MAGENTA="\033[45m"
CYAN="\033[46m"
WHITE="\033[47m"

function debug() { echo -e "${blue}$1${nc}" >%2; }
function alert() { echo -e "$1" >&2; }
function warn() { echo -e "${yellow}$1${nc}"; }
function sayOk() { echo -e "${green}$1${nc}";}
function say() { echo -e "$1";}
function put() { echo -ne "$1"; }

function readNotEmptyVar() {
   local var=${1:?'Missed variable name.'}
   local value
   local desc="${2:-$1}"
   local default=$3

   prompt="Provide ${desc}${default:+" (default is $default)"}: "
   while [[ -z "${value}" ]]
   do
      read -p "${prompt}" value
      if [[ -z "${value}" ]] && [[ -n "${default}" ]]
      then
         value="${default}"
      fi
   done
   printf -v ${var} -- "${value}"
}

function injectVars() {
   local varsFile=$1
   local tmpFile=tmp

   local varDecl="^\([a-Z_][a-Z0-9_]*\)=.*"
   source $(readlink -f "${varsFile}")
   cat <&0 > ${tmpFile}

   for var in $(sed -n -e "/${varDecl}/ p" < "${varsFile}" | sed -e "s/${varDecl}/\1/")
   do
      local escapedValue=$(echo ${!var} | sed -e 's/[\\&\/]/\\&/g')
      sed -e "s/\${${var}}/${escapedValue}/g" -e "s/\$${var}/${escapedValue}/g" < "${tmpFile}" > "${tmpFile}.tmp"
      mv "${tmpFile}.tmp" "${tmpFile}"
   done
   cat "${tmpFile}" >&1
   rm "${tmpFile}"
}
