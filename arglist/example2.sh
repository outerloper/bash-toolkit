#!/bin/bash

. arglist.sh

dbConnect="host"
dbConnect_help='db-connect'
dbConnect_main='main-arg'
dbConnect_main_arity=1
dbConnect_main_required=yes
dbConnect_main_description='yes'
dbConnect_main_completion='yes no'
dbConnect_host="host"
dbConnect_host_arity=1
dbConnect_host_default="localhost"
enableAutocompletion dbConnect

function db-connect() {
   getArgs dbConnect $@ && printArgs dbConnect
}
