require utils.sh

${BUSH_ASSOC} KEY_BINDINGS
KEY_BINDINGS=()

${BUSH_ASSOC} KEY_MACROS
for fun in $( bind -l ) ;do
    KEY_MACROS["$fun"]="$fun"
done

${BUSH_ASSOC} KEY_EXECUTABLES
KEY_EXECUTABLES=()

${BUSH_ASSOC} KEY_PLACEHOLDERS
KEY_PLACEHOLDERS=()

undef='\e[XX~'

${BUSH_ASSOC} KEY_DEFS
if -has "$(uname)" CYGWIN ;then
    KEY_DEFS=(
        ['Left']='\e[D'     ['Alt-Left']='\e[1;3D'    ['Ctrl-Left']='\e[1;5D'    ['Alt-Ctrl-Up']='\e[1;7A'      ['Ctrl-Shift-Up']='\e[1;6A'     ['Shift-Up']=$undef
        ['Right']='\e[C'    ['Alt-Right']='\e[1;3C'   ['Ctrl-Right']='\e[1;5C'   ['Alt-Ctrl-Down']='\e[1;7B'    ['Ctrl-Shift-Down']='\e[1;6B'   ['Shift-Down']=$undef
        ['Up']='\e[A'       ['Alt-Up']='\e[1;3A'      ['Ctrl-Up']='\e[1;5A'      ['Alt-Ctrl-Left']='\e[1;7D'    ['Ctrl-Shift-Left']='\e[1;6D'   ['Shift-Left']='\e[1;2D'
        ['Down']='\e[B'     ['Alt-Down']='\e[1;3B'    ['Ctrl-Down']='\e[1;5B'    ['Alt-Ctrl-Right']='\e[1;7C'   ['Ctrl-Shift-Right']='\e[1;6C'  ['Shift-Right']='\e[1;2C'
        ['PgUp']='\e[5~'    ['Alt-PgUp']=$undef       ['Ctrl-PgUp']='\e[5;5~'    ['Alt-Ctrl-PgUp']=$undef       ['Ctrl-Shift-PgUp']='\e[5;6~'   ['Shift-PgUp']=$undef
        ['PgDown']='\e[6~'  ['Alt-PgDown']='\e[6;3~'  ['Ctrl-PgDown']='\e[6;5~'  ['Alt-Ctrl-PgDown']='\e[6;7~'  ['Ctrl-Shift-PgDown']='\e[6;6~' ['Shift-PgDown']=$undef
        ['Home']='\e[7~'    ['Alt-Home']='\e[1;3~'    ['Ctrl-Home']='\e[1;5~'    ['Alt-Ctrl-Home']='\e[1;7~'    ['Ctrl-Shift-Home']='\e[1;6~'   ['Shift-Home']=$undef
        ['End']='\e[8~'     ['Alt-End']='\e[4;3~'     ['Ctrl-End']='\e[4;5~'     ['Alt-Ctrl-End']='\e[4;7~'     ['Ctrl-Shift-End']='\e[4;6~'    ['Shift-End']=$undef
        ['Ins']='\e[2~'     ['Alt-Ins']='\e[2;3~'     ['Ctrl-Ins']='\e[2;5~'     ['Alt-Ctrl-Ins']='\e[2;7~'     ['Ctrl-Shift-Ins']='\e[2;6~'    ['Shift-Ins']='\e[2;2~'
        ['Del']='\e[3~'     ['Alt-Del']='\e[3;3~'     ['Ctrl-Del']='\033[3;5~'   ['Alt-Ctrl-Del']=$undef        ['Ctrl-Shift-Del']='\e[3;6~'    ['Shift-Del']='\e[3;2~'
        ['F1']='\eOP'       ['Alt-F1']='\e[1;3P'      ['Ctrl-F1']='\e[1;5P'      ['Alt-Ctrl-F1']='\e[1;7P'      ['Ctrl-Shift-F1']='\e[1;6P'     ['Shift-F1']='\e[1;2P'
        ['F2']='\eOQ'       ['Alt-F2']='\e[1;3Q'      ['Ctrl-F2']='\e[1;5Q'      ['Alt-Ctrl-F2']='\e[1;7Q'      ['Ctrl-Shift-F2']='\e[1;6Q'     ['Shift-F2']='\e[1;2Q'
        ['F3']='\eOR'       ['Alt-F3']='\e[1;3R'      ['Ctrl-F3']='\e[25~'       ['Alt-Ctrl-F3']='\e[25;3~'     ['Ctrl-Shift-F3']='\e[25;2~'    ['Shift-F3']='\e[1;2R'
        ['F4']='\eOS'       ['Alt-F4']='\e[1;3S'      ['Ctrl-F4']='\e[26~'       ['Alt-Ctrl-F4']='\e[26;3~'     ['Ctrl-Shift-F4']='\e[26;2~'    ['Shift-F4']='\e[1;2S'
        ['F5']='\e[15~'     ['Alt-F5']='\e[15;3~'     ['Ctrl-F5']='\e[28~'       ['Alt-Ctrl-F5']='\e[28;3~'     ['Ctrl-Shift-F5']='\e[28;2~'    ['Shift-F5']='\e[15;2~'
        ['F6']='\e[17~'     ['Alt-F6']='\e[17;3~'     ['Ctrl-F6']='\e[29~'       ['Alt-Ctrl-F6']='\e[29;3~'     ['Ctrl-Shift-F6']='\e[29;2~'    ['Shift-F6']='\e[17;2~'
        ['F7']='\e[18~'     ['Alt-F7']='\e[18;3~'     ['Ctrl-F7']='\e[31~'       ['Alt-Ctrl-F7']='\e[31;3~'     ['Ctrl-Shift-F7']='\e[31;2~'    ['Shift-F7']='\e[18;2~'
        ['F8']='\e[19~'     ['Alt-F8']='\e[19;3~'     ['Ctrl-F8']='\e[32~'       ['Alt-Ctrl-F8']='\e[32;3~'     ['Ctrl-Shift-F8']='\e[32;2~'    ['Shift-F8']='\e[19;2~'
        ['F9']='\e[20~'     ['Alt-F9']='\e[20;3~'     ['Ctrl-F9']='\e[33~'       ['Alt-Ctrl-F9']='\e[33;3~'     ['Ctrl-Shift-F9']='\e[33;2~'    ['Shift-F9']='\e[20;2~'
        ['F10']='\e[21~'    ['Alt-F10']='\e[21;3~'    ['Ctrl-F10']='\e[34~'      ['Alt-Ctrl-F10']='\e[34;3~'    ['Ctrl-Shift-F10']='\e[34;2~'   ['Shift-F10']='\e[21;2~'
        ['F11']='\e[23~'    ['Alt-F11']='\e[23;3~'    ['Ctrl-F11']='\e[23;5~'    ['Alt-Ctrl-F11']='\e[23;7~'    ['Ctrl-Shift-F11']='\e[23;6~'   ['Shift-F11']='\e[23;2~'
        ['F12']='\e[24~'    ['Alt-F12']='\e[24;3~'    ['Ctrl-F12']='\e[24;5~'    ['Alt-Ctrl-F12']='\e[24;7~'    ['Ctrl-Shift-F12']='\e[24;6~'   ['Shift-F12']='\e[24;2~'
        ['Space']=' '       ['Alt-Space']='\e '       ['Ctrl-Space']='\0'        ['Alt-Ctrl-Space']='\e\0'      ['Ctrl-Shift-Space']='\302\200' ['Shift-Space']=$undef
        ['Bsp']='\C-?'      ['Alt-Bsp']='\e\C-?'      ['Ctrl-Bsp']='\37'         ['Alt-Ctrl-Bsp']='\e\37'       ['Ctrl-Shift-Bsp']='\302\237'   ['Shift-Bsp']='\C-?'
        ['Tab']='\t'        ['Alt-Tab']=$undef        ['Ctrl-Tab']='\e[1;5I'     ['Alt-Ctrl-Tab']=$undef        ['Ctrl-Shift-Tab']='\e[1;6I'    ['Shift-Tab']='\e[Z'

        ['Esc']='\e'        ['Ctrl-1']='\e[1;5q'      ['Ctrl-Shift-1']='\e[1;6q' ['Ctrl-Shift-A']='\302\201'    ['Ctrl-Shift-K']='\302\213'     ['Ctrl-Shift-V']='\302\226'
        ['Ctrl-E']='\005'   ['Ctrl-2']=$undef         ['Ctrl-Shift-2']=$undef    ['Ctrl-Shift-B']='\302\202'    ['Ctrl-Shift-L']='\302\214'     ['Ctrl-Shift-W']='\302\227'
        ['Ctrl-Y']='\031'   ['Ctrl-3']='\e[1;5s'      ['Ctrl-Shift-3']='\e[1;6s' ['Ctrl-Shift-C']='\302\203'    ['Ctrl-Shift-M']='\302\215'     ['Ctrl-Shift-X']='\302\230'
        ['Ctrl-F']='\007'   ['Ctrl-4']='\e[1;5t'      ['Ctrl-Shift-4']='\e[1;6t' ['Ctrl-Shift-D']='\302\204'    ['Ctrl-Shift-N']='\302\216'     ['Ctrl-Shift-Y']='\302\231'
        ['Ctrl-P']='\020'   ['Ctrl-5']='\e[1;5u'      ['Ctrl-Shift-5']='\e[1;6u' ['Ctrl-Shift-E']='\302\205'    ['Ctrl-Shift-O']='\302\217'     ['Ctrl-Shift-Z']='\302\232'
        ['Ctrl-A']='\001'   ['Ctrl-6']='\036'         ['Ctrl-Shift-6']=$undef    ['Ctrl-Shift-F']='\302\206'    ['Ctrl-Shift-P']='\302\220'     ['Ctrl-Shift-U']='\302\225'
        ['Ctrl-X']='\030'   ['Ctrl-7']='\e[1;5w'      ['Ctrl-Shift-7']='\e[1;6w' ['Ctrl-Shift-G']='\302\207'    ['Ctrl-Shift-Q']='\302\221'
        ['Ctrl-B']='\002'   ['Ctrl-8']=$undef         ['Ctrl-Shift-8']=$undef    ['Ctrl-Shift-H']='\302\210'    ['Ctrl-Shift-R']='\302\222'
        ['Ctrl-N']='\016'   ['Ctrl-9']='\e[1;5y'      ['Ctrl-Shift-9']='\e[1;6y' ['Ctrl-Shift-I']='\302\211'    ['Ctrl-Shift-S']='\302\223'
        ['Ctrl-/']='\037'   ['Ctrl-0']='\e[1;5p'      ['Ctrl-Shift-0']='\e[1;6p' ['Ctrl-Shift-J']='\302\212'    ['Ctrl-Shift-T']='\302\224'
    )
