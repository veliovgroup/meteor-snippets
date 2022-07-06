# Meteor.js: DevOps

This is set of tutorials and snippets related to DevOps, deployment, and maintenance of node.js/meteor.js web applications

## ToC:

- [Files and links](https://github.com/veliovgroup/meteor-snippets/tree/main/devops#files-and-links)
- __[Tutorial goals](https://github.com/veliovgroup/meteor-snippets/tree/main/devops#tutorial-goals)__
- [Linux setup](https://github.com/veliovgroup/meteor-snippets/tree/main/devops#linux-setup)
  - [Setting up](https://github.com/veliovgroup/meteor-snippets/tree/main/devops#setting-up) — Step-by-step process, for detailed instructions read annotations in [`steps.sh`](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/steps.sh)
- [Security](https://github.com/veliovgroup/meteor-snippets/tree/main/devops#security)
  - [Application](https://github.com/veliovgroup/meteor-snippets/tree/main/devops#application)
  - [Managing your "secrets"](https://github.com/veliovgroup/meteor-snippets/tree/main/devops#managing-your-secrets)
  - [non-root user](https://github.com/veliovgroup/meteor-snippets/tree/main/devops#application-user)
  - [MongoDB](https://github.com/veliovgroup/meteor-snippets/tree/main/devops#mongodb)
- [Nginx setup](https://github.com/veliovgroup/meteor-snippets/tree/main/devops#nginx)
- [Deploy](https://github.com/veliovgroup/meteor-snippets/tree/main/devops#deploy)
  - [Deploy script features](https://github.com/veliovgroup/meteor-snippets/tree/main/devops#deploy-script-features)
  - [First deploy](https://github.com/veliovgroup/meteor-snippets/tree/main/devops#first-deploy)
  - [Node.js app](https://github.com/veliovgroup/meteor-snippets/tree/main/devops#deploy-nodejs-app)
  - [Meteor app](https://github.com/veliovgroup/meteor-snippets/tree/main/devops#deploy-meteor-app)
  - [Static assets app](https://github.com/veliovgroup/meteor-snippets/tree/main/devops#deploy-static-app)
  - [Deploy with changes in Nginx](https://github.com/veliovgroup/meteor-snippets/tree/main/devops#deploy-with-changes-in-nginxconf) configuration file
- [SEO](https://github.com/veliovgroup/meteor-snippets/tree/main/devops#seo)
  - [Meta tags and title](https://github.com/veliovgroup/meteor-snippets/tree/main/devops#meta-tags-and-title)
  - [Pre-rendering](https://github.com/veliovgroup/meteor-snippets/tree/main/devops#pre-rendering)
- [Debugging](https://github.com/veliovgroup/meteor-snippets/tree/main/devops#debugging)
- [Further steps](https://github.com/veliovgroup/meteor-snippets/tree/main/devops#further-steps) and recommendations

## Files and links:

- [`deploy.sh`](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/deploy.sh) — Semi-automated deploy bash script
- [`steps.sh`](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/steps.sh) — Fresh Linux/Debian/Ubuntu setup step-by-step
- [`mongod.conf`](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/mongod.conf) — Local MongoDB configuration file
- [`nginx.conf`](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/nginx.conf) — Server Nginx `http {}` configuration file
- [`server.conf`](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/server.conf) — Host Nginx `server {}` configuration file
- [`mime.types`](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/mime.types) — A map of file extensions and its mime-types for static files served over Nginx

## Tutorial goals

- Setup Linux environment
- Setup local MongoDB
- Setup Nginx flavored with Phusion Passenger
- Automate further deployments
- Follow security "best practices"

## Linux setup

Let's start with a good tip:

> Always keep a log of your actions while setting up Linux server in a text `.sh` file. I usually call such file [`steps.sh`](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/steps.sh).

For this project virtual Linux Debian 10 with 2vCPU, 4GB, and SSD storage are used.

### Setting up

Check out set of [Linux tutorials](https://github.com/veliovgroup/ostrio/tree/master/tutorials/linux) published by us in the past. TL;TR; Update Linux, implement basic "best practices", install and configure Node.js, MongoDB, Nginx, and Phusion Passenger. Here's steps I've performed after logging *first time* to the server, __detailed steps are logged in [`steps.sh`](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/steps.sh)__:

1. `apt-get update`
2. `apt-get remove sudo` — *let's discuss it in the issues*
3. First `apt-get dist-upgrade -s` to check if there's any updates available
4. Then `apt-get dist-upgrade -y` updating all packages and Linux itself
5. [Change timezone](https://github.com/VeliovGroup/ostrio/blob/master/tutorials/linux/change-timezone.md) to UTC
6. [Tune up `.bash_profile`](https://github.com/veliovgroup/ostrio/blob/master/tutorials/linux/bash_profile-tuning.md) for ease of Terminal use
7. Install `mongo` and started service with `systemctl start mongod`
8. Copy-paste `mongod.conf` MongoDB configuration file from this repo to `/etc/mongod.conf` __changing default [PORT]__ to a random port
9. Create `/data` and `/data/mongo` directories with access permission by `mongodb` user; To double-check *service* user's names in Linux use `cat /etc/passwd`
10. [Install Nginx flavored with Phusion Passenger](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/steps.sh#L92)
11. For security reasons create `appuser` user, see [`steps.sh`](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/steps.sh) for more details
12. Copy-paste `nginx.conf` from this repo to `/etc/nginx/nginx.conf`
13. Create empty configuration file with `touch etc/nginx/secrets.files-veliov-com.conf`
14. Install meteor as `appuser` with `curl https://install.meteor.com/ | sh`
15. Install NVM (Node Version Manager) as `appuser` to be able to run multiple meteor and node applications under different versions of node.js
16. Add load command for NVM script to `/home/appuser/.bash_profile` of `appuser` user
17. Create storage directory for uploaded files and set correct permissions `mkdir -p /data/meteor-files && chown appuser:appuser /data/meteor-files`
18. Initiate first deploy `cd /home/appuser && ./deploy.sh -bmr meteor-files-website`
19. Restart Nginx `service nginx restart`

## Security

Implement well-known "best practices" for Linux, Nginx, and MongoDB. Check out our [Linux security](https://github.com/veliovgroup/ostrio/tree/master/tutorials/linux/security) tutorials collection for advanced security options.

- [Application level security](https://github.com/veliovgroup/meteor-snippets/tree/main/devops#application)
- [Manage "secrets"](https://github.com/veliovgroup/meteor-snippets/tree/main/devops#managing-your-secrets)
- [Use non-root user](https://github.com/veliovgroup/meteor-snippets/tree/main/devops#application-user)
- [MongoDB Security](https://github.com/veliovgroup/meteor-snippets/tree/main/devops#application)

### Application

As an example of open and secure [files app](https://github.com/veliovgroup/meteor-files-website) during its development we followed:

- No data-collection
- No file reading nor processing
- All files has TTL since the moment it was uploaded and every file would be eventually removed
- Application "secrets" stored in static ["secrets" file](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/secrets.files-veliov-com.conf) not tracked with git

### Managing your "secrets"

Our "secrets" is something we would like to keep out of reach by *others*, and untracked by Git. This application (*and Meteor itself too*) designed with configuration options passed via [Linux Environment Variables](https://en.wikipedia.org/wiki/Environment_variable#Unix). Thanks to Phusion Passenger and Nginx we can pass all required variables via configuration file, and "secrets" can be dynamically loaded. In [`steps.sh`](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/steps.sh#L52) we create an empty configuration file:

```shell
touch /etc/nginx/secrets.files-veliov-com.conf
```

Edit this file with `nano`:

```shell
nano /etc/nginx/secrets.files-veliov-com.conf
```

And copy-paste settings from [sample "secrets" file](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/secrets.files-veliov-com.conf), __update values to match your setup and environment.__ [Host declaration in `server.conf` configured](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/server.conf#L34) to read environment variable ["secrets" file](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/secrets.files-veliov-com.conf). This file not tracked with git and should exist only on server with permissions to read only by `www-data` (*in our case — user used to run Nginx*).

### Application user

For security reasons many actions should be performed as non-root user. In our case we're using `appuser`:

```shell
useradd appuser
mkdir -p /home/appuser
usermod -m -d /home/appuser appuser
chown -R appuser:appuser /home/appuser
chmod 770 /home/appuser
chsh appuser -s /bin/bash
```

To login into new shell session as `appuser` user use `su`:

```shell
su - appuser
```

To execute a single command as `appuser` use `su -c`, for example to install NPM dependencies:

```shell
su -s /bin/bash -c 'npm ci --production' appuser
```

### MongoDB

By default in [suggested `mongod.conf`](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/mongod.conf) file MongoDB would listen only on local network. Second security advise is random port for MongoDB, find `[PORT]` in [`mongod.conf`](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/mongod.conf) and replace with a value between `1024` and `65535`. Make sure `MONGO_URL` environment variable in [`server.conf`](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/server.conf) or in ["secrets" file](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/secrets.files-veliov-com.conf) is set to the correct value.

## Nginx

Install Nginx flavored with Phusion Passenger following [official docs](https://www.phusionpassenger.com/library/walkthroughs/deploy/nodejs/ownserver/nginx/oss/install_language_runtime.html), as time of writing (Oct 2020) next steps were necessary to perform on Debian 10:

```shell
apt-get install nginx
apt-get install -y dirmngr gnupg
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7
apt-get install -y apt-transport-https ca-certificates
echo deb https://oss-binaries.phusionpassenger.com/apt/passenger buster main > /etc/apt/sources.list.d/passenger.list
apt-get update
apt-get install -y libnginx-mod-http-passenger
```
PLEASE NOTE THE ABOVE WILL WORK FOR DEBIAN 10 
So before check with `lsb_release -a` if the versio is different that 10, use corrent codename in package list 
`echo deb https://oss-binaries.phusionpassenger.com/apt/passenger Codename main > /etc/apt/sources.list.d/passenger.list`
For example for Debian 11 it's bullseye.
Sadly right now libnginx-mod-http-passenger does not support bullseye, so I've tried focal
There are different tickets like https://github.com/phusion/passenger/issues/2122 but I don't think they fixed it so far.

Copy paste [`nginx.conf`](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/nginx.conf) from this repo to `/etc/nginx/nginx.conf`. Phusion Passenger enable simple and easy configuration passing environment variables to the application from Nginx configuration file using `passenger_env_var`. Create an empty configuration file `secrets.files-veliov-com.conf` with `touch etc/nginx/secrets.files-veliov-com.conf`. This file will be used to store application "secrets", in our case:

```nginx
# /etc/nginx/secrets.files-veliov-com.conf

passenger_env_var DEBUG false;
passenger_env_var ROOT_URL https://example.com;
passenger_env_var DDP_DEFAULT_CONNECTION_URL https://example.com;
passenger_env_var MONGO_URL mongodb://127.0.0.1:27017/upload-and-share;
passenger_env_var METEOR_SETTINGS '{"storagePath":"/data/meteor-files/uploads","public":{"maxFileSizeMb":3000,"maxFilesQty":10,"fileTTLSec":129600,"vapid":{"publicKey":""}},"s3":{"key":"","secret":"","bucket":"","region":""},"vapid":{"email":"","privateKey":""}}';
```

To make sure configuration file has no errors run:

```shell
service nginx configtest
```

### Serve `.manifest` with correct mime-type

Add next lines to `/etc/nginx/mime.types` (*make sure no duplicates are added*):

```nginx
application/manifest+json             webmanifest;
application/x-web-app-manifest+json   webapp;
```

## Deploy

To deploy we use [`deploy.sh`](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/deploy.sh).

- [Deploy script features](https://github.com/veliovgroup/meteor-snippets/tree/main/devops#deploy-script-features)
- [First deployment steps](https://github.com/veliovgroup/meteor-snippets/tree/main/devops#first-deploy)
- [Deploy Node.js app](https://github.com/veliovgroup/meteor-snippets/tree/main/devops#deploy-nodejs-app)
- [Deploy Meteor app](https://github.com/veliovgroup/meteor-snippets/tree/main/devops#deploy-meteor-app)
- [Build and deploy meteor client bundle](https://github.com/veliovgroup/meteor-snippets/tree/main/devops#build-and-deploy-meteor-client)
- [Deploy static assets app](https://github.com/veliovgroup/meteor-snippets/tree/main/devops#deploy-static-app)
- [Deploy after changes in Nginx](https://github.com/veliovgroup/meteor-snippets/tree/main/devops#deploy-with-changes-in-nginxconf) __configuration__ file

By default [`deploy.sh`](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/deploy.sh) script able to deploy static, node.js, and meteor.js websites backed with Nginx. You can get up-to-date help from `./deploy.sh -h`, script manual:

```text
Usage:
./deploy.sh -[args] repo [username] [nginxuser]

-h          - Show this help and exit
-b          - Build, install dependencies & move files around
-r          - Restart server after deployment
-m          - Build meteor app, use with `-b` flag
-c          - Build meteor client app, using `meteor-build-client`, use with `-b` flag
-p          - Force Phusion Passenger deployment scenario
-s          - Force static website deployment scenario, use with `-b` flag
-n          - Reload Nginx __configuration__ without downtime
-d          - Debug this script arguments and exit
repo        - Name of web app repository and working directory
[username]  - Username of an "application user" owned app files and used to spawn a process, default: `appuser`
[nginxuser] - Username used to spawn a process and access files by Nginx, default: `www-data`
```

To start using script (*[run it as `apppuser` user](https://github.com/veliovgroup/meteor-snippets/tree/main/devops#application-user)*):

- Login as `appuser` with `su - appuser`
- Copy-paste [`deploy.sh`](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/deploy.sh) to non-root user "home" directory in our case it will be `/home/appuser/deploy.sh`
- Make script executable: `chmod +x /home/appuser/deploy.sh`

### Deploy script features

- Compatible with static websites (html or client-only JS websites, like ones build with [`meteor-build-client`](https://github.com/frozeman/meteor-build-client))
- Compatible with `http`, `https`, `express`, and similar implementations of node.js backend
- Compatible with (*raw and build*) meteor.js web applications
- Gap-less zero-downtime deployments

### First deploy

First deploy require some extra preparation:

0. As `root` go to `appuser` user "home" directory — `cd /home/appuser/`
1. `git clone [repo-url]` — Clone repository to a local directory ([`deploy.sh`](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/deploy.sh) should be located in the same directory, recommended to use SSH protocol for cloning)
2. Run deploy script with `-r` flag (restart flag) (*see examples below*)

```shell

./deploy.sh -bmr app-directory-name

# where:
#  -b - Move files into right directories
#  -m - Build meteor app
#  -r - Restart nginx at the end
```

### Deploy node.js app

Run this script against repository with `package.json` and `nginx.conf` in the root directory.

```shell
./deploy.sh -bpr app-directory-name

# where:
#  -b  - Move files into right directories
#  -pr - Run Phusion Passenger scenario and restart without downtime
```

### Deploy Meteor app

Run this script against repository with `.meteor` and `nginx.conf` in the root directory.

```shell
./deploy.sh -bmpr app-directory-name

# where:
#  -b  - Move files into right directories
#  -m  - Build meteor app
#  -pr - Run Phusion Passenger scenario and restart without downtime
```

### Build and deploy meteor client

Run this script against repository with `.meteor` and `nginx.conf` in the root directory to build client-only and static version of Meteor application with [`meteor-build-client`](https://github.com/frozeman/meteor-build-client):

```shell
ROOT_URL=\"https://example.com\" ./deploy.sh -bmc app-directory-name

# ROOT_URL env.var is required to properly serve client bundle
# where:
#  -b  - Move files into right directories
#  -mc - Build meteor application with meteor-build-client
```

### Deploy static app

Run this script against repository with `nginx.conf` in the root directory.

```shell
./deploy.sh -bs app-directory-name

# where:
#  -b - Move files into right directories
#  -s - Run static website scenario
```

### Deploy with changes in `nginx.conf`

If `nginx.conf` host definition was changed it would require `-n` to run gap-less zero-downtime deploy:

```shell
./deploy.sh -n app-directory-name
```

## SEO

To make this project "crawlable" by search engines, social networks, and web-crawlers on this project we are using:

- [`ostrio:flow-router-meta`](https://github.com/VeliovGroup/Meteor-flow-router-meta) package to generate meta-tags and title
- [Pre-rendering](https://ostr.io/info/prerendering) service to serve static HTML

### Meta tags and title

Using [`ostrio:flow-router-meta`](https://github.com/VeliovGroup/Meteor-flow-router-meta) package controlling meta-tags content as easy as extending *FlowRouter* definition with `{ meta, title, link }` properties:

```js
FlowRouter.route('/about', {
  name: 'about',
  title: 'About',
  meta: {
    keywords: {
      name: 'keywords',
      itemprop: 'keywords',
      content: 'about, file, files, share, sharing, upload, service, free, details'
    },
    description: {
      name: 'description',
      itemprop: 'description',
      property: 'og:description',
      content: 'About file-sharing web application'
    },
    'twitter:description': 'About file-sharing web application'
  },
  action() {
    this.render('layout', 'about');
  }
});
```

Set default meta tags and page title using `FlowRouter.globals.push({ meta })`:

```js
const title = 'Default page title up to 65 symbols';
const description = 'Default description up to 160 symbols';

FlowRouter.globals.push({ title });
FlowRouter.globals.push({
  meta: {
    robots: 'index, follow',
    keywords: {
      name: 'keywords',
      itemprop: 'keywords',
      content: 'keywords, separated, with, comma'
    },
    'og:title': {
      name: 'title',
      property: 'og:title',
      content() {
        return document.title;
      }
    },
    description: {
      name: 'description',
      itemprop: 'description',
      property: 'og:description',
      content: description
    }
  }
});
```

Activate `meta` and `title` packages:

```js
import { FlowRouter } from 'meteor/ostrio:flow-router-extra';
import { FlowRouterMeta, FlowRouterTitle } from 'meteor/ostrio:flow-router-meta';

/* ... DEFINE FLOWROUTER RULES HERE, BEFORE INIT ... */

new FlowRouterTitle(FlowRouter);
new FlowRouterMeta(FlowRouter);
```

### Pre-rendering

To pre-render JS-driven templates (Blaze, React, Vue, etc.) to HTML we are using [pre-rendering](https://ostr.io/info/prerendering) via [`spiderable-middleware` package](https://github.com/VeliovGroup/spiderable-middleware#meteor-specific-usage):

```js
/**
 * @locus Server
 */

import { Meteor } from 'meteor/meteor';
import { WebApp } from 'meteor/webapp';
import Spiderable from 'meteor/ostrio:spiderable-middleware';

WebApp.connectHandlers.use(new Spiderable({
  serviceURL: 'https://render.ostr.io',
  auth: 'pass:login', // <-- obtain from ostr.io
  only: [ // <-- Allow pre-rendering only for existing public routes: `index`, `about` `file`
    /^\/?$/,
    /^\/about\/?$/i,
    /^\/f\/[A-z0-9]{16}\/?$/i
  ]
}));
```

## Debugging

To debug meteor/node.js application use Nginx logs:

```shell
tail -n 100 -f /var/log/nginx/error.log
```

Using `tail`, where `-n 100` means show 100 lines from bottom of the file, and `-f` means "follow" live-file updates. press <kbd>control</kbd>+<kbd>c</kbd> to exit live-mode.

Same can be done for MongoDB logs:

```shell
tail -n 100 -f /var/log/mongodb/mongod.log
```

## Further steps

Recommended further steps

1. Read annotations in [`deploy.sh`](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/deploy.sh) and learn how it works from its [source code](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/deploy.sh)
2. Enhance security of the server with [changing default SSH port](https://github.com/veliovgroup/ostrio/blob/master/tutorials/linux/security/change-ssh-port.md) and restricting SSH authentication [only by using SSH-key](https://github.com/veliovgroup/ostrio/blob/master/tutorials/linux/security/use-ssh-keys.md)
3. Read other [Linux tutorials](https://github.com/veliovgroup/ostrio/tree/master/tutorials/linux)
4. Integrate ostr.io to enable [24/7 monitoring](https://snmp-monitoring.com/), get [the best SEO score](https://prerendering.com/), and [protect a domain name](https://domain-protection.info/)
