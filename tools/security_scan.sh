#!/usr/bin/env bash

# This script is intended to check whether there are any outstanding patches
# upstream which have yet to be applied to this system. It is primarily meant to
# be run in CI but can also be run on non-Bootc installations. For the official
# Bootc images, you should simply rely on the built-in update mechanism to patch
# any issues found by this tool, as any positive result from this script will
# open an issue in the SpamTagger-Bootc repository to prompt a rebuild with the
# new patches.

# Detect Bootc installation and bail
if [ -e /usr/bin/bootc ] && [ -z $CI ]; then
  echo "This tool is not intended for use with Bootc installations. If you have concerns about potentially unpatched vulnerabilities, please check for Bootc updates with 'bootc upgrade'. This tool is run daily via a GitHub Action and any results will open a GitHub Issue, prompting a new release of the official images as soon as they are discovered."
  exit
fi

if [ ! "$(dpkg -l | grep debsecan)" -eq "" ]; then
  echo "Installing Debian Security Analyzer..."
  apt-get update 2>&1 >/dev/null && apt-get install debsecan 2>&1 >/dev/null
fi

SUITE=$(grep 'VERSION_CODENAME=' /etc/os-release | cut -d '=' -f 2)

debsecan --suite $SUITE --format detail --only-fixed
