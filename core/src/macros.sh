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

${BUSH_ASSOC} KEY_DEFS
if -has "$(uname)" CYGWIN ;then
    KEY_DEFS=(
        ['Left']='\e[D'     ['Alt-Left']='\e[1;3D'    ['Ctrl-Left']='\e[1;5D'    ['Alt-Ctrl-Up']='\e[1;7A'      ['Shift-Up']=''
        ['Right']='\e[C'    ['Alt-Right']='\e[1;3C'   ['Ctrl-Right']='\e[1;5C'   ['Alt-Ctrl-Down']='\e[1;7B'    ['Shift-Down']=''
        ['Up']='\e[A'       ['Alt-Up']='\e[1;3A'      ['Ctrl-Up']='\e[1;5A'      ['Alt-Ctrl-Left']='\e[1;7D'    ['Shift-Left']='\e[1;2D'
        ['Down']='\e[B'     ['Alt-Down']='\e[1;3B'    ['Ctrl-Down']='\e[1;5B'    ['Alt-Ctrl-Right']='\e[1;7C'   ['Shift-Right']='\e[1;2C'
        ['PgUp']='\e[5~'    ['Alt-PgUp']=''           ['Ctrl-PgUp']='\033[5;5~'  ['Alt-Ctrl-PgUp']=''           ['Shift-PgUp']=''
        ['PgDown']='\e[6~'  ['Alt-PgDown']='\e[6;3~'  ['Ctrl-PgDown']='\e[6;5~'  ['Alt-Ctrl-PgDown']='\e[6;7~'  ['Shift-PgDown']=''
        ['Home']='\e[7~'    ['Alt-Home']='\e[1;3~'    ['Ctrl-Home']='\e[1;5~'    ['Alt-Ctrl-Home']='\e[1;7~'    ['Shift-Home']=''
        ['End']='\e[8~'     ['Alt-End']='\e[4;3~'     ['Ctrl-End']='\e[4;5~'     ['Alt-Ctrl-End']='\e[4;7~'     ['Shift-End']=''
        ['Ins']='\e[2~'     ['Alt-Ins']='\e[2;3~'     ['Ctrl-Ins']='\e[2;5~'     ['Alt-Ctrl-Ins']='\e[2;7~'     ['Shift-Ins']='\e[2;2~'
        ['Del']='\e[3~'     ['Alt-Del']='\e[3;3~'     ['Ctrl-Del']='\033[3;5~'   ['Alt-Ctrl-Del']=''            ['Shift-Del']='\e[3;2~'
        ['F1']='\eOP'       ['Alt-F1']='\e[1;3P'      ['Ctrl-F1']='\e[1;5P'      ['Alt-Ctrl-F1']='\e[1;7P'      ['Shift-F1']='\e[1;2P'
        ['F2']='\eOQ'       ['Alt-F2']='\e[1;3Q'      ['Ctrl-F2']='\e[1;5q'      ['Alt-Ctrl-F2']='\e[1;7Q'      ['Shift-F2']='\e[1;2Q'
        ['F3']='\eOR'       ['Alt-F3']='\e[1;3R'      ['Ctrl-F3']='\e[25~'       ['Alt-Ctrl-F3']='\e[25;3~'     ['Shift-F3']='\e[1;2R'
        ['F4']='\eOS'       ['Alt-F4']='\e[1;3S'      ['Ctrl-F4']='\e[26~'       ['Alt-Ctrl-F4']='\e[26;3~'     ['Shift-F4']='\e[1;2S'
        ['F5']='\e[15~'     ['Alt-F5']='\e[15;3~'     ['Ctrl-F5']='\e[28~'       ['Alt-Ctrl-F5']='\e[28;3~'     ['Shift-F5']='\e[15;2~'
        ['F6']='\e[17~'     ['Alt-F6']='\e[17;3~'     ['Ctrl-F6']='\e[29~'       ['Alt-Ctrl-F6']='\e[29;3~'     ['Shift-F6']='\e[17;2~'
        ['F7']='\e[18~'     ['Alt-F7']='\e[18;3~'     ['Ctrl-F7']='\e[31~'       ['Alt-Ctrl-F7']='\e[31;3~'     ['Shift-F7']='\e[18;2~'
        ['F8']='\e[19~'     ['Alt-F8']='\e[19;3~'     ['Ctrl-F8']='\e[32~'       ['Alt-Ctrl-F8']='\e[32;3~'     ['Shift-F8']='\e[19;2~'
        ['F9']='\e[20~'     ['Alt-F9']='\e[20;3~'     ['Ctrl-F9']='\e[33~'       ['Alt-Ctrl-F9']='\e[33;3~'     ['Shift-F9']='\e[20;2~'
        ['F10']='\e[21~'    ['Alt-F10']='\e[21;3~'    ['Ctrl-F10']='\e[34~'      ['Alt-Ctrl-F10']='\e[34;3~'    ['Shift-F10']='\e[21;2~'
        ['F11']='\e[23~'    ['Alt-F11']='\e[23;3~'    ['Ctrl-F11']='\e[23;5~'    ['Alt-Ctrl-F11']='\e[23;7~'    ['Shift-F11']='\e[23;2~'
        ['F12']='\e[24~'    ['Alt-F12']='\e[24;3~'    ['Ctrl-F12']='\e[24;5~'    ['Alt-Ctrl-F12']='\e[24;7~'    ['Shift-F12']='\e[24;2~'
        ['Space']=' '       ['Alt-Space']='\e '       ['Ctrl-Space']='\0'        ['Alt-Ctrl-Space']='\e\0'      ['Shift-Space']=''
        ['Bsp']='\C-?'      ['Alt-Bsp']='\e\C-?'      ['Ctrl-Bsp']='\37'         ['Alt-Ctrl-Bsp']='\e\37'       ['Shift-Bsp']='\C-?'
        ['Tab']='\t'        ['Alt-Tab']=''            ['Ctrl-Tab']='\e[1;5I'     ['Alt-Ctrl-Tab']=''            ['Shift-Tab']='\e[Z'

        ['Esc']='\e'
        ['Ctrl-E']='\005'
        ['Ctrl-Y']='\031'
        ['Ctrl-F']='\007'
        ['Ctrl-P']='\020'
        ['Ctrl-A']='\001'
        ['Ctrl-X']='\030'
        ['Ctrl-B']='\002'
        ['Ctrl-N']='\016'
        ['Ctrl-Slash']='\037'
    )