else
    KEY_DEFS=(
        ['Left']='\e[D'     ['Alt-Left']='\e\e[D'     ['Ctrl-Left']=$undef       ['Alt-Ctrl-Up']='\e\eOA'       ['Ctrl-Shift-Up']=$undef        ['Shift-Up']='\eOA'
        ['Right']='\e[C'    ['Alt-Right']='\e\e[C'    ['Ctrl-Right']=$undef      ['Alt-Ctrl-Down']='\e\eOB'     ['Ctrl-Shift-Down']=$undef      ['Shift-Down']='\eOA'
        ['Up']='\e[A'       ['Alt-Up']='\e\e[A'       ['Ctrl-Up']=$undef         ['Alt-Ctrl-Left']='\e\eOD'     ['Ctrl-Shift-Left']=$undef      ['Shift-Left']='\eOA'
        ['Down']='\e[B'     ['Alt-Down']='\e\e[B'     ['Ctrl-Down']=$undef       ['Alt-Ctrl-Right']='\e\eOC'    ['Ctrl-Shift-Right']=$undef     ['Shift-Right']='\eOA'
        ['PgUp']='\e[5~'    ['Alt-PgUp']='\e\e[5~'    ['Ctrl-PgUp']=$undef       ['Alt-Ctrl-PgUp']=$undef       ['Ctrl-Shift-PgUp']=$undef      ['Shift-PgUp']=$undef
        ['PgDown']='\e[6~'  ['Alt-PgDown']='\e\e[6~'  ['Ctrl-PgDown']=$undef     ['Alt-Ctrl-PgDown']=$undef     ['Ctrl-Shift-PgDown']=$undef    ['Shift-PgDown']=$undef
        ['Home']='\e[1~'    ['Alt-Home']='\e\e[1~'    ['Ctrl-Home']=$undef       ['Alt-Ctrl-Home']=$undef       ['Ctrl-Shift-Home']=$undef      ['Shift-Home']=$undef
        ['End']='\e[4~'     ['Alt-End']='\e\e[4~'     ['Ctrl-End']=$undef        ['Alt-Ctrl-End']=$undef        ['Ctrl-Shift-End']=$undef       ['Shift-End']=$undef
        ['Ins']='\e[2~'     ['Alt-Ins']='\e\e[2~'     ['Ctrl-Ins']=$undef        ['Alt-Ctrl-Ins']=$undef        ['Ctrl-Shift-Ins']=$undef       ['Shift-Ins']=$undef
        ['Del']='\e[3~'     ['Alt-Del']='\e\e[3~'     ['Ctrl-Del']=$undef        ['Alt-Ctrl-Del']=$undef        ['Ctrl-Shift-Del']=$undef       ['Shift-Del']=$undef
        ['F1']='\e[11'      ['Alt-F1']='\e\e[1;3P'    ['Ctrl-F1']=$undef         ['Alt-Ctrl-F1']='\e\e[11'      ['Ctrl-Shift-F1']=$undef        ['Shift-F1']='\e[23~'
        ['F2']='\e[12'      ['Alt-F2']='\e\e[1;3Q'    ['Ctrl-F2']=$undef         ['Alt-Ctrl-F2']='\e\e[12'      ['Ctrl-Shift-F2']=$undef        ['Shift-F2']='\e[24~'
        ['F3']='\e[13'      ['Alt-F3']='\e\e[1;3R'    ['Ctrl-F3']=$undef         ['Alt-Ctrl-F3']='\e\e[13'      ['Ctrl-Shift-F3']=$undef        ['Shift-F3']='\e[25~'
        ['F4']='\e[14'      ['Alt-F4']='\e\e[1;3S'    ['Ctrl-F4']=$undef         ['Alt-Ctrl-F4']='\e\e[14'      ['Ctrl-Shift-F4']=$undef        ['Shift-F4']='\e[26~'
        ['F5']='\e[15~'     ['Alt-F5']='\e\e[15;3~'   ['Ctrl-F5']=$undef         ['Alt-Ctrl-F5']='\e\e[15~'     ['Ctrl-Shift-F5']=$undef        ['Shift-F5']='\e[28~'
        ['F6']='\e[17~'     ['Alt-F6']='\e\e[17;3~'   ['Ctrl-F6']=$undef         ['Alt-Ctrl-F6']='\e\e[17~'     ['Ctrl-Shift-F6']=$undef        ['Shift-F6']='\e[29~'
        ['F7']='\e[18~'     ['Alt-F7']='\e\e[18;3~'   ['Ctrl-F7']=$undef         ['Alt-Ctrl-F7']='\e\e[18~'     ['Ctrl-Shift-F7']=$undef        ['Shift-F7']='\e[31~'
        ['F8']='\e[19~'     ['Alt-F8']='\e\e[19;3~'   ['Ctrl-F8']=$undef         ['Alt-Ctrl-F8']='\e\e[19~'     ['Ctrl-Shift-F8']=$undef        ['Shift-F8']='\e[32~'
        ['F9']='\e[20~'     ['Alt-F9']='\e\e[20;3~'   ['Ctrl-F9']=$undef         ['Alt-Ctrl-F9']='\e\e[20~'     ['Ctrl-Shift-F9']=$undef        ['Shift-F9']='\e[34~'
        ['F10']='\e[21~'    ['Alt-F10']='\e\e[21;3~'  ['Ctrl-F10']=$undef        ['Alt-Ctrl-F10']='\e\e[21~'    ['Ctrl-Shift-F10']=$undef       ['Shift-F10']=$undef
        ['F11']='\e[23~'    ['Alt-F11']='\e\e[23;3~'  ['Ctrl-F11']=$undef        ['Alt-Ctrl-F11']='\e\e[23~'    ['Ctrl-Shift-F11']=$undef       ['Shift-F11']=$undef
        ['F12']='\e[24~'    ['Alt-F12']='\e\e[24;3~'  ['Ctrl-F12']=$undef        ['Alt-Ctrl-F12']='\e\e[24~'    ['Ctrl-Shift-F12']=$undef       ['Shift-F12']=$undef
        ['Space']=' '       ['Alt-Space']='\e '       ['Ctrl-Space']=$undef      ['Alt-Ctrl-Space']=$undef      ['Ctrl-Shift-Space']=$undef     ['Shift-Space']=$undef
        ['Bsp']='\C-?'      ['Alt-Bsp']='\e\C-?'      ['Ctrl-Bsp']=$undef        ['Alt-Ctrl-Bsp']=$undef        ['Ctrl-Shift-Bsp']=$undef       ['Shift-Bsp']=$undef
        ['Tab']='\t'        ['Alt-Tab']=$undef        ['Ctrl-Tab']=$undef        ['Alt-Ctrl-Tab']=$undef        ['Ctrl-Shift-Tab']=$undef       ['Shift-Tab']=$undef

        ['Esc']='\e'        ['Ctrl-1']=$undef         ['Ctrl-Shift-1']=$undef    ['Ctrl-Shift-A']=$undef        ['Ctrl-Shift-K']=$undef         ['Ctrl-Shift-U']=$undef
        ['Ctrl-E']='\005'   ['Ctrl-2']=$undef         ['Ctrl-Shift-2']=$undef    ['Ctrl-Shift-B']=$undef        ['Ctrl-Shift-L']=$undef         ['Ctrl-Shift-V']=$undef
        ['Ctrl-Y']='\024'   ['Ctrl-3']=$undef         ['Ctrl-Shift-3']=$undef    ['Ctrl-Shift-C']=$undef        ['Ctrl-Shift-M']=$undef         ['Ctrl-Shift-W']=$undef
        ['Ctrl-F']='\006'   ['Ctrl-4']=$undef         ['Ctrl-Shift-4']=$undef    ['Ctrl-Shift-D']=$undef        ['Ctrl-Shift-N']=$undef         ['Ctrl-Shift-X']=$undef
        ['Ctrl-P']='\020'   ['Ctrl-5']=$undef         ['Ctrl-Shift-5']=$undef    ['Ctrl-Shift-E']=$undef        ['Ctrl-Shift-O']=$undef         ['Ctrl-Shift-Y']=$undef
        ['Ctrl-A']='\001'   ['Ctrl-6']=$undef         ['Ctrl-Shift-6']=$undef    ['Ctrl-Shift-F']=$undef        ['Ctrl-Shift-P']=$undef         ['Ctrl-Shift-Z']=$undef
        ['Ctrl-X']='\030'   ['Ctrl-7']=$undef         ['Ctrl-Shift-7']=$undef    ['Ctrl-Shift-G']=$undef        ['Ctrl-Shift-Q']=$undef
        ['Ctrl-B']='\002'   ['Ctrl-8']=$undef         ['Ctrl-Shift-8']=$undef    ['Ctrl-Shift-H']=$undef        ['Ctrl-Shift-R']=$undef
        ['Ctrl-N']='\016'   ['Ctrl-9']=$undef         ['Ctrl-Shift-9']=$undef    ['Ctrl-Shift-I']=$undef        ['Ctrl-Shift-S']=$undef
        ['Ctrl-/']='\037'   ['Ctrl-0']=$undef         ['Ctrl-Shift-0']=$undef    ['Ctrl-Shift-J']=$undef        ['Ctrl-Shift-T']=$undef
    )
