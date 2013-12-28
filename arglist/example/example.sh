#!/bin/bash

. ../src/arglist.sh

options="user password operations"
options_help='connect-db'
options_help_description='This is arglist.sh demo.'
options_main='database name'
options_main_required=yes
options_main_arity=1
options_main_completion='foo bar baz qux quxx'
options_main_description='Name of a database'
options_user=user
options_user_arity=1
options_user_required=yes
options_user_description='User name'
options_user_completion='root guest'
options_password=password
options_password_description='Whether to provide a password'
options_operations=operations
options_operations_arity=n
options_operations_required=no
options_operations_description='Operations allowed'
options_operations_completion='create retrieve update delete'
options_operations_default='retrieve'
enableAutocompletion options

function connect-db() {
   getArgs options $@ || return $?
   printArgs options
}
