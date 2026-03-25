#!/usr/bin/env bash

apt-get update
apt install --assume-yes --no-install-recommends --no-install-suggests \
  libperl-critic-perl \
  libtest2-suite-perl

prove /opt/spamtagger/tests/
