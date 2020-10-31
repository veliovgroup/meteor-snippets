# Meteor.js: DevOps

This is tutorial and snippets related to DevOps, deployment, and maintenance of node.js/meteor.js web applications

## Files and links:

- [`deploy.sh`](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/deploy.sh) — Semi-automated deploy bash script
- [`steps.sh`](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/steps.sh) — Fresh Linux/Debian/Ubuntu setup step-by-step
- [`mongod.conf`](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/mongod.conf) — Local MongoDB configuration file
- [`nginx.conf`](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/nginx.conf) — Server Nginx `http {}` configuration file
- [`sever.conf`](https://github.com/veliovgroup/meteor-snippets/blob/main/devops/sever.conf) — Host Nginx `server {}` configuration file

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
11. Copy-pasted `nginx.conf` from this repo to `/etc/nginx/nginx.conf`
12. Install meteor with `curl https://install.meteor.com/ | sh`
13. Install NVM (Node Version Manager) to be able to run multiple meteor and node applications under different versions of node.js
14. Add load command for NVM script to `.bash_profile`
15. Create storage directory for uploaded files and set correct permissions `mkdir -p /data/meteor-files && chown www-data:www-data /data/meteor-files`

## Nginx

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
service nginx reload
```

## Further steps

Recommended further steps

1. Enhance security of the server with [changing default SSH port](https://github.com/veliovgroup/ostrio/blob/master/tutorials/linux/security/change-ssh-port.md) and restricting SSH authentication [only by using SSH-key](https://github.com/veliovgroup/ostrio/blob/master/tutorials/linux/security/use-ssh-keys.md)
2. Integrate ostr.io to enable [24/7 monitoring](https://snmp-monitoring.com/), get [the best SEO score](https://prerendering.com/), and [protect a domain name](https://domain-protection.info/)
