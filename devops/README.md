# Meteor.js: DevOps

This is set of tutorials and snippets related to DevOps, deployment, and maintenance of node.js/meteor.js web applications

## ToC:

- [Files and links](https://github.com/veliovgroup/meteor-snippets/tree/main/devops#files-and-links)
- [Linux setup](https://github.com/veliovgroup/meteor-snippets/tree/main/devops#linux-setup)
  - [Setting up](https://github.com/veliovgroup/meteor-snippets/tree/main/devops#setting-up) — Step-by-step process, for detailed instructions read annotations in [`steps.sh`](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/steps.sh)
  - [Security](https://github.com/veliovgroup/meteor-snippets/tree/main/devops#security)
    - [Application](https://github.com/veliovgroup/meteor-snippets/tree/main/devops#application)
    - [non-root user](https://github.com/veliovgroup/meteor-snippets/tree/main/devops#application-user)
    - [MongoDB](https://github.com/veliovgroup/meteor-snippets/tree/main/devops#application)
- [Nginx setup](https://github.com/veliovgroup/meteor-snippets/tree/main/devops#nginx)
- [Deploy](https://github.com/veliovgroup/meteor-snippets/tree/main/devops#deploy)

## Files and links:

- [`deploy.sh`](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/deploy.sh) — Semi-automated deploy bash script
- [`steps.sh`](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/steps.sh) — Fresh Linux/Debian/Ubuntu setup step-by-step
- [`mongod.conf`](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/mongod.conf) — Local MongoDB configuration file
- [`nginx.conf`](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/nginx.conf) — Server Nginx `http {}` configuration file
- [`server.conf`](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/server.conf) — Host Nginx `server {}` configuration file
- [`mime.types`](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/mime.types) — A map of file extensions and its mime-types for static files served over Nginx

## Linux setup

Let's start with a good tip:

> Always keep a log of your actions while setting up Linux server in a text `.sh` file. I usually call this file [`steps.sh`](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/steps.sh).

For this project virtual Linux Debian 10 with 2vCPU, 4GB, and SSD storage are used.

### Setting up

Check out set of [Linux tutorials](https://github.com/veliovgroup/ostrio/tree/master/tutorials/linux) published by us in the past. TL;TR; Update Linux, implement basic "best practices", install and configure Node.js, MongoDB, Nginx, and Phusion Passenger. Here's steps I've performed after logging *first time* to the server, __detailed steps are logged in [`steps.sh`](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/steps.sh)__:

1. `apt-get update`
2. `apt-get remove sudo` — *let's discuss it in the issues*
3. First `apt-get dist-upgrade -s` to check if there's any updates available
4. Then `apt-get dist-upgrade -y` updating all packages and Linux itself
5. [Changed timezone](https://github.com/VeliovGroup/ostrio/blob/master/tutorials/linux/change-timezone.md) to UTC
6. [Tuned up my `.bash_profile`](https://github.com/veliovgroup/ostrio/blob/master/tutorials/linux/bash_profile-tuning.md) for ease of Terminal use
7. Installed `mongo` and started service with `systemctl start mongod`
8. Copy-pasted `mongod.conf` MongoDB configuration file from this repo to `/etc/mongod.conf` __changing default [PORT]__ to a random port
9. Create `/data` and `/data/mongo` directories with access permission by `mongodb` user; To double-check *service* user's names in Lunix use `cat /etc/passwd`
10. Install Nginx following instruction from Phusion Passenger website
11. For security reasons create `appuser` user, see [`steps.sh`](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/steps.sh) for more details
12. Copy-pasted `nginx.conf` from this repo to `/etc/nginx/nginx.conf`
13. Create empty configuration file with `touch etc/nginx/secrets.files-veliov-com.conf`
14. Install meteor as `appuser` with `curl https://install.meteor.com/ | sh`
15. Install NVM (Node Version Manager) as `app user` to be able to run multiple meteor and node applications under different versions of node.js
16. Add load command for NVM script to `/home/appuser/.bash_profile` of `appuser` user
17. Create storage directory for uploaded files and set correct permissions `mkdir -p /data/meteor-files && chown appuser:appuser /data/meteor-files`
18. Initiate first deploy `cd /home/appuser && ./deploy meteor-files-website --no-restart --meteor`
19. Restart Nginx `service nginx restart`

### Security

#### Application

- No data-collection
- No file reading nor processing
- All files has TTL since the moment it was uploaded and every file would be eventually removed
- Application "secrets" stored in static `/etc/nginx/secrets.files-veliov-com.conf` file not tracked with git

#### Application user

For security reasons many actions should be performed as non-root user. In our case we're using `appuser`:

```shell
useradd appuser
mkdir -p /home/appuser
usermod -m -d /home/appuser appuser
chown -R appuser:appuser /home/appuser
chmod 770 /home/appuser
```

To login into new shell session as `appuser` user use `su`:

```shell
su - appuser
```

To execute a single command as `appuser` use `su -c`, for example to install NPM dependencies:

```shell
su -s /bin/bash -c 'npm ci --production' appuser
```

#### MongoDB

By default in [suggested `mongod.conf`](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/mongod.conf) file MongoDB would listen only on local network. Second security advise is random port for MongoDB, find `[PORT]` in [`mongod.conf`](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/mongod.conf) and replace with a value between `1024` and `65535`. Make sure `MONGO_URL` environment variable in [`server.conf`](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/server.conf) is set to the correct value.

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

To deploy we use [`deploy.sh`](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/deploy.sh), script manual:

```text
Usage:
./deploy.sh repo [--help|--load-only|--meteor]

By default this script will restart Passenger, unless --load-only is passed
Otherwise it will restart Phusion Passenger after sources update

repo         - Name of web app repository and working directory
--help | -h  - This help docs
--load-only  - Load only source code without Passenger restart
--meteor     - Build meteor app locally
```

### First deploy

First deploy require some extra preparation:

1. `git clone [repo-url]` — Clone repository to a local directory ([`deploy.sh`](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/deploy.sh) should be located in the same directory)
2. Run deploy script with `--no-restart` flag (*see examples below*)
3. Restart nginx: `service nginx restart`

That's it! Now let's deploy using [`deploy.sh`](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/deploy.sh) script. By default this script would work with static, node.js, and meteor.js websites backed with Nginx. You can get up-to-date help from `./deploy -h`

### Deploy node.js app

```shell
./deploy.sh app-directory-name
```

### Deploy Meteor app

```shell
./deploy.sh app-directory-name --meteor
```

### Deploy static app

```shell
./deploy.sh app-directory-name --no-restart
```

### First deploy steps

```shell
./deploy.sh app-directory-name --no-restart
# Double-check config for errors:
service nginx configtest
# restart nginx
service nginx restart
```

### Deploy with changes in `nginx.conf`

```shell
./deploy.sh app-directory-name --no-restart
# Double-check config for errors:
service nginx configtest
# restart nginx
service nginx restart
```

## Further steps

Recommended further steps

1. Enhance security of the server with [changing default SSH port](https://github.com/veliovgroup/ostrio/blob/master/tutorials/linux/security/change-ssh-port.md) and restricting SSH authentication [only by using SSH-key](https://github.com/veliovgroup/ostrio/blob/master/tutorials/linux/security/use-ssh-keys.md)
2. Integrate ostr.io to enable [24/7 monitoring](https://snmp-monitoring.com/), get [the best SEO score](https://prerendering.com/), and [protect a domain name](https://domain-protection.info/)
