#!/bin/bash

require utils.sh


### Explicit style escape sequences ###

# Instead of them, whenever possible, use 'Generic style escape sequences' defined in the section below.

plain="\e[0m"
weightBold="\e[1m"
weightDim="\e[2m"
weightOff="\e[22m"
italic="\e[3m"
italicOff="\e[23m"
underline="\e[24m\e[4m"
underlineDouble="\e[24m\e[21m"
underlineBold="\e[4m\e[21m"
underlineOff="\e[24m"
blink="\e[5m"
blinkOff="\e[25m"
reverse="\e[7m"
reverseOff="\e[27m"
hidden="\e[8m"
hiddenOff="\e[8m"
strike="\e[9m"
strikeOff="\e[29m"
black="\e[30m"
blackBackground="\e[40m"
red="\e[31m"
redBackground="\e[41m"
green="\e[32m"
greenBackground="\e[42m"
yellow="\e[33m"
yellowBackground="\e[43m"
blue="\e[34m"
blueBackground="\e[44m"
magenta="\e[35m"
magentaBackground="\e[45m"
cyan="\e[36m"
cyanBackground="\e[46m"
lightGray="\e[37m"
lightGrayBackground="\e[47m"
darkGray="\e[90m"
darkGrayBackground="\e[100m"
lightRed="\e[91m"
lightRedBackground="\e[101m"
lightGreen="\e[92m"
lightGreenBackground="\e[102m"
lightYellow="\e[93m"
lightYellowBackground="\e[103m"
lightBlue="\e[94m"
lightBlueBackground="\e[104m"
lightMagenta="\e[95m"
lightMagentaBackground="\e[105m"
lightCyan="\e[96m"
lightCyanBackground="\e[106m"
white="\e[97m"
whiteBackground="\e[107m"
colorOff="\e[39m"
backgroundOff="\e[49m"


### Generic style escape sequences ###

# They may be redefined in profile.sh if needed.

styleMessage="$white"
styleSuccess="$lightGreen"
styleWarning="$lightYellow"
styleFailure="$lightRed"
styleOff="$colorOff"
em="$weightBold"
emOff="$weightOff"
q="$italic"
qOff="$italicOff"


### Functions ###

# Like printf with newline character appended
function printfn() { printf "${1}\n" "${@:2}"; }
# Printf with output styled as emphasized message
function message() { printf "$styleMessage${1}$styleOff\n" "${@:2}"; }
# Printf with output styled as success message
function success() { printf "[SUCCESS] $styleSuccess${1}$styleOff\n" "${@:2}"; }
# Printf with output styled as warning
function warning() { printf "[WARNING] $styleWarning${1}$styleOff\n" "${@:2}"; }
# Printf with output styled as error message
function failure() { printf "[FAILURE] $styleFailure${1}$styleOff\n" "${@:2}"; }

function print-styles() {
    -help "$1" && {
    echo "Usage: $FUNCNAME
Use this function to check setup of styles."
    return 0
    }
    local styleVar
    for style in message success warning failure ;do
        capitalize style
        styleVar="style"$style
        printf "This is ${!styleVar}inline $q\$$styleVar$qOff sample with $em%s$emOff and $q%s$qOff text${styleOff}. Here should go plain text again.\n" 'emphasized' 'quoted'
        echo
    done
    for fun in printfn message success warning failure ;do
        $fun "This is $q$fun$qOff function output demo with $em%s$emOff and $q%s$qOff text." 'emphasized' 'quoted'
        echo
    done
    local functions='success warning failure'
    echo "Below the following functions called without parameters - $functions:"
    echo
    for fun in $functions ;do
        $fun
        echo
    done
}

function color() {
    -help "$1" && {
        echo "Usage: $FUNCNAME COLOR_CODE OPTIONS
Prints escape sequence for COLOR_CODE changing text color. Works in terminal supporting 256 colors.
COLOR_CODE    One of:
              - @RGB - where R, G and B are digits 0-5 meaning intensity of Red, Green and Blue respectively. Example: @034
              - GN - where N is a number from color from greyscale: 0-23. Greater means brighter. Example: G5
              - number from 0 to 255 - explicit color code where: 0-16 - basic colors, 237-255 - greyscale
              To get background color, add 'b' suffix. Example: G23b
Options:
  -p [TEXT]   Instead of escape sequence changing color, prints colored TEXT (which by default is the sequence itself).
  -n [TEXT]   Like -p but does not append new line character (like -n in echo).
  -v VAR      Assigns escape sequence to VAR variable."
        return 0
    }
    local code="${1?'Missing color code'}" color ctrl=38 var print text n
    shift
    while -gz $# ;do
        case "$1" in
        -v)
            shift
            -optval "$1" || {
                err 'Missing variable name'
                return 1
            }
            var="$1"
            shift
            ;;
        -[pn])
            print=1
            -eq "$1" '-n' && n=n
            shift
            -optval "$1" && {
                text="$1"
                shift
            }
            ;;
        *)
            err "Unknown option: $1"
            return 1
        esac
    done

    if -rlike "$code" '(.*)[Bb]' ;then
        ctrl=48
        code="${BASH_REMATCH[1]}"
    fi
    if -rlike "$code" '[0-9][0-9]*' ;then
        (( code > 255 )) && {
            err "Invalid color code: $code. Maximum value is 255."
            return 1
        }
        (( color = code ))
    elif -rlike "$code" '[Gg]([0-9][0-9]*)' ;then
        local grey="${BASH_REMATCH[1]}"
        (( grey > 23 )) && {
            err "Invalid color code: $code. Maximum index on greyscale is 23."
            return 1
        }
        (( color = 255 - grey ))
    elif -rlike "$code" '@([0-5])([0-5])([0-5])' ;then
        local r="${BASH_REMATCH[1]}" g="${BASH_REMATCH[2]}" b="${BASH_REMATCH[3]}"
        (( color = 16 + r * 36 + g * 6 + b ))
    else
        err "Invalid color code: $code. For more information run: $FUNCNAME --help"
        return 1
    fi

    local seq="\e[$ctrl;5;$color"m
    echo -en "$seq"

    if -n "$print" ;then
        echo -e$n "${text:-\\$seq}$plain"
    fi

    -n "$var" && {
        set-var "$var" "$seq"
    }

    return 0
}

function color-palette() {
    -help "$1" && {
        echo "Usage: $FUNCNAME [-b]
Prints available color samples.
  -b         Background instead of foreground."
        return 0
    }
    local code bg
    -n "$1" && {
        -neq -b "$1" && {
            err "Invalid option: $1"
            return 1
        }
        bg=B
    }
    for i in {0..1}; do
        for j in {0..7}; do
            color "$(( i * 8 + j ))$bg" -n -v code
            printf " $code"
        done
        echo
    done
    for i in {0..39}; do
        for j in {0..5}; do
            color "$(( 16 + i * 6 + j ))$bg" -n -v code
            printf " $code"
        done
        echo
    done
}
