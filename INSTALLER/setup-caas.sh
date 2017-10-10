#!/bin/bash

#########
FRESH="YES"                 ## If no, existing Caas will be removed!!                  
BASE="/srv/ibm-caas2"
ICP_RELEASE="2.1.0-beta-2"
MASTER_IP="CHANGE-ME"       ## CE Edition doesnt allow HA-cluster
PROXY_IP="CHANGE-ME"        ## Multiple Proxies can be used in CE Edition
CLUSTER_DOMAIN="prodcluster.local"
CLUSTER_NAME="caas01"
COMPANY="newCO"
PRODUCT="CaaS"
SSH_KEY_EXIST="/root/.ssh/mycaasmgmtkey4096"  #use existing ssh key (will be used for ssh public-key auth!)
DEBUG="FALSE"               # Set it to true if you are new to the IBM ICP setup
ICP_HOSTS="/root/icp_hosts" #add a file with ICP hosts or leave it empty
#########
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

if [ "${MASTER_IP}" == "CHANGE-ME" ]; then
  echo ""
  echo -e "$COL_RED ## PLEASE, adjust base vars virst !! ## $COL_RESET"
  exit 1
fi

if [ "${FRESH}" == "YES" ]; then
### pre-req
if [ ! -d "${BASE}" ]; then
  mkdir -p ${BASE}
fi

if [ ! -f "$SSH_KEY_EXIST" ]; then
   ssh-keygen -t rsa -b 4096 -N "" -f /root/.ssh/mycaasmgmtkey4096
   cat /root/.ssh/mycaasmgmtkey4096.pub >> ~/.ssh/authorized_keys
fi


### IBM ICP CE Install
echo -e "$COL_MAGENTA ## Pull initial IBM ICP Installer Docker image.. $COL_RESET"

docker pull ibmcom/icp-inception:${ICP_RELEASE}
cd ${BASE}
docker run -e LICENSE=accept \
-v "$(pwd)":/data ibmcom/icp-inception:${ICP_RELEASE} cp -r cluster /data

echo -e "$COL_MAGENTA ## Adjust necessary config in ${BASE}/cluster directory... $COL_RESET"
### configuration
cd ${BASE}/cluster
cp config.yaml config.yaml.ORIG
if [ -f "$SSH_KEY_EXIST" ]; then
   cp "$SSH_KEY_EXIST" ssh_key
else
  cp /root/.ssh/caasid_rsa4096 ssh_key
fi

#
if [ ! -z "$ICP_HOSTS" ]; then
  cp "$ICP_HOSTS" ${BASE}/cluster/hosts
  echo -e "$COL_YELLOW ## Don't forget to copy the new public RSA4096-ssh-key to all nodes in authorized_keys!! $COL_RESET"
  sleep 5
fi
#
if [ -z "$ICP_HOSTS" ]; then
echo "[master]
${MASTER_IP}

[worker]
${MASTER_IP}

[proxy]
${PROXY_IP}
" >hosts
fi
#
echo "network_cidr: 10.1.0.0/16
service_cluster_ip_range: 10.0.0.1/24
#
default_admin_user: admin
default_admin_password: SecAdminChange
#
secure_connection_enabled: true
#
cluster_domain: ${CLUSTER_DOMAIN}
cluster_name: ${CLUSTER_NAME}
#
metering_enabled: true
" >config.yaml
#
if [ "${DEBUG}" == "TRUE" ]; then
 printf "\n### OKAY. please verify all ICP configs and than proceed manual!\n"
 exit 1 
else
 echo -e "$COL_MAGENTA ## NOW, we will start the installer, depending on you node, it will take at least 10min... $COL_RESET"
 echo -e "$COL_MAGENTA ## YOU HAVE 10sec to interrupt now :-> $COL_RESET"
 sleep 10
 docker run -e LICENSE=accept --net=host -t -v "$(pwd)":/installer/cluster \
 ibmcom/icp-inception:${ICP_RELEASE} install
 fi

 echo -e "$COL_YELLOW ## Be aware, the are a lot of docker images to be taken care of, so wait 10 more mins, before logging in to the web ui... $COL_RESET"
 echo -e "$COL_RED ## Change Default Credentials!! admin / SecAdminChange $COL_RESET"
 sleep 4
fi


### addons
echo -e "$COL_MAGENTA ## Installing necessary addons, like HELM, ISTIO, Kubectl... $COL_RESET"
cd /tmp
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x kubectl
mv kubectl /usr/local/bin/
#
cd /tmp
curl -L https://git.io/getIstio | sh -
chmod +x istio-*/bin/istioctl && cp -p istio-*/bin/istioctl /usr/local/bin
#
echo 'kubectl get pods' >>/root/.bashrc
#

### customize ibm main http container
#docker inspect `docker ps |grep "icp-router" |grep -v "elastics" |cut -d" " -f1`
echo -e "$COL_MAGENTA ## Customizing IBM ICP Branding in the web-ui... $COL_RESET"
for i in `find /var/lib/docker -name "index.[0-9]*.js"`
do
  #adjust javascript
  sed -i "s/IBM/${COMPANY}/g" $i
  sed -i "s/private-ce/${PRODUCT}/g" $i
  #adjust main index.html
  index="$(echo ${i} | cut -d"/" -f1-13)"
  sed -i "s/IBM/${COMPANY}/g" $index/index.html
  sed -i "s/private-ce/${PRODUCT}/g" $index/index.html
  sed -i "s/private//g" $index/index.html
done

