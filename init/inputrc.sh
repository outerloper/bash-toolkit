#!/bin/sh

function bindToMacro() {
   macro=$1
   shift
   for key in $@
   do
      bind "\"${key}\": ${macro}"
   done
}

function bindToChars() {
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

function grep-history() { history | grep --color=always "$1" | tail -n50; }

function quick-find() { find . -regex ".*$1.*" 2> /dev/null; }

#complete -d chdir
#complete -d pushdir
#function chdir() { cd $1 && \ls --color; }
#function pushdir() { pushd $1 && \ls --color; }
#function popdir() { popd $1 && \ls --color; }

function env_bind() {
   : ${ENV:=cd}
   : ${EDITOR:=vim}

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

   # macro bindings

   bindToMacro forward-char "${Right}"
   bindToMacro forward-word "${FwdWord}"
   bindToMacro delete-char "${Del}"
   bindToMacro kill-word "${AltCtrlRight}"
   bindToMacro end-of-line "${End}"
   #bindToMacro kill-line

   bindToMacro backward-char "${Left}"
   bindToMacro backward-word "${BkwWord}" "${CtrlLeft}"
   bindToMacro backward-delete-char "${Bsp}"
   bindToMacro backward-kill-word "${AltCtrlLeft}"
   bindToMacro beginning-of-line "${Home}"
   bindToMacro unix-line-discard "${ClrLnLeft}"

   #bindToMacro kill-whole-line
   bindToMacro undo "${Alt}z"
   bindToMacro paste-from-clipboard "${Alt}v"

   bindToMacro end-of-history "${EndOfHist}"
   bindToMacro reverse-search-history "${Ctrl}r" "${CtrlUp}"
   bindToMacro forward-search-history "${Ctrl}t" "${CtrlDown}"
   bindToMacro history-search-backward "${AltUp}"
   bindToMacro history-search-forward "${AltDown}"

   # custom char sequences definitions

   local nextWord=${FwdWord}${FwdWord}${BkwWord}
   local help=${End}' --help\n'
   local man=${Home}'man '${FwdWord}${ClrLnRight}'\n'
   local lsAndPwd=${ClrLn}'\\ls --color -l\npwd\n'
   local lsLtr=${ClrLn}'\\ls --color -ltr\n'
   local pipeToGrep=${End}' | grep \"\"'${Left}
   local pipeToSed=${End}' | sed -e \"\"'${Left}
   local echoize=${Home}'echo \"'${End}'\"'${Left}
   local find=${ClrLn}'quick-find \"\"'${Left}
   local grepHistory=${Home}' grep-history \"'${End}'\"\n'
   local grepPs=${ClrLn}'ps aux | grep \"\"'${Left}
   local jps=${ClrLn}'jps -lm\n'
   local executize=${Home}'./'${FwdWord}''${End}'\t'
   local makeVar=${BkwWord}'${'${FwdWord}'\t'
   local initVar='}'${Left}':='
   local arrayVar=${BkwWord}'${'${FwdWord}'[@]}'
   local goToHome=${ClrLn}' cd ~\n'
   local goToPrev=${ClrLn}' cd -\n'
   local goDownDir=${ClrLn}' cd \t'
   local goUpDir=${ClrLn}' cd ..\n'
   local pushd=${ClrLn}' pushd \t'
   local popd=${ClrLn}' popd\n'
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

   # custom char sequences bindings

   bindToChars "${ClrLn}" "${AltCtrlDown}"
   bindToChars "${nextWord}" "${CtrlRight}"
   bindToChars "${help}" "${F1}"
#   bindToChars "${man}" "${F3}"
   bindToChars "${lsAndPwd}" "${F2}"
   bindToChars "${lsLtr}" "${AltF2}"
   bindToChars "${pipeToGrep}" "${Alt}g"
   bindToChars "${pipeToSed}" "${Alt}s"
   bindToChars "${echoize}" "${Alt}e"
   bindToChars "${find}" "${Alt}f"
   bindToChars "${grepHistory}" "${AltCtrlUp}"
   bindToChars "${grepPs}" "${Alt}p"
   bindToChars "${jps}" "${Alt}j"
   bindToChars "${executize}" "${Alt}."
   bindToChars "${makeVar}" "${Alt}$" "${Ctrl}"
   bindToChars "${initVar}" "${Alt}=" "${Alt}"
   bindToChars "${arrayVar}" "${Alt}@"
   bindToChars "${goToHome}" "${AltHome}"
   bindToChars "${goToPrev}" "${AltEnd}"
   bindToChars "${goDownDir}" "${PgDown}"
   bindToChars "${goUpDir}" "${PgUp}"
   bindToChars "${pushd}" "${AltPgDown}"
   bindToChars "${popd}" "${AltPgUp}"
   bindToChars "${editFile}" "${Ins}"
   bindToChars "${mkdir}" "${AltIns}"
   bindToChars "${rm}" "${AltDel}"
   bindToChars "${currAbsPath}" "${ShiftTab}"
   bindToChars "${useLastCommentedLine}" "${Alt}!"
   bindToChars "${envCommand}" "${F4}"
   bindToChars "${macro}" "${Alt}m"
   bindToChars "${echoLastResultCode}" "${Alt}?"
   bindToChars "${doubleQuote}" "${Alt}\'"
   bindToChars "${parentheses}" "${Alt}("
   bindToChars "${braces}" "${Alt}{"
   bindToChars "${rerunLast2Commands}" "${Alt}%"

   # history setup

   HISTCONTROL=ignorespace:ignoredups:erasedups
   HISTFILESIZE=1000
   HISTSIZE=1000
   HISTTIMEFORMAT="%Y-%m-%d %T  "
   bind "set completion-ignore-case on"
   bind "set show-all-if-ambiguous on"
   bind "set completion-query-items 1000"
}

env_bind