fi

declare _key=
declare _bindOption=
declare _macroDef=

function _getKey() {
    _key=
    local keyName="${1:?'Missing keyName'}"
    -n "${KEY_DEFS["$keyName"]}" && {
        _key="${KEY_DEFS["$keyName"]}"
        return
    }
    -rlike "$keyName" 'Alt-(.)' && {
        _key='\e'"${BASH_REMATCH[1],,}"
        return
    }
    -rlike "$keyName" 'Alt-Shift-([a-zA-Z])' && {
        _key='\e'"${BASH_REMATCH[1]^^}"
        return
    }
    -z KEY_DEFS["$keyName"] && stderr "Unknown key: $keyName"
    return 1
}

function _getMacro() {
    _macroDef= _bindOption=
    local macroName="${1:?'Missing macroName'}"
    -n "${KEY_MACROS["$macroName"]}" && {
        _macroDef="${KEY_MACROS["$macroName"]}"
        return
    }
    -n "${KEY_EXECUTABLES["$macroName"]}" && {
        _macroDef="${KEY_EXECUTABLES["$macroName"]}"
        _bindOption='-x'
        return
    }
    stderr "Unknown macro: $macroName"
    return 1
}

function _doBind() {
    : "${_bindOption?}" "${_key:?}" "${_macroDef:?}"
    bind $_bindOption "\"$_key\": $_macroDef"
}

