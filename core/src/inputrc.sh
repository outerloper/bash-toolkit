#!/bin/sh

function bind-to-macro() {
   macro=$1
   shift
   for key in $@
   do
      bind "\"${key}\": ${macro}"
   done
}

function bind-to-chars() {
   local macro=$1
   shift
   for key in $@
   do
      case ${key} in
         '\e'|'\C-'|'\e\C-') key="${key} " ;;
      esac
      bind "\"${key}\": \"${macro}\""
   done
}

function grep-history() {
   history | g "$1" | tail -50
}

function quick-find() {
   find . -regex ".*$1.*" 2> /dev/null
}

function env-bind() {
   : ${ENV:=cd}
   : ${EDITOR:=vim}
#   if [[ $- =~ *i* ]] # does not work
#   then
      alias cd=chdir
#   fi

   # key definitions

   local Ctrl='\C-'
   local Alt='\e'
   local AltCtrl=${Alt}${Ctrl}

   local Left='\e[D'
   local Right='\e[C'
   local Up='\e[A'
   local Down='\e[B'
   local CtrlLeft='\eOD'
   local CtrlRight='\eOC'
   local CtrlUp='\eOA'
   local CtrlDown='\eOB'
   local AltLeft=${Alt}${Left}
   local AltRight=${Alt}${Right}
   local AltUp=${Alt}${Up}
   local AltDown=${Alt}${Down}
   local AltCtrlLeft=${Alt}${CtrlLeft}
   local AltCtrlRight=${Alt}${CtrlRight}
   local AltCtrlUp=${Alt}${CtrlUp}
   local AltCtrlDown=${Alt}${CtrlDown}

   local Home='\e[1~'
   local End='\e[4~'
   local Ins='\e[2~'
   local Del='\e[3~'
   local PgUp='\e[5~'
   local PgDown='\e[6~'
   local AltHome=${Alt}${Home}
   local AltEnd=${Alt}${End}
   local AltIns=${Alt}${Ins}
   local AltDel=${Alt}${Del}
   local AltPgUp=${Alt}${PgUp}
   local AltPgDown=${Alt}${PgDown}

   local Sp=' '
   local Bsp='\C-?'
   local CtrlBsp='\e'
   local AltBsp=${Alt}${Bsp}
   local ShiftTab='\e[Z'
   local BackTick='\`'

   local F1='\e[11~'
   local F2='\e[12~'
   local F3='\e[13~'
   local F4='\e[14~'
   local F5='\e[15~'
   local F6='\e[17~'
   local F7='\e[18~'
   local F8='\e[19~'
   local F9='\e[20~'
   local F10='\e[21~'
   local F11='\e[23~'
   local F12='\e[24~'

   local AltF1=${Alt}${F1}
   local AltF2=${Alt}${F2}
   local AltF3=${Alt}${F3}
   local AltF4=${Alt}${F4}
   local AltF5=${Alt}${F5}
   local AltF6=${Alt}${F6}
   local AltF7=${Alt}${F7}
   local AltF8=${Alt}${F8}
   local AltF9=${Alt}${F9}
   local AltF10=${Alt}${F10}
   local AltF11=${Alt}${F11}
   local AltF12=${Alt}${F12}

   # key sequences definitions

   local EndOfHist="${Alt}>"
   local FwdWord=${AltRight}
   local BkwWord=${AltLeft}
   local ClrLn=${EndOfHist}${End}${AltBsp}
   local ClrLnRight=${AltDel}
   local ClrLnLeft=${AltBsp}

   # key codes used for substitution

   local Aux0='\e[90~'
   local Aux1='\e[91~'
   local Aux2='\e[92~'
   local Aux3='\e[93~'
   local Aux4='\e[94~'
   local Aux5='\e[95~'
   local Aux6='\e[96~'
   local Aux7='\e[97~'
   local Aux8='\e[98~'
   local Aux9='\e[99~'

   # macro bindings

   bind-to-macro forward-char "${Right}"
   bind-to-macro forward-word "${FwdWord}"
   bind-to-macro delete-char "${Del}"
   bind-to-macro kill-word "${AltCtrlRight}"
   bind-to-macro end-of-line "${End}"
   bind-to-macro kill-line "${ClrLnRight}"

   bind-to-macro backward-char "${Left}"
   bind-to-macro backward-word "${BkwWord}" "${CtrlLeft}"
   bind-to-macro backward-delete-char "${Bsp}"
   bind-to-macro backward-kill-word "${AltCtrlLeft}"
   bind-to-macro beginning-of-line "${Home}"
   bind-to-macro unix-line-discard "${ClrLnLeft}"

   #bind-to-macro kill-whole-line
   bind-to-macro undo "${Alt}z"
   bind-to-macro paste-from-clipboard "${Alt}v"
   bind ' ':magic-space # bind-to-macro does not work for magic-space don't know why

   bind-to-macro end-of-history "${EndOfHist}"
   bind-to-macro forward-search-history "${Ctrl}t" "${CtrlDown}"
   bind-to-macro history-search-backward "${AltUp}"
   bind-to-macro history-search-forward "${AltDown}"

   # custom char sequences definitions

   local nextWord=${FwdWord}${FwdWord}${BkwWord}
   local help=${End}' --help\n'
   local man=${Home}'man '${FwdWord}${AltDel}'\n'
   local lsAndPwd=${ClrLn}'\\ls --color -l\npwd\n'
   local lsLtr=${ClrLn}'\\ls --color -ltr\n'
   local pipeToGrep=${End}' | grep \"\"'${Left}
   local pipeToSed=${End}' | sed -e \"\"'${Left}
   local echoize=${Home}'echo \"'${End}'\"'${Left}
   local find=${ClrLn}'quick-find \"\"'${Left}
   local grepHistory=${Home}' grep-history \"'${End}'\"\n'
   local grepPs=${ClrLn}'ps ux | grep \"\"'${Left}
   local kill=${ClrLn}'ps ux\nkill -9 '
   local jps=${ClrLn}'jps -lm\n'
   local executize=${Home}'./'${FwdWord}''${End}'\t'
   local makeVar=${BkwWord}'${'${FwdWord}}${Left}'\t'
   local initVar='}'${Left}':='
   local arrayVar=${BkwWord}'${'${FwdWord}'[@]}'${Left}${Left}${Left}${Left}'\t'
   local goToHome=${ClrLn}'cd ~\n'
   local goToPrev=${ClrLn}'cd -\n'
   local goDownDir=${ClrLn}'cd \t'
   local goUpDir=${ClrLn}'cd ..\n'
   local chDir=${ClrLn}'cd --\ncd -'
   local editFile=${ClrLn}${EDITOR}' \t'
   local mkdir=${ClrLn}'mkdir -p '
   local rm=${ClrLn}'rm -rf \t'
   local currAbsPath='$PWD/\t'
   local useLastCommentedLine=${ClrLn}'#'${AltUp}${Bsp}${End}
   local envCommand=${ClrLn}${ENV}' \t'
   local macro=${End}'; }'${Home}'() { '${Home}'function '
   local echoLastResultCode=${End}'echo $?\n'
   local doubleQuote='q\"'${BkwWord}'\"'${FwdWord}${Bsp}
   local parentheses='q)'${BkwWord}'('${FwdWord}${Bsp}
   local braces='q}'${BkwWord}'{'${FwdWord}${Bsp}
   local rerunLast2Commands=${Up}${Up}'\n'${Up}${Up}'\n'
   local historyExpansion=${Home}'!'${End}${Aux0}

   # custom char sequences bindings

   # Ctrl+Num not working

   bind-to-chars "${ClrLn}" "${AltCtrlDown}"
   bind-to-chars "${nextWord}" "${CtrlRight}"
   bind-to-chars "${help}" "${F1}"
   bind-to-chars "${man}" "${AltF1}"
   bind-to-chars "${lsAndPwd}" "${F2}"
   bind-to-chars "${lsLtr}" "${AltF2}"
   bind-to-chars "${pipeToGrep}" "${Alt}g"
   bind-to-chars "${pipeToSed}" "${Alt}s"
   bind-to-chars "${echoize}" "${Alt}e"
   bind-to-chars "${find}" "${Alt}f"
   bind-to-chars "${grepHistory}" "${CtrlUp}" "${AltCtrlUp}"
   bind-to-chars "${grepHistory}!" "${AltCtrlUp}"
   bind-to-chars "${grepPs}" "${Alt}p"
   bind-to-chars "${kill}" "${Alt}k"
   bind-to-chars "${jps}" "${Alt}j"
   bind-to-chars "${executize}" "${Alt}."
   bind-to-chars "${makeVar}" "${Alt}$"
   bind-to-chars "${initVar}" "${Alt}="
   bind-to-chars "${arrayVar}" "${Alt}@"
   bind-to-chars "${goToHome}" "${AltHome}"
   bind-to-chars "${goToPrev}" "${AltEnd}"
   bind-to-chars "${goDownDir}" "${PgDown}"
   bind-to-chars "${goUpDir}" "${PgUp}"
   bind-to-chars "${chDir}" "${AltPgDown}" "${AltPgUp}"
   bind-to-chars "${mkdir}" "${AltIns}"
   bind-to-chars "${currAbsPath}" "${ShiftTab}"
   bind-to-chars "${useLastCommentedLine}" "${Alt}!"
   bind-to-chars "${envCommand}" "${F3}"
   bind-to-chars "${macro}" "${Alt}m"
   bind-to-chars "${echoLastResultCode}" "${Alt}?"
   bind-to-chars "${doubleQuote}" "${Alt}\'"
   bind-to-chars "${parentheses}" "${Alt}("
   bind-to-chars "${braces}" "${Alt}{"
   bind-to-chars "${rerunLast2Commands}" "${Alt}%"

   # history setup

   export HISTCONTROL=ignorespace:ignoredups:erasedups
   export HISTFILESIZE=1000
   export HISTSIZE=1000
   export HISTTIMEFORMAT="%Y-%m-%d %T  "
   export PROMPT_COMMAND=''
   shopt -s histappend # to check if duplicates handled as desired here
   bind "set completion-ignore-case on"
   bind "set show-all-if-ambiguous on"
   bind "set completion-query-items 1000"
}

env-bind
unset -f env-bind
