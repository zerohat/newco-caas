#!/bin/bash

########## BASE VARS
BASE_OLD="/srv/ibm-caas2"           # change to your environment
BASE_NEW="/srv/ibm-caas2-3"         # change to your environment
ICP_RELEASE_OLD="2.1.0-beta-2"      # change to your exiting running version
ICP_RELEASE_NEW="2.1.0-beta-3"      # change to the new version you want
LOG="/tmp/upgrade.log"
REMOTE_NODE=""        # Add IP(s) (with space) of additional nodes for removal
###########
# Colors
ESC_SEQ="\x1b["
COL_RESET=$ESC_SEQ"39;49;00m"
COL_RED=$ESC_SEQ"31;01m"
COL_GREEN=$ESC_SEQ"32;01m"
COL_YELLOW=$ESC_SEQ"33;01m"
COL_BLUE=$ESC_SEQ"34;01m"
COL_MAGENTA=$ESC_SEQ"35;01m"
COL_CYAN=$ESC_SEQ"36;01m"
#

if [ -d "$BASE_OLD" ]; then
  echo ""
  echo -e "$COL_YELLOW ## Removing old CaaS environment, all existing configs will be deleted - NO BACKUP! ## $COL_RESET"
  #
  cd $BASE_OLD/cluster
  docker run -e LICENSE=accept --net=host --name=installer \
    -t -v $(pwd):/installer/cluster ibmcom/icp-inception:${ICP_RELEASE_OLD} uninstall | tee $LOG
  sleep 2
  systemctl restart docker
  #
  echo -e "$COL_YELLOW ## Installing new CaaS-Release $ICP_RELEASE_NEW  ## $COL_RESET"
  #
  docker rm -f $(docker ps -aq)
  docker rmi -f $(docker images -q)
  systemctl stop docker
  rm -rf /var/lib/docker/overlay/
  systemctl start docker
  #
  if [ ! -z "$REMOTE_NODE" ]; then
    echo -e "$COL_YELLOW ## Removing Remote Nodes CaaS Install ## $COL_RESET"
    for node in `echo $REMOTE_NODE`
    do
      ssh -i $BASE_OLD/cluster/ssh_key $node "docker rm -f $(docker ps -aq)"
      ssh -i $BASE_OLD/cluster/ssh_key $node "docker rmi -f $(docker images -q)"
      ssh -i $BASE_OLD/cluster/ssh_key $node "systemctl stop docker"
      ssh -i $BASE_OLD/cluster/ssh_key $node "rm -rf /var/lib/docker/overlay/"
      ssh -i $BASE_OLD/cluster/ssh_key $node "systemctl start docker"
    done
  fi
  sleep 2
  #
  echo -e "$COL_MAGENTA ## Pull initial IBM ICP Installer Docker image.. $COL_RESET"
  #
  if [ ! -d "$BASE_NEW" ]; then
     mkdir -p "$BASE_NEW"
  fi
  #
  docker pull ibmcom/icp-inception:${ICP_RELEASE_NEW}
  cd ${BASE_NEW}
  docker run -e LICENSE=accept \
  -v "$(pwd)":/data ibmcom/icp-inception:${ICP_RELEASE_NEW} cp -r cluster /data
  #
  echo -e "$COL_MAGENTA ## Adjust necessary config in ${BASE_NEW}/cluster directory... $COL_RESET"
  ### configuration
  cd ${BASE_NEW}/cluster
  cp config.yaml config.yaml.ORIG
  cp ${BASE_OLD}/cluster/config.yml ${BASE_NEW}/cluster/
  cp ${BASE_OLD}/cluster/ssh_key ${BASE_NEW}/cluster/
  cp ${BASE_OLD}/cluster/hosts ${BASE_NEW}/cluster/
  #
  echo -e "$COL_MAGENTA ## Grab a coffee and take some time... $COL_RESET"
  docker run -e LICENSE=accept --net=host \
  -t -v "$(pwd)":/installer/cluster \
  ibmcom/icp-inception:${ICP_RELEASE_NEW} install | tee $LOG
  #
  echo ""
  echo -e "$COL_MAGENTA ## FINISHED. Take 5 more minutes before logging in.. $COL_RESET"
  echo -e "$COL_MAGENTA ## Default Dreds: admin / SecAdminChange $COL_RESET"
  echo -e "$COL_MAGENTA ## Install Log written to $LOG $COL_RESET"
  #
else
  echo ""
  echo -e "$COL_RED ## SORRY, can't find existing CaaS Installation! ## $COL_RESET"  
  exit 1
fi