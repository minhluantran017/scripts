#!/bin/bash
ERROR=$'\e[1;31m'ERROR$'\e[0m':
INFO=$'\e[1;32m'INFO$'\e[0m':
WARNING=$'\e[1;33m'WARNING$'\e[0m':
DEBUG=$'\e[1;34m'DEBUG$'\e[0m':

if [[ -z $WORKSPACE ]]; then WORKSPACE=`dirname $0/../..`; fi

function downloadFile {
    if [[ $# -ne 2 ]]; then return 1 ; fi
    local SOURCE_URL=$1
    local DEST_FOLDER=$2
    if [[ ! -d $DEST_FOLDER ]]; then mkdir -p $DEST_FOLDER ; fi
    wget -q -r -np -nd -P $DEST_FOLDER $SOURCE_URL
}