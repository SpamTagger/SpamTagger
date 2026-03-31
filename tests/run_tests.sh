#!/usr/bin/env bash

if [ "$(dpkg -l | grep -P 'lib(perl-critic|test2-suite)-perl' | wc -l)" -lt 2 ]; then
  apt-get update
  apt install --assume-yes --no-install-recommends --no-install-suggests \
    libperl-critic-perl \
    libtest2-suite-perl
fi

prove /usr/spamtagger/tests/
