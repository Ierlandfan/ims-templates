#!/bin/bash
# TISMI 2021
# Ronald Brakeboer
# Version 1.2
# Based on the https://open5gs.org/open5gs/docs/tutorial/02-VoLTE-setup 
# This script is rebuild to do a full automated pcscf install

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
sudo make cfg
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
CREATE DATABASE  \`pcscf\`;
EOF
cd /usr/local/src/kamailio/utils/kamctl/mysql
sudo mysql -u root -p pcscf < standard-create.sql
sudo mysql -u root -p pcscf < presence-create.sql
sudo mysql -u root -p pcscf < ims_usrloc_pcscf-create.sql
sudo mysql -u root -p pcscf < ims_dialog-create.sql
sudo mysql << EOF
grant delete,insert,select,update on pcscf.* to pcscf@localhost identified by \'heslo\';
GRANT ALL PRIVILEGES ON pcscf.* TO \'pcscf\'@\'%\' identified by \'heslo\';
flush privileges;
exit;
EOF

#sudo git clone some-tismi-git-location where the modules.lst is to /usr/local/src/kamailio/src 

#for now sudo git clone https://github.com/Ierlandfan/ims-templates
cd /usr/local/src/
sudo git clone https://github.com/Ierlandfan/ims-templates

cd /usr/local/src/kamailio
export RADCLI=1
sudo make Q=0 all | sudo tee make_all.txt
sudo make install | sudo tee make_install.txt
sudo ldconfig

#sudo cp some-tismi-git-location where the kamailio is kamilio to /etc/init.d/kamailio
sudo cp /usr/local/src/ims-templates/init.d/kamailio /etc/init.d/kamailio
sudo chmod 755 /etc/init.d/kamailio

#sudo cp some-tismi-git-location where the kamailio is kamailio.default /etc/default/kamailio
sudo cp /usr/local/src/ims-templates/default/kamailio /etc/default/kamailio
systemctl daemon-reload
sudo  mkdir -p /var/run/kamailio
sudo adduser --quiet --system --group --disabled-password \
        --shell /bin/false --gecos "Kamailio" \
        --home /var/run/kamailio kamailio
sudo chown kamailio:kamailio /var/run/kamailio
cd /usr/local/src/ 
sudo wget https://dfx.at/rtpengine/latest/pool/main/r/rtpengine-dfx-repo-keyring/rtpengine-dfx-repo-keyring_1.0_all.deb 
sudo dpkg -i rtpengine-dfx-repo-keyring_1.0_all.deb
sudo echo "deb [signed-by=/usr/share/keyrings/dfx.at-rtpengine-archive-keyring.gpg] https://dfx.at/rtpengine/10.2 buster main" | sudo tee /etc/apt/sources.list.d/dfx.at-rtpengine.list
sudo apt update
sudo apt install rtpengine 
#sudo cp some-tismi-git-location where the rtpengine.conf is to /etc/rtpengine/
sudo cp -r /usr/local/src/ims-templates/rtpengine.conf /etc/rtpengine/
sudo systemctl restart rtpengine
#sudo cp some-tismi-git-location where the pcscf-template-config is and template script to /usr/local/etc/kamailio
sudo cp -r /usr/local/src/ims-templates/pcscf01-git-config/kamailio* /usr/local/etc/kamailio
cd /usr/local/etc/kamailio
sudo sh configurator-ims.sh
wait
#sudo /usr/local/etc/kamailio
sudo kamdbctl create

sudo systemctl start kamailio
