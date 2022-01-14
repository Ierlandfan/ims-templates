#!/bin/bash
# TISMI 2021
# Ronald Brakeboer
# Version 1.4
# Based on the https://open5gs.org/open5gs/docs/tutorial/02-VoLTE-setup 
# This script is rebuild to do a full automated scscf install

# Initialization & global vars for setting up the configuration files for a IMS provisioning
#(E.g for PCSCSF - ICSCF or SCSCF based on the templated Kamailio IMS files Tismi are using)
# if you execute this script for the second time
# you should change these variables to the latest
# domain name and ip address

sudo apt update && sudo apt upgrade

export LC_ALL="en_US.UTF-8"
sudo locale-gen "en_US.UTF-8"
sudo dpkg-reconfigure locales
sudo apt install -y tcpdump screen ntp ntpdate git-core dkms gcc flex bison make \
libssl-dev libcurl4-openssl-dev libxml2-dev libpcre3-dev bash-completion g++ autoconf libmnl-dev libsctp-dev libradcli-dev \
libradcli4
cd /usr/local/src/
sudo git clone https://github.com/herlesupreeth/kamailio
#Insert some basic check to see if the git download went fine
[ -d "/usr/local/src/kamailio" ] && echo "Directory /usr/local/src/kamailio exists. All seems fine" || echo "Error: Directory /usr/local/src/kamailio does not exists."
cd kamailio
sudo git checkout -b 5.3 origin/5.3
sudo make PREFIX="/etc/kamailio" cfg
sudo apt install mariadb-server mariadb-common libmariadb-dev-compat libmariadb-dev
# Maybe some basic check the download went ok and mariadb is started
UP=$(/etc/init.d/mysql status | grep running | grep -v not | wc -l);
if [ "$UP" -ne 1 ];
then
        echo "MySQL is down.Trying to start again";
        service mysql start

else
        echo "All is well.";
fi

sudo mysql_secure_installation
sudo mysql << EOF
CREATE DATABASE  \`iscscf\`;
EOF
cd /usr/local/src/kamailio/utils/kamctl/mysql
sudo mysql -u root -p scscf < standard-create.sql
sudo mysql -u root -p scscf < presence-create.sql
sudo mysql -u root -p scscf < ims_usrloc_scscf-create.sql
sudo mysql -u root -p scscf < ims_dialog-create.sql
sudo mysql -u root -p scscf < ims_charging-create.sql

sudo mysql << EOF
grant delete,insert,select,update on scscf.* to scscf@localhost identified by \'heslo\';
GRANT ALL PRIVILEGES ON scscf.* TO \'scscf\'@\'%\' identified by \'heslo\';
flush privileges;
exit;
EOF


#for now sudo git clone https://github.com/Ierlandfan/ims-templates
cd /usr/local/src/
sudo git clone https://github.com/Ierlandfan/ims-templates
[ -d "/usr/local/src/ims-templates" ] && echo "Directory /usr/local/src/ims-templates exists. All seems fine" || echo "Error: Directory /usr/local/src/ims-templates does not exists." && exit 

sudo cp /usr/local/src/ims-templates/modules.lst /usr/local/src/kamailio/src/
cd /usr/local/src/kamailio
export RADCLI=1
sudo make Q=0 all | sudo tee make_all.txt
sudo make install | sudo tee make_install.txt
sudo ldconfig


sudo cp /usr/local/src/ims-templates/init.d/kamailio /etc/init.d/kamailio
sudo chmod 755 /etc/init.d/kamailio

sudo cp /usr/local/src/ims-templates/default/kamailio /etc/default/kamailio
systemctl daemon-reload
sudo  mkdir -p /var/run/kamailio
sudo adduser --quiet --system --group --disabled-password \
        --shell /bin/false --gecos "Kamailio" \
        --home /var/run/kamailio kamailio
sudo chown kamailio:kamailio /var/run/kamailio
cd /usr/local/src/ 

sudo cp -r /usr/local/src/ims-templates/scscf01-git-config/kamailio/* /usr/local/etc/kamailio
cd /usr/local/etc/kamailio

sudo sh configurator-ims.sh
wait
sudo kamdbctl create

sudo systemctl start kamailio
