#!/bin/sh -e
export PROJECT_NUMBER=`git describe --tag --dirty`
doxygen
# Files in doc/html/

