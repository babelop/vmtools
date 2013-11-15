#!/bin/bash
#
#  extend-root-lvm.sh
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

RELEASE="2012-02-20"
#
#  The latest version of this script is available at
#    http://www.binbab.com/code
#  ----------------------------------------------------------------------
#  This assists with the cloning of virtual machines by working around
#  common pitfalls and assisting with the setup of new clones.
#
#  USAGE:
#    See "./extend-root-lvm.sh --help" for more information.
#  ----------------------------------------------------------------------


#########################################################################
###### CONFIGURATION ####################################################


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
    echo "COMMAND LINE OPTIONS:"
    echo "  --new-device=PATH		# Extend storage with this device"
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

function doExtend() {
	echo
	echo "************************************************"
	echo "              LVM Expansion Script              "
	echo "************************************************"
	echo
	echo The LVM logical volume lv_root will be extended
	echo with all available space on device:
	echo "     $NEW_DEVICE."
	echo
	askYN "Continue?" || exit 1
	
	echo
	echo + Creating new physical volume...
	echo
	
	lvm pvcreate $NEW_DEVICE || exit 1
	
	echo
	echo + Adding new volume to volume group...
	echo
	
	lvm vgextend VolGroup $NEW_DEVICE || exit 1
	
	echo
	echo + Extending logical volume...
	echo 
	
	lvm lvextend -l +100%FREE /dev/VolGroup/lv_root || exit 1
	
	echo
	echo + Resizing logical filesystem to recognize new capacity...
	echo
	
	resize2fs /dev/VolGroup/lv_root || exit 1
	
	echo
	echo ALL DONE.
	echo
}



#########################################################################
### MAIN ################################################################

cd $(dirname $0)
SCRIPT_DIR=$(pwd)
SCRIPT_NAME=$(basename $0)
SCRIPT_PATH="${SCRIPT_DIR}/${SCRIPT_NAME}"

NEW_DEVICE=""

(( "$#" )) || printUsage

while (( "$#" )); do
case $1 in 

    --new-device=*)
            NEW_DEVICE=${1##*=}
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

[ -z "${NEW_DEVICE}" ] && printUsage

doExtend
