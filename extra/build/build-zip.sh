#!/bin/bash
#tar cfv smart-proxy.tar --exclude .git --exclude log/* --exclude *.pem --exclude *.bak --exclude Kdynamic* --exclude .project --exclude .loadpath smart-proxy
zip -r smart-proxy smart-proxy -x smart-proxy/.git/\* \*.log \*.pem \*.bak smart-proxy/config/Kdynamic\* smart-proxy/.project smart-proxy/.loadpath smart-proxy/extra/build-package.sh
