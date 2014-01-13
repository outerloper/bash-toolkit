#!/bin/bash

source ../src/arglist.sh

declare -A options=(
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
   local main persons loud times
   if getArgs options "$@"
   then
      printArgs options

      for (( i = 0; i < times; i++)) {
         echo "${main} ${persons[@]}${loud:+!!}"
      }
   else
      return 1
   fi
}



declare -A calculatorOptions=(
   ["help"]='calculator'
   ["help.desc"]='This is arglist.sh demo - integer calculator.'
   ["main"]=operation-and-first-arg
   ["main.required"]=yes
   ["main.arity"]=n
   ["main.desc"]='Operation name and first numeric argument'
   ["main.comp"]='add sub mul div'
   ["to.required"]=yes
   ["to.arity"]=1
   ["to.desc"]='Second numeric argument'
)
enableAutocompletion calculatorOptions

function calculator() {
   local main to
   if getArgs calculatorOptions "$@"
   then
      printArgs calculatorOptions
      if (( ${#main[@]} < 2 ))
      then
         error 'Missing first argument and/or operation name'
         return 1
      fi
      operation=${main}
      arg1=${main[1]}
      case "${operation}" in
       add) (( result = arg1 + to )) ;;
       sub) (( result = arg1 - to )) ;;
       mul) (( result = arg1 * to )) ;;
       div) (( result = arg1 / to )) ;;
       *)
         echo 'Invalid parameter name'
         return 1
      esac
      echo ${result}
   else
      return 1
   fi
}



declare -A listDirOptions=(
   ["help"]='list-dir'
   ["help.desc"]='This is arglist.sh demo.'
   ["hidden"]='include-hidden'
   ["dir.comp"]='compDirs()'
   ["dir.arity"]='1'
)
enableAutocompletion listDirOptions
function compDirs() {
   echo 'dir1 dir2 dir3'
}

function list-dir() {
   local hidden
   if getArgs listDirOptions "$@"
   then
      printArgs listDirOptions

      if is ${hidden}
      then
         echo 'file1 file2 .file3'
      else
         echo 'file1 file2'
      fi
   else
      return 1
   fi
}
