#!/bin/bash

# THIS IS ALL STEPS (e.g. COMMANDS) I'VE PERFORMED ON A FRESH
# VIRTUAL SERVER (Linux; Debian 10; 2vCPU; 4GB; SSD)
# DETAILED TUTORIAL: https://github.com/veliovgroup/meteor-snippets/tree/main/devops

apt-get update
apt-get remove sudo
apt-get dist-upgrade -s
apt-get dist-upgrade -y
apt-get install git build-essential
dpkg-reconfigure tzdata

# tune up .bash_profile

# Install local MongoDB
wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | apt-key add -
echo "deb http://repo.mongodb.org/apt/debian buster/mongodb-org/4.4 main" | tee /etc/apt/sources.list.d/mongodb-org-4.4.list

systemctl start mongod

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

# copy paste `mongod.conf` from this repo to `/etc/mongod.conf`

mkdir -p /data/mongo
chmod 777 /data
chown mongodb:mongodb /data/mongo

# Install Nginx + Phusion Passenger
apt-get install nginx
apt-get install -y dirmngr gnupg
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7
apt-get install -y apt-transport-https ca-certificates
echo deb https://oss-binaries.phusionpassenger.com/apt/passenger buster main > /etc/apt/sources.list.d/passenger.list
apt-get update
apt-get install -y libnginx-mod-http-passenger

# Copy paste `nginx.conf` from this repo to `/etc/nginx/nginx.conf`
# Create empty file for secrets
touch /etc/nginx/secrets.files-veliov-com.conf
# To make sure configuration file has no errors run:
service nginx configtest

##########################[start as appuser]#####################################
# Execute next few commands as "appuser" for security reasons
# Login to appuser's shell:
su -s /bin/bash -l appuser

# Install meteor.js
# Execute this command as "appuser" for security reasons
curl https://install.meteor.com/ | sh
# Add next two lines into `.bash_profile`
# edit with nano ~/.bash_profile
export PATH=$PATH:$HOME/.meteor

# Since we would like to be able to run
# multiple apps under different meteor/node
# releases we will install and use NVM
#
# Execute this command as "appuser" for security reasons
# Node Version Manager: https://github.com/nvm-sh/nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.36.0/install.sh | bash
# Add next two lines into `.bash_profile`
# edit with nano ~/.bash_profile
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Reload `.bash_profile`
source ~/.bash_profile

# install required Node by Meteor as of Oct 2020
nvm install 12.18.4
nvm use 12.18.4

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

# create directory where uploaded files
# are stored and set correct permissions
mkdir -p /data/meteor-files
chown appuser:appuser /data/meteor-files

# add manifest+json mime-type [see README.md for more details](https://github.com/veliovgroup/meteor-snippets/tree/main/devops)
# adding two lines to `/etc/nginx/mime.types`

# Got to appuser's home directory
cd /home/appuser
# -------- First deploy --------
./deploy meteor-files-website --no-restart --meteor

service nginx restart