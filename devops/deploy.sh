#!/bin/bash

# Hello there!
# This is deploy script we use to pull
# webapp repo from github

name=$1
flag=$2
flag2=$3
restart=true
isMeteor=false
appusername="appuser"

if ! [ "$name" ]; then
  echo "Command is missing, use"
  echo "$ ./deploy.sh --help"
  echo "to get help"
  exit 1
fi

# HELP DOCS
if [ "$flag" = '--help' ] || [ "$flag" = '-h' ] || [ "$name" = '--help' ] || [ "$name" = '-h' ]; then
  echo "Pull source and nginx config from GitHub"
  echo "then build Meteor app, move files in the right place, and restart "
  echo ""
  echo "Usage: "
  echo "./deploy.sh repo [--help|--load-only|--meteor]"
  echo ""
  echo "By default this script will restart Passenger, unless --load-only is passed"
  echo "Otherwise it will restart Phusion Passenger after sources update"
  echo ""
  echo "repo         - Name of web app repository and working directory"
  echo "--help | -h  - This help docs"
  echo "--load-only  - Load only source code without Passenger restart"
  echo "--meteor     - Build meteor app locally"
  echo ""
  echo "ONLY WHEN nginx.conf WAS UPDATED PERFORM NEXT STEPS:"
  echo "$ service nginx configtest"
  echo "\`configtest\` SHOULD RETURN [OK]"
  echo "$ service nginx reload"
  echo "\`reload\` WOULD SILENTLY UPDATE CONFIGURATION IN THE BACKGROUND WITHOUT DROPPING ACTIVE CLIENTS"
  exit 1
fi

# CHECK FOR --load-only FLAG
if [ "$flag" = '--load-only' ] || [ "$flag2" = '--load-only' ]; then
  restart=false
  echo "Sync with git, build app, and move files without Nginx or Passenger restart, use"
  echo "$ ./deploy.sh --help"
  echo "to get help"
fi

# CHECK FOR --meteor FLAG
if [ "$flag" = '--meteor' ] || [ "$flag2" = '--meteor' ]; then
  isMeteor=true
fi

# CHECK IF WORKING DIRECTORY EXISTS
if [ ! -d "./$name" ]; then
  echo "No project with name \"$name\" found"
  echo "Start with cloning your new project from GitHub"
  echo "git clone [path-to-repository], use"
  echo "$ ./deploy.sh --help"
  echo "to get help"
  exit 1
fi

# GO TO WORKING DIRECTORY
echo "[ 1.0. ] Going to ./$name"
cd "./$name"
echo "[ 1.1. ] Sync with Git"
git pull

# CHECK FOR .meteor DIRECTORY
if [ -d "./.meteor" ]; then
  isMeteor=true
  echo "[ *.*. ] Meteor app detected by \`./.meteor\` directory!"
fi

# MOVE/UPDATE nginx.conf OF THE WEB APP
if [ -f "./nginx.conf" ]; then
  echo "[ *.*. ] nginx.conf found! Copy to the nginx directory"
  cp ./nginx.conf "/etc/nginx/sites-available/$name.conf"
  ln -s "/etc/nginx/sites-available/$name.conf" "/etc/nginx/sites-enabled/$name.conf"

  # TEST NEW NGINX CONFIGURATION FILE
  # TERMINATE THE SCRIPT IF CONFIG HAS ERRORS
  service nginx configtest || { echo "nginx.conf has errors. Deploy process terminated." ; exit 1; }
  echo "[ *.*. ] nginx.conf successfully updated and tested, no errors found!"
fi

echo "[ 2.0. ] Ensure /var/www/$name"
mkdir -p "/var/www/$name"

# BUILD METEOR APP
if "$isMeteor"; then
  echo "[ 2.1. ] Meteor app detected! Building meteor app to ../$name-build"
  # Install NPM dependencies
  echo "[ 2.2. ] Installing NPM dependencies in working meteor app directory"
  su -s /bin/bash -c "cd /home/$appusername/$name && meteor npm ci" - "$appusername"

  echo "[ 2.3. ] Building meteor app to ../$name-build"
  su -s /bin/bash -c "cd /home/$appusername/$name && METEOR_DISABLE_OPTIMISTIC_CACHING=1 meteor build ../$name-build --directory" - "$appusername"

  echo "[ 2.4. ] Meteor app successfully build! Going to ../$name-build/bundle"
  cd "../$name-build/bundle"

  echo "[ 2.5. ] Move static Meteor files to /public directory"
  mkdir -p ./public
  cp ./programs/web.browser/*.css ./public/
  cp ./programs/web.browser/*.js ./public/
  cp ./programs/web.browser.legacy/*.css ./public/
  cp ./programs/web.browser.legacy/*.js ./public/
  rsync -qauh ./programs/web.browser/app/ ./public
  rsync -qauh ./programs/web.browser.legacy/app/ ./public
  rsync -qauh ./programs/web.browser/packages/ ./public
  rsync -qauh ./programs/web.browser.legacy/packages/ ./public

  echo "[ 2.6. ] Ensure /var/www/$name/programs/web.browser/"
  mkdir -p "/var/www/$name/programs/web.browser/"
fi

# SET PERMISSIONS
echo "[ 3.0. ] Ensure permissions and ownership"
chmod -R 744 ./
chmod 755 ./
chown -R "$appusername":"$appusername" ./

echo "[ 3.1. ] Copy files to /var/www/$name"
rsync -qauh ./ "/var/www/$name" --exclude=".git"

if "$isMeteor"; then
  echo "[ *.*. ] Going to /var/www/$name/programs/server"
  cd "/var/www/$name/programs/server"
  echo "[ *.*. ] Installing Meteor's NPM dependencies"
  su -s /bin/bash -c "cd /var/www/$name/programs/server && npm install --production" - "$appusername"
fi

# CHECK FOR package.json
# AND INSTALL DEPENDENCIES
echo "[ 4.0. ] Going to /var/www/$name"
cd "/var/www/$name"
if [ -f "./package.json" ]; then
  echo "[ 4.1. ] \`packages.json\` detected! Installing NPM dependencies"
  su -s /bin/bash -c "cd /var/www/$name && npm ci --production" "$appusername"
fi

# GO TO "HOME" DIRECTORY
echo "[ 5.0. ] Going to application user \"home\" (/home/$appusername)"
cd "/home/$appusername"

# SET PERMISSIONS
echo "[ 5.1. ] Ensure permissions and ownership after installing dependencies"
chown -R "$appusername":"$appusername" "/var/www/$name"
chmod -R 744 "/var/www/$name"
chmod 755 "/var/www/$name"

# CHECK IF public DIRECTORY EXISTS
# SET 755 PERMISSIONS
if [ -d "/var/www/$name/public" ]; then
  echo "[ 5.2. ] Set 755 permissions for static assets in /var/www/$name/public/"
  chmod -R 755 "/var/www/$name/public"
fi

# RESTART PASSENGER APP ONLY
if "$restart"; then
  echo "[ 6.0. ] RESTARTING PASSENGER"
  passenger-config restart-app "/var/www/$name"
  passenger-status -v
  echo "[ 6.1. ] DISPLAY PASSENGER LOGS"
  tail -n 100 /var/log/nginx/error.log
fi

echo "===============[$name: deployed]==============="
