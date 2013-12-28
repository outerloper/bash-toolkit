#!/bin/bash

function assertLastResultEquals() {
   assertEquals $1 $?
}
