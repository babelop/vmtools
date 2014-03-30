#!/bin/bash
#
#  clone-tool.sh
#  ----------------------------------------------------------------------
#  Copyright (c) 2014  code.binbab.com
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

RELEASE="2014-03-29"
#
#  The latest version of this script is available at
#    http://www.binbab.com/code
#  ----------------------------------------------------------------------
#  This assists with the cloning of virtual machines by working around
#  common pitfalls and assisting with the setup of new clones.
#
#  USAGE:
#    See "./clone-tool.sh --help" for more information.
#  ----------------------------------------------------------------------


#########################################################################
###### CONFIGURATION ####################################################

PROFILE_SCRIPT="/etc/profile"

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
    echo "  --prep              # Prepare source VM for cloning"
    echo
    echo "CURRENT CONFIG:"
    for i in PROFILE_SCRIPT
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

function prepClone() {
    echo
    echo "PREPARING MACHINE FOR CLONING:"
    echo
    
    echo "+ Clearing logs..."
    echo
    sleep 1
    
    cat /dev/null > /var/log/messages
    cat /dev/null > /var/log/secure
    history -c && rm -f /root/.bash_history &> /dev/null
		find /home -name .bash_history -delete &> /dev/null

		if [ -e '/var/lib/cloud' ] ; then
      echo
      echo "+ Resetting cloud-init..."
      echo
      sleep 1

		  rm -Rf /var/lib/cloud/*
		fi
    
    echo
    echo "+ Resetting network config..."
    echo
    sleep 1
    
    cd /etc/sysconfig/network-scripts
    cp ifcfg-eth0 /tmp/ifcfg-eth0.bak
    cat ifcfg-eth0 | grep -v HWADDR > /tmp/ifcfg-eth0.new
    cat /tmp/ifcfg-eth0.new > ifcfg-eth0
    rm /etc/udev/rules.d/70-persistent-net.rules &> /dev/null
    
    echo
    echo "+ Setup post-clone promp..."
    echo
    
    askYN "Prompt user for post-clone VM tasks?"
    if [ $? -eq 0 ] ; then
        postCloneActivate
    else
        postCloneDeactivate
    fi
    
    echo
    echo "+ Shutting down..."
    echo
    
    askYN "Process complete, OK to shutdown?" && shutdown -h now
}

function postCloneActivate() {
    postCloneDeactivate
    echo "${SCRIPT_PATH} --post   #CLONE-TOOL" >> ${PROFILE_SCRIPT}
}

function postCloneDeactivate() {
    P0="${PROFILE_SCRIPT}"
    P1=$(mktemp -t "clone-profile.XXXXXX")
    cp $P0 $P1 || exit 1
    cat $P1 | grep -v "#CLONE-TOOL" > $P0
}

function postCloneRun() {
    if [ $(whoami) == "root" ] ; then
    	echo
        echo "***********************************************"
        echo "          CLONED MACHINE SETUP HELPER          "
        echo "***********************************************"
        echo
        askYN "Would you like help setting up this new VM?"
        if [ $? -ne 0 ] ; then
            echo
            askYN "Should I ask you again at next login?" || postCloneDeactivate
            exit
        fi
        
        postCloneDeactivate
        
        echo
        echo "+ Root password..."
        echo
        askYN "Would you like to change the root password now?"
        if [ $? -eq 0 ] ; then
            passwd
        fi     
        
        echo
        echo "+ Added storage..."
        echo
        askYN "Have you attached a larger virtual disk for more storage?"
        if [ $? -eq 0 ] ; then
        	read -p"Please enter the new device path: " NEW_DEVICE
        	${SCRIPT_DIR}/extend-root-lvm.sh --new-device="${NEW_DEVICE}"
        else
        	echo "The storage expansion tool is available later at:"
        	echo "    ${SCRIPT_DIR}/extend-root-lvm.sh"
        fi
                
        echo
        echo "+ Hostname..."
        echo
        askYN "Would you like to change the hostname now?"
        if [ $? -eq 0 ] ; then
        	read -p"Please enter the new hostname: " NEW_HN
        	${SCRIPT_DIR}/fqdn-tool.sh --new-value="${NEW_HN}"
        else
        	echo "The hostname tool is available later at:"
        	echo "    ${SCRIPT_DIR}/fqdn-tool.sh"
        fi
        
        echo
        echo "+ Chef..."
        echo
        askYN "Would you like to setup chef now?"
        if [ $? -eq 0 ] ; then
        	installChef
        else
        	echo "You can setup chef later with:"
        	echo "    ${SCRIPT_DIR}/clone-tool.sh --setup-chef"
        fi
        
        echo
        echo "SETUP COMPLETE. HAVE A NICE DAY."
        echo
        
       	askYN "Would you like to restart the system now?" && shutdown -r now
    fi
}

function installChef() {
	if [ -e "/usr/bin/chef-client" ] ; then
	    echo "Chef already installed."
	else 
		curl -L http://www.opscode.com/chef/install.sh | bash
	fi
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

    --prep)
            prepClone
            ;;
            
    --post)
            postCloneRun
            ;;
            
    --setup-chef)
    		installChef
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
