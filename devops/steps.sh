#!/bin/bash

# THIS IS ALL STEPS (e.g. COMMANDS) I'VE PERFORMED ON A FRESH
# VIRTUAL SERVER (Linux; Debian 10; 2vCPU; 4GB; SSD)
# DETAILED TUTORIAL: https://github.com/veliovgroup/meteor-snippets/tree/main/devops

apt-get update
apt-get remove sudo
apt-get dist-upgrade -s
apt-get dist-upgrade -y
apt-get install git build-essential rsync apt-transport-https ca-certificates
dpkg-reconfigure tzdata

# tune up .bash_profile
# DETAILED TUTORIAL: https://github.com/VeliovGroup/ostrio/blob/master/tutorials/linux/bash_profile-tuning.md

# Install local MongoDB
wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | apt-key add -
echo "deb http://repo.mongodb.org/apt/debian buster/mongodb-org/5.0 main" | tee /etc/apt/sources.list.d/mongodb-org-5.0.list
apt-get update
apt-get install -y mongodb-org
systemctl start mongod
systemctl enable mongod.service

# copy paste `mongod.conf` from this repo to `/etc/mongod.conf`

mkdir -p /data/mongo
chmod 777 /data
chown mongodb:mongodb /data/mongo
# CREATE MONGODB LOG-FILE
touch /var/log/mongodb/mongod.log
chown mongodb:mongodb /var/log/mongodb/mongod.log

# FOR SECURITY REASONS AND AS A PART OF "BEST PRACTICES"
# IT IS HIGHLY RECOMMENDED TO INSTALL CERTAIN APPS AND
# SPAWN CERTAIN PROCESSES AS NON-root USER, BETTER —
# USER WITH LIMITED ACCESS AND PERMISSIONS. IN OUR CASE
# USER WILL BE USED FOR Nginx, NPM, AND process spawning
#
# CREATE `appuser` USER AND ITS HOME DIRECTORY:
useradd appuser
mkdir -p /home/appuser
usermod -m -d /home/appuser appuser
chown -R appuser:appuser /home/appuser
chmod 770 /home/appuser
chsh appuser -s /bin/bash

##########################[start as appuser]#####################################
# Execute next few commands as "appuser" for security reasons
# Login to appuser's shell:
su -s /bin/bash -l appuser

# Install meteor.js
# Execute this command as "appuser" for security reasons
curl https://install.meteor.com/ | sh
# Add next line into `.bash_profile`
# edit with nano ~/.bash_profile
export PATH=$PATH:$HOME/.meteor

# Since we would like to be able to run
# multiple apps under different meteor/node
# releases we will install and use NVM
#
# Execute this command as "appuser" for security reasons
# Node Version Manager: https://github.com/nvm-sh/nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash
# Add next two lines into `.bash_profile`
# edit with nano ~/.bash_profile
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Reload `.bash_profile`
source ~/.bash_profile

# install required Node by Meteor as of May 2021
nvm install 12.22.1
nvm use 12.22.1

# Symlink .bashrc to .bash_profile
# so environment would be loaded
# in non-interactive shells
ln -s .bash_profile .bashrc

# Clone repository
git clone https://github.com/veliovgroup/meteor-files-website.git

# Copy-paste deploy script `deploy.sh` from this tutorial to /home/appuser/deploy.sh
# make it executable
chmod +x ~/deploy.sh

# Exit back to root
exit
##############################[end as appuser]#####################################

# Install Nginx + Phusion Passenger
apt-get install nginx
apt-get install -y dirmngr gnupg
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7
echo deb https://oss-binaries.phusionpassenger.com/apt/passenger buster main > /etc/apt/sources.list.d/passenger.list
apt-get update
apt-get install -y libnginx-mod-http-passenger

# Copy paste `nginx.conf` from this repo to `/etc/nginx/nginx.conf`
# Create empty file for secrets
touch /etc/nginx/secrets.files-veliov-com.conf
# To make sure configuration file has no errors run:
service nginx configtest

# ENABLE LOGROTATE BY EDITING `/etc/logrotate.d/nginx`
# FOLLOW LOGROTATE GUIDE: https://www.digitalocean.com/community/tutorials/how-to-configure-logging-and-log-rotation-in-nginx-on-an-ubuntu-vps

# create directory where uploaded files
# are stored and set correct permissions
mkdir -p /data/meteor-files
chown appuser:appuser /data/meteor-files

# add manifest+json mime-type [see README.md for more details](https://github.com/veliovgroup/meteor-snippets/tree/main/devops)
# adding two lines to `/etc/nginx/mime.types`

# Got to appuser's home directory
cd /home/appuser
# -------- First deploy --------
./deploy.sh -bmpr meteor-files-website

service nginx restart