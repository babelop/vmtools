#!/bin/bash
#
#  fqdn-tool.sh
#  ----------------------------------------------------------------------
#  Copyright (c) 2012  code.binbab.com
#
#        AUTHORSHIP HASH: d9ad194b974b1b834181c49860589110b37a9c1f
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#    http://www.fsf.org/licenses/gpl.txt
#  ----------------------------------------------------------------------

RELEASE="2012-08-30"
#
#  The latest version of this script is available at
#    http://www.binbab.com/code
#  ----------------------------------------------------------------------
#  This assists with setting a machine's FQDN.
#
#  USAGE:
#    See "./fqdn-tool.sh --help" for more information.
#  ----------------------------------------------------------------------


#########################################################################
###### CONFIGURATION ####################################################

NETW_FILE="/etc/sysconfig/network"
HOST_FILE="/etc/hosts"
HOST_FILE_TMP="/tmp/hosts.new"

###### END CONFIG #######################################################
#########################################################################

shopt -s extglob

function error() {
    echo ERROR: $1
    exit 1
}

function printUsage() {
    echo "USAGE: $0 OPTION"
    echo "  Use --help for more information and a list of options."
    echo
    exit 1
}

function printHelp() {
    echo "$0 - Help Information"
    echo
    echo "MAIN FUNCTIONS:"
    echo "  --new-value=FQDN               # Set new fqdn."
    echo
    echo "CURRENT CONFIG:"
    for i in NETW_FILE HOST_FILE 
    do
        echo "  ${i} = ${!i}"
    done
    echo
    exit 1
}

function askYN() {
    PROMPT="${1?}"
    YN=""
    while [ -z "${YN}" ] ; do
        read -p"${PROMPT} [y/n]: " YN
        case $YN in
            y) return 0 ;;
            n) return 1 ;;
            *) YN="" ;;
        esac
    done
}

function setFQDN() {
	NEW_FQDN=${1:?}
	NEW_FQDN_SHORT=${1%%.*}
	OLD_FQDN=$(hostname 2> /dev/null)
	OLD_FQDN_SHORT=$(hostname -s 2> /dev/null)
	
	echo
	echo "********** UPDATING FQDN **********"
	echo
	echo "Old host: ${OLD_FQDN_SHORT} (${OLD_FQDN})"
	echo "New host: ${NEW_FQDN_SHORT} (${NEW_FQDN})"
	echo
	
	echo "+ Updating ${NETW_FILE}"
	echo
	
	sed -i "s/HOSTNAME=.*/HOSTNAME=${NEW_FQDN}/" "${NETW_FILE}"
	
	echo "+ Updating ${HOST_FILE}"
	echo
	
	if [ "z${OLD_FQDN%%localhost*}" != "z" ] ; then
	  cp /etc/hosts /tmp/hosts.bak
	  sed -i "/^127.*${OLD_FQDN}/d" /etc/hosts
	fi
	echo "127.0.0.1   ${NEW_FQDN} ${NEW_FQDN_SHORT}" > "${HOST_FILE_TMP}"
	cat "${HOST_FILE}" >> "${HOST_FILE_TMP}"
	cat "${HOST_FILE_TMP}" > "${HOST_FILE}"
	rm -f "${HOST_FILE_TMP}" &> /dev/null
	hostname "${NEW_FQDN}"
	
	echo "FQDN UPDATED."
	echo
}


#########################################################################
### MAIN ################################################################

cd $(dirname $0)
SCRIPT_DIR=$(pwd)
SCRIPT_NAME=$(basename $0)
SCRIPT_PATH="${SCRIPT_DIR}/${SCRIPT_NAME}"

(( "$#" )) || printUsage

while (( "$#" )); do
case $1 in 

    --new-value=*)
            setFQDN "${1##*=}"
            ;;

    --help)
            printHelp
            ;;
            
    --*)
            printUsage
            ;;

esac
shift
done
