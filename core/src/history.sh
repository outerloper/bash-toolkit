#!/usr/bin/env bash

require macros.sh

function filter-history() {
   history -a
   history -c
   history -r
   history | g -i "$1" | sort -r -k 2 | uniq -f 1 | sort | tail -30
   say 'Type instruction number and press Ctrl-Space.'
}

HISTCONTROL=ignorespace:ignoredups # :erasedups # no erasedups - make history numbers change as rarely as possible
HISTFILESIZE=1000
HISTSIZE=1000
HISTTIMEFORMAT=""
on-prompt 'history -a;history -c;history -r' # having common history for concurrent sessions
shopt -s histappend

def-macro filter-history @beginning-of-line ' filter-history "' @end-of-line '"' @accept-line
bind-macro filter-history Alt-Ctrl-Up
def-macro apply-history @beginning-of-line '!' @forward-word @magic-space
bind-macro apply-history Ctrl-Space
