#!/bin/bash

########## BASE VARS
IP="CHANGE-ME"
HOST="CHANGE-ME"
GIT="/srv/newco"
RVM="2.4.0"
TERRAFORM="0.10.7"
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

if [ "${HOST}" == "CHANGE-ME" ]; then
  echo ""
  echo -e "$COL_RED ## PLEASE, adjust base vars virst !! ## $COL_RESET"
  exit 1
fi


### base ubuntu setup
#echo "${IP}  ${HOST}" >>/etc/hosts  ## FIX THIS!
echo "${HOST}" >/etc/hostname
#
timedatectl set-ntp no
#
apt-get -y update && apt-get upgrade && apt-get -y dist-upgrade
apt-get -y install build-essential apt-transport-https \
ca-certificates curl software-properties-common \
libreadline-dev libssl-dev libpq5 libpq-dev libreadline5 \
libsqlite3-dev libpcap-dev git-core autoconf curl zlib1g-dev \
libxml2-dev libxslt1-dev libyaml-dev unzip zip ntp
#
if [ ! -f "/usr/bin/python" ]; then
  ln -s /usr/bin/python3 /usr/bin/python
fi
#
echo "vm.max_map_count = 262144" >> /etc/sysctl.conf
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable"
apt-get -y update
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

##
echo ""
echo -e "$COL_YELLOW ## SEEMS we are done :-> ## $COL_RESET"
echo -e "$COL_GREEN ## PLEASE, reboot your server now and afterwards start setup-caas.sh ## $COL_RESET"
echo ""
# EOF

