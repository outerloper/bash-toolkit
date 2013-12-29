#!/bin/bash

. ../src/arglist.sh

options="times loud greetees"
options_help='greet'
options_help_description='This is arglist.sh demo.'
options_main='phrase'
options_main_required=no
options_main_arity=1
options_main_completion='hello salut privet ciao serwus ahoj'
options_main_description='Greeting phrase'
options_main_default='Hello'
options_times=times
options_times_arity=1
options_times_required=yes
options_times_description='How many times to greet'
options_times_completion='root guest'
options_loud=loud
options_loud_description='Whether to gred loudly.'
options_greetees=greetees
options_greetees_arity=n
options_greetees_required=yes
options_greetees_description='Persons to greet'
options_greetees_completion='john bob alice world'
enableAutocompletion options

function greet() {
   getArgs options $@ && printArgs options
}