function def-macro() {
    -eq "$1" --help && echo -e "Usage: $FUNCNAME NAME DEFINITION...\nExample:$FUNCNAME display-help @end-of-line ' --help' @accept-line" && return
    local name="${1:?'Missing macro'}"
    local executable
    -eq "$2" '-x' && executable=1 && shift
    : "${2?'Missing macro definition'}"
    local def
    for part in "${@:2}" ;do
        if -rlike "$part" '@(.*)' ;then
            local macroName="${BASH_REMATCH[1]}"
            _getMacro "$macroName" || return 1
            _key="${KEY_PLACEHOLDERS["$macroName"]}"
            -z "$_key" && {
                _key='\e['$(( 99 - ${#KEY_PLACEHOLDERS[@]} ))'~'
                KEY_PLACEHOLDERS["$macroName"]="$_key"
                _doBind
            }
            def+="${KEY_PLACEHOLDERS[$macroName]}"
        else
            def+="$part"
            -n "$executable" && def+=' '
        fi
    done
    if -n "$executable" ;then
        KEY_EXECUTABLES["$name"]="\"${def% }\""
    else
        KEY_MACROS["$name"]="\"$def\""
    fi
}

function bind-macro() {
    -eq "$1" --help && echo -e "Usage: $FUNCNAME NAME KEYSTROKE...\nExample:$FUNCNAME display-help F1 Alt-H" && return
    local macroName="${1:?'Missing macro'}"
    : "${2:?'Missing hotkeys'}"
    _getMacro "$macroName" || return 1
    for keyName in ${@:2} ;do
        _getKey "$keyName" || continue
        _doBind && KEY_BINDINGS["$keyName"]="$macroName"
    done
}

function bindings() {
    for keyName in "${!KEY_BINDINGS[@]}" ;do
        printf "%30s  $colorWhite%s$plainText\n" "${KEY_BINDINGS["$keyName"]}" "$keyName"
    done | sort -k 2
}

def-macro do-nothing            ''
def-macro test                  '<ok>'
def-macro help                  @end-of-line ' --help' @accept-line
def-macro clear-line            @kill-line @unix-line-discard
def-macro prev-cmd-1st-word     '!:0' @magic-space
def-macro prev-cmd-2nd-word     '!:1' @magic-space
def-macro prev-cmd-3rd-word     '!:2' @magic-space
def-macro prev-cmd-4th-word     '!:3' @magic-space
def-macro prev-cmd-5th-word     '!:4' @magic-space
def-macro prev-cmd-6th-word     '!:5' @magic-space
def-macro prev-cmd-7th-word     '!:6' @magic-space
def-macro prev-cmd-8th-word     '!:7' @magic-space
def-macro prev-cmd-9th-word     '!:8' @magic-space
def-macro prev-cmd-last-word    '!$'  @magic-space
def-macro prev-cmd-all-args     '!:*' @magic-space
def-macro next-word             @forward-word @forward-word @backward-word
def-macro previous-word         @backward-word @backward-word @forward-word
#def-macro previous-dir-cmd      -x 'cd -'
def-macro previous-dir          @clear-line 'cd -' @accept-line
#def-macro parent-dir-cmd        -x 'cd ..'
def-macro parent-dir            @clear-line 'cd ..' @accept-line
#def-macro home-dir-cmd          -x 'cd'+
def-macro home-dir              @clear-line 'cd' @accept-line
def-macro child-dir             'cd \t'

bind-macro do-nothing               F1            F2            F3            F4            F5            F6            F7            F8            F9            F10            F11            F12
bind-macro do-nothing           Alt-F1        Alt-F2        Alt-F3        Alt-F4        Alt-F5        Alt-F6        Alt-F7        Alt-F8        Alt-F9        Alt-F10        Alt-F11        Alt-F12
bind-macro do-nothing          Ctrl-F1       Ctrl-F2       Ctrl-F3       Ctrl-F4       Ctrl-F5       Ctrl-F6       Ctrl-F7       Ctrl-F8       Ctrl-F9       Ctrl-F10       Ctrl-F11       Ctrl-F12
bind-macro do-nothing      Alt-Ctrl-F1   Alt-Ctrl-F2   Alt-Ctrl-F3   Alt-Ctrl-F4   Alt-Ctrl-F5   Alt-Ctrl-F6   Alt-Ctrl-F7   Alt-Ctrl-F8   Alt-Ctrl-F9   Alt-Ctrl-F10   Alt-Ctrl-F11   Alt-Ctrl-F12
bind-macro do-nothing         Shift-F1      Shift-F2      Shift-F3      Shift-F4      Shift-F5      Shift-F6      Shift-F7      Shift-F8      Shift-F9      Shift-F10      Shift-F11      Shift-F12
bind-macro do-nothing    Ctrl-Shift-F1 Ctrl-Shift-F2 Ctrl-Shift-F3 Ctrl-Shift-F4 Ctrl-Shift-F5 Ctrl-Shift-F6 Ctrl-Shift-F7 Ctrl-Shift-F8 Ctrl-Shift-F9 Ctrl-Shift-F10 Ctrl-Shift-F11 Ctrl-Shift-F12
bind-macro do-nothing    Ctrl-Shift-A Ctrl-Shift-B Ctrl-Shift-C Ctrl-Shift-D Ctrl-Shift-E Ctrl-Shift-F Ctrl-Shift-G Ctrl-Shift-H Ctrl-Shift-I Ctrl-Shift-J Ctrl-Shift-K Ctrl-Shift-L Ctrl-Shift-M
bind-macro do-nothing    Ctrl-Shift-N Ctrl-Shift-O Ctrl-Shift-P Ctrl-Shift-Q Ctrl-Shift-R Ctrl-Shift-S Ctrl-Shift-T Ctrl-Shift-U Ctrl-Shift-V Ctrl-Shift-W Ctrl-Shift-X Ctrl-Shift-Y Ctrl-Shift-Z
bind-macro do-nothing    Ctrl-Shift-1 Ctrl-Shift-2 Ctrl-Shift-3 Ctrl-Shift-4 Ctrl-Shift-5 Ctrl-Shift-6 Ctrl-Shift-7 Ctrl-Shift-8 Ctrl-Shift-9 Ctrl-Shift-0
bind-macro do-nothing          Ctrl-1       Ctrl-2       Ctrl-3       Ctrl-4       Ctrl-5       Ctrl-6       Ctrl-7       Ctrl-8       Ctrl-9       Ctrl-0

bind-macro backward-char            Left
bind-macro forward-char             Right
bind-macro backward-word            Ctrl-Left
bind-macro forward-word             Alt-Right
bind-macro previous-word            Alt-Left
bind-macro next-word                Ctrl-Right
bind-macro backward-delete-char     Bsp
bind-macro delete-char              Del
bind-macro backward-kill-word       Alt-Ctrl-Left
bind-macro kill-word                Alt-Ctrl-Right
bind-macro beginning-of-line        Home
bind-macro end-of-line              End
bind-macro unix-line-discard        Alt-Bsp
bind-macro kill-line                Alt-Del
bind-macro clear-line               Alt-Ctrl-Down    Esc

bind-macro undo                     Alt-Z      Ctrl-Shift-Z
bind-macro paste-from-clipboard     Alt-V
bind-macro magic-space              Alt-Space
bind-macro menu-complete            Ctrl-Down  Ctrl-Shift-Down
bind-macro menu-complete-backward   Ctrl-Up    Ctrl-Shift-Up

bind-macro history-search-forward   Alt-Down
bind-macro history-search-backward  Alt-Up

bind-macro insert-comment           'Alt-#'

bind-macro help                     F1
bind-macro prev-cmd-1st-word        Alt-1
bind-macro prev-cmd-2nd-word        Alt-2
bind-macro prev-cmd-3rd-word        Alt-3
bind-macro prev-cmd-4th-word        Alt-4
bind-macro prev-cmd-5th-word        Alt-5
bind-macro prev-cmd-6th-word        Alt-6
bind-macro prev-cmd-7th-word        Alt-7
bind-macro prev-cmd-8th-word        Alt-8
bind-macro prev-cmd-9th-word        Alt-9
bind-macro prev-cmd-last-word       Alt-0      'Alt-`'
bind-macro prev-cmd-all-args        Alt--
bind-macro previous-dir             Alt-End    Ctrl-End
bind-macro parent-dir               PgUp
bind-macro child-dir                PgDown
bind-macro home-dir                 Alt-Home   Ctrl-Home

bind "set completion-ignore-case on"
bind "set completion-map-case on"
bind "set show-all-if-ambiguous on"
bind "set completion-query-items 1000"

unset _key
unset _bindOption
unset _macroDef

# TODO command generating .inputrc for legacy systems