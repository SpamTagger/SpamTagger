#!/bin/bash

BACK=$(pwd)

exit 0

cd /usr/spamtagger/install/src

#tar -xvzf razor-agents-sdk.tar.gz
#cd razor-agents-sdk-2.03
#perl Makefile.PL 2>&1
#make 2>&1
#make install 2>&1
#cd ..
tar -xvjf razor-agents.tar.bz2
cd razor-agents-2.82
perl Makefile.PL 2>&1
make 2>&1
make install 2>&1

cd $BACK
#rm -rf /usr/spamtagger/install/src/razor-agents-sdk-2.03
rm -rf /usr/spamtagger/install/src/razor-agents-2.82

#su spamtagger -c "/usr/bin/razor-admin -discover"
