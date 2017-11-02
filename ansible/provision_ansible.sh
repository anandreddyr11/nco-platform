#!/bin/bash
set -ex
################################################################################
# File:    provision-ansible.sh
# Purpose: Executes ansible-playbook for the given playbook yml file
# Version: 0.1
# Author:  Jai Bapna
# Created: 2017-06-14
################################################################################


PLAYBOOK_YML_FILE=$1
export PATH=$PATH:/sbin

# we wait forever,
while true
 do
  ansiplaybookbin="/usr/bin/ansible-playbook"

  #because we're -e, we have to catch the exit..
  if $ansiplaybookbin -i "localhost," -c local  $PLAYBOOK_YML_FILE
    then
      echo "Success."
  else
    exit=$?
    echo "Chef exited: $exit"
    # if [ $exit -gt 0 ]
    #  then
      if [ -f /opt/nuxeo-ansible/ansible/Provisioning/ansible.log ]
       then
        echo
        echo "STACKTRACE:"
        cat /opt/nuxeo-ansible/ansible/Provisioning/ansible.log
        echo
        echo "ERROR: ansible-playbook exited: $exit"
        echo
        exit $exit
      fi
  fi
  break  #out of our loop
done

# exit cleanly
exit 0