else
    KEY_DEFS=(
        ['Left']='\e[D'     ['Alt-Left']='\e\e[D'     ['Ctrl-Left']=''    ['Alt-Ctrl-Up']=''      ['Shift-Up']=''
        ['Right']='\e[C'    ['Alt-Right']='\e\e[C'    ['Ctrl-Right']=''   ['Alt-Ctrl-Down']=''    ['Shift-Down']=''
        ['Up']='\e[A'       ['Alt-Up']='\e\e[A'       ['Ctrl-Up']=''      ['Alt-Ctrl-Left']=''    ['Shift-Left']=''
        ['Down']='\e[B'     ['Alt-Down']='\e\e[B'     ['Ctrl-Down']=''    ['Alt-Ctrl-Right']=''   ['Shift-Right']=''
        ['PgUp']='\e[5~'    ['Alt-PgUp']='\e\e[5~'    ['Ctrl-PgUp']=''    ['Alt-Ctrl-PgUp']=''    ['Shift-PgUp']=''
        ['PgDown']='\e[6~'  ['Alt-PgDown']='\e\e[6~'  ['Ctrl-PgDown']=''  ['Alt-Ctrl-PgDown']=''  ['Shift-PgDown']=''
        ['Home']='\e[1~'    ['Alt-Home']='\e\e[1~'    ['Ctrl-Home']=''    ['Alt-Ctrl-Home']=''    ['Shift-Home']=''
        ['End']='\e[4~'     ['Alt-End']='\e\e[4~'     ['Ctrl-End']=''     ['Alt-Ctrl-End']=''     ['Shift-End']=''
        ['Ins']='\e[2~'     ['Alt-Ins']='\e\e[2~'     ['Ctrl-Ins']=''     ['Alt-Ctrl-Ins']=''     ['Shift-Ins']=''
        ['Del']='\e[3~'     ['Alt-Del']='\e\e[3~'     ['Ctrl-Del']=''     ['Alt-Ctrl-Del']=''     ['Shift-Del']=''
        ['F1']='\e11'       ['Alt-F1']='\e\e[1;3P'    ['Ctrl-F1']=''      ['Alt-Ctrl-F1']=''      ['Shift-F1']=''
        ['F2']='\e12'       ['Alt-F2']='\e\e[1;3Q'    ['Ctrl-F2']=''      ['Alt-Ctrl-F2']=''      ['Shift-F2']=''
        ['F3']='\e13'       ['Alt-F3']='\e\e[1;3R'    ['Ctrl-F3']=''      ['Alt-Ctrl-F3']=''      ['Shift-F3']=''
        ['F4']='\e14'       ['Alt-F4']='\e\e[1;3S'    ['Ctrl-F4']=''      ['Alt-Ctrl-F4']=''      ['Shift-F4']=''
        ['F5']='\e[15~'     ['Alt-F5']='\e\e[15;3~'   ['Ctrl-F5']=''      ['Alt-Ctrl-F5']=''      ['Shift-F5']=''
        ['F6']='\e[17~'     ['Alt-F6']='\e\e[17;3~'   ['Ctrl-F6']=''      ['Alt-Ctrl-F6']=''      ['Shift-F6']=''
        ['F7']='\e[18~'     ['Alt-F7']='\e\e[18;3~'   ['Ctrl-F7']=''      ['Alt-Ctrl-F7']=''      ['Shift-F7']=''
        ['F8']='\e[19~'     ['Alt-F8']='\e\e[19;3~'   ['Ctrl-F8']=''      ['Alt-Ctrl-F8']=''      ['Shift-F8']=''
        ['F9']='\e[20~'     ['Alt-F9']='\e\e[20;3~'   ['Ctrl-F9']=''      ['Alt-Ctrl-F9']=''      ['Shift-F9']=''
        ['F10']='\e[21~'    ['Alt-F10']='\e\e[21;3~'  ['Ctrl-F10']=''     ['Alt-Ctrl-F10']=''     ['Shift-F10']=''
        ['F11']='\e[23~'    ['Alt-F11']='\e\e[23;3~'  ['Ctrl-F11']=''     ['Alt-Ctrl-F11']=''     ['Shift-F11']=''
        ['F12']='\e[24~'    ['Alt-F12']='\e\e[24;3~'  ['Ctrl-F12']=''     ['Alt-Ctrl-F12']=''     ['Shift-F12']=''
        ['Space']=' '       ['Alt-Space']='\e '       ['Ctrl-Space']=''   ['Alt-Ctrl-Space']=''   ['Shift-Space']=''
        ['Bsp']='\C-?'      ['Alt-Bsp']='\e\C-?'      ['Ctrl-Bsp']=''     ['Alt-Ctrl-Bsp']=''     ['Shift-Bsp']=''
        ['Tab']='\t'        ['Alt-Tab']=''            ['Ctrl-Tab']=''     ['Alt-Ctrl-Tab']=''     ['Shift-Tab']=''

        ['Esc']='\e'
        ['Ctrl-E']='\005'
        ['Ctrl-Y']='\024'
        ['Ctrl-F']='\006'
        ['Ctrl-P']='\020'
        ['Ctrl-A']='\001'
        ['Ctrl-X']='\030'
        ['Ctrl-B']='\002'
        ['Ctrl-N']='\016'
        ['Ctrl-Slash']='\037'
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
        _key='\e'"${BASH_REMATCH[2],,}"
        return
    }
    -rlike "$keyName" 'Alt-Shift-([a-zA-Z])' && {
        _key='\e'"${BASH_REMATCH[2]^^}"
        return
    }
    -nv KEY_DEFS["$keyName"] && stderr "Unknown key: $keyName"
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
    -eq "$1" --help && echo -e "Usage: ${FUNCNAME[0]} NAME DEFINITION...\nExample:${FUNCNAME[0]} display-help @end-of-line ' --help' @accept-line" && return
    local name="${1:?'Missing macro'}"
    local executable
    -eq "$2" '-x' && executable=1 && shift
    : "${2?'Missing macro definition'}"
    local def
    for part in "${@:2}" ;do
        if -rlike "$part" '@(.*)' ;then
            local macroName="${BASH_REMATCH[2]}"
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
    -eq "$1" --help && echo -e "Usage: ${FUNCNAME[0]} NAME KEYSTROKE...\nExample:${FUNCNAME[0]} display-help F1 Alt-H" && return
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
#def-macro home-dir-cmd          -x 'cd'
def-macro home-dir              @clear-line 'cd' @accept-line
def-macro child-dir             'cd \t'

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

bind-macro undo                     Alt-Z
bind-macro paste-from-clipboard     Alt-V
bind-macro magic-space              Alt-Space
bind-macro menu-complete            Ctrl-Down
bind-macro menu-complete-backward   Ctrl-Up

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
bind-macro prev-cmd-last-word       Alt-0    'Alt-`'
bind-macro prev-cmd-all-args        Alt--
bind-macro previous-dir             Alt-End  Ctrl-End
bind-macro parent-dir               PgUp
bind-macro child-dir                PgDown
bind-macro home-dir                 Alt-Home Ctrl-Home

bind "set completion-ignore-case on"
bind "set show-all-if-ambiguous on"
bind "set completion-map-case on"
bind "set completion-query-items 1000"

unset _key
unset _bindOption
unset _macroDef

# TODO (???) bash 3.2 emulation for arrays: get set declare, variable expansions ^^ ,, <<<