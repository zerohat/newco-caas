#!/bin/bash

########## BASE VARS
IP="CHANGE-ME"
HOST="CHANGE-ME"
GIT="/srv/newco"
RVM="2.4.0"
TERRAFORM="0.10.7"
###########

if [ "${HOST}" == "CHANGE-ME" ]; then
  exit 1
  printf "\n\n# PLEASE, adjust base vars virst !!\n"
fi


### base ubuntu setup
echo "${IP}  ${HOST}" >>/etc/hosts
echo " ${HOST}" >/etc/hostname
apt-get -y update && && apt-get upgrade && apt-get -y dist-upgrade
apt-get -y install build-essential apt-transport-https \
ca-certificates curl software-properties-common \
libreadline-dev libssl-dev libpq5 libpq-dev libreadline5 \
libsqlite3-dev libpcap-dev git-core autoconf curl zlib1g-dev \
libxml2-dev libxslt1-dev libyaml-dev

#
if [ ! -f "/usr/bin/python" ]; then
  ln -s /usr/bin/python3 /usr/bin/python
fi
#
echo "vm.max_map_count = 262144" >> /etc/sysctl.conf
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable"
# docker
apt-get -y install docker-ce
echo '
{
  "storage-driver": "devicemapper"
}
' >/etc/docker/daemon.json
#
echo '
#!/bin/sh
#
printf "\n"
printf " * newCO CAAS Platform\n"
printf "_________________________________\n"
printf "\n"
#
' >/etc/update-motd.d/10-help-text
#
ssh-keygen -t rsa -b 4096 -N "" -f /root/.ssh/id_rsa4096
cat /root/.ssh/id_rsa4096.pub >> ~/.ssh/authorized_keys
##

### terraform
cd /tmp
wget -q https://releases.hashicorp.com/terraform/${TERRAFORM}/terraform_${TERRAFORM}_linux_amd64.zip
unzip terraform_${TERRAFORM}_linux_amd64.zip
mv terraform /usr/local/bin/
##

## latest rvm
curl -sSL https://rvm.io/mpapis.asc | gpg --import -
curl -sSL https://get.rvm.io | bash -s stable --rails
echo "source /usr/local/rvm/scripts/rvm" >> ~/.bashrc
source ~/.bashrc
rvm install ${RVM}
rvm use ${RVM} --default


