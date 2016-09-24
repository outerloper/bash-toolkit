#!/bin/bash

require utils.sh

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

function color() {
    -help "$1" && {
        echo "Usage: $FUNCNAME COLOR_CODE OPTIONS
Prints escape sequence for COLOR_CODE changing text color. Works in terminal supporting 256 colors.
COLOR_CODE    One of:
              - @RGB - where R, G and B are digits 0-5 meaning intensity of Red, Green and Blue respectively. Example: @034
              - GN - where N is a number from color from greyscale: 0-23, greater is lighter. Example: G5
              - number from 0 to 255 - color code. 0-16 - basic colors, 237-255 - greyscale
              Any of the above value with letter 'b' appended means background color.
Options:
  -p [TEXT]   Instead of escape sequence changing color, prints colored TEXT (which by default is the sequence itself).
  -v VAR      Stores escape sequence in a variable VAR."
        return 0
    }
    local code="${1?'Missing color code'}" color ctrl=38 var print text
    shift
    while -gz $# ;do
        -eq -v "$1" && {
            shift
            -optval "$1" || {
                err 'Missing variable name'
                return 1
            }
            var="$1"
            shift
        }
        -eq -p "$1" && {
            print=1
            shift
            -optval "$1" && {
                text="$1"
                shift
            }
        }
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
        color="$code"
    elif -rlike "$code" 'G([0-9][0-9]*)' ;then
        (( code > 23 )) && {
            err "Invalid color code: $code. Maximum greyscale index is 23."
            return 1
        }
        local grey="${BASH_REMATCH[1]}"
        (( color = 255 - grey ))
    elif -rlike "$code" '@([0-5])([0-5])([0-5])' ;then
        local r="${BASH_REMATCH[1]}" g="${BASH_REMATCH[2]}" b="${BASH_REMATCH[3]}"
        (( color = 16 + r * 36 + g * 6 + b ))
    else
        err "Invalid color code: $code"
        return 1
    fi

    local seq="\e[$ctrl;5;$color"m
    echo -ne "$seq"

    if -n "$print" ;then
        echo -ne "${text:-\\$seq}$plain"
    fi

    -n "$var" && {
        set-var "$var" "$seq"
    }
}

function color-palette() {
    -help "$1" && {
        echo "Usage: $FUNCNAME [-b]
Prints available colors.
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
            color "$(( i * 8 + j ))$bg" -p -v code
            printf " $code"
        done
        echo
    done
    for i in {0..39}; do
        for j in {0..5}; do
            color "$(( 16 + i * 6 + j ))$bg" -p -v code
            printf " $code"
        done
        echo
    done
}

function printfn() { printf "${1}\n" "${@:2}"; }
function message() { printf "$styleMessage${1}$styleOff\n" "${@:2}"; }
function success() { printf "[SUCCESS] $styleSuccess${1}$styleOff\n" "${@:2}"; }
function warning() { printf "[WARNING] $styleWarning${1}$styleOff\n" "${@:2}"; }
function failure() { printf "[FAILURE] $styleFailure${1}$styleOff\n" "${@:2}"; }



styleMessage="$white"
styleSuccess="$lightGreen"
styleWarning="$lightYellow"
styleFailure="$lightRed"
styleOff="$colorOff"
em="$weightBold"
emOff="$weightOff"
q="$italic"
qOff="$italicOff"
