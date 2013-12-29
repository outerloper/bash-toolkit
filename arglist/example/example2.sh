#!/bin/bash

. ../src/arglist.sh

dbConnect="host"
dbConnect_help='db-connect'
dbConnect_main_arity=1
dbConnect_main_required=yes
dbConnect_main_description='yes'
#dbConnect_main_completion='-f'
dbConnect_host_arity=1
dbConnect_host_default="localhost"
dbConnect_host_completion="f()"
enableAutocompletion dbConnect

function f() {
   echo 'localhost remote'
}

function db-connect() {
   getArgs dbConnect "$@" && printArgs dbConnect
}
