#!/bin/bash

SD=$(echo "/usr/spamtagger" | perl -pi -e 's/\//\\\//g')

perl -p -e "s/__SRCDIR__/\"$SD\"/" setuid_wrapper.c_template >setuid_wrapper.c

make

make install

make clean
