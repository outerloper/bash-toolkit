#!/usr/bin/env bash

bt-require keymap.sh

history-filter() {
   history -a
   history -c
   history -r
   history | egrep --color=always -i "$1" | sort -r -k 2 | uniq -f 1 | sort -n | tail -30
   message 'Type instruction number and press Ctrl-Space.'
}

HISTCONTROL=ignorespace:ignoredups # no erasedups - make history numbers change as rarely as possible
HISTFILESIZE=1000
HISTSIZE=1000
HISTTIMEFORMAT=""
bt-on-prompt 'history -a; history -c; history -r' # having common history when multiple shells open at the same time
shopt -s histappend

keymap-macro-def filter-history @beginning-of-line ' history-filter "' @end-of-line '"' @accept-line
keymap-bind filter-history Alt-Ctrl-Up Alt-PgUp Shift-Up Alt-Shift-Up
keymap-macro-def apply-history @beginning-of-line '!' @forward-word @magic-space
keymap-bind apply-history Ctrl-Space
