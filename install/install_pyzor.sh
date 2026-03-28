#!/bin/bash

BACK=$(pwd)

exit 0

cd /usr/spamtagger/install/src

tar -xvjf pyzor.tar.bz2
cd pyzor-0.4.0
python setup.py build 2>&1
python setup.py install 2>&1
#su spamtagger -c "pyzor discover" 2>&1

cd $BACK
rm -rf /usr/spamtagger/install/src/pyzor-0.4.0

chmod a+rx /usr/bin/pyzor
