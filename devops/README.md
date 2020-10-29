# Meteor.js: DevOps

## Linux setup

I'd like to start with a good tip: Always keep a log of your actions setting up Linux servers in text `.sh` file. I usually call this file `steps.sh`.

For this project I'm using virtual Linux Debian 10 with 2vCPU, 4GB, and SSD storage.

We have set of [Linux tutorials](https://github.com/veliovgroup/ostrio/tree/master/tutorials/linux) published in the past, I did next steps after logging first time to server:

1. `apt-get update`
2. `apt-get remove sudo` — *let's discuss it in the issues*
3. First `apt-get dist-upgrade -s` to check if there's any updates available
4. Then `apt-get dist-upgrade -y` updating all packages and Linux itself
5. [Changed timezone](https://github.com/VeliovGroup/ostrio/blob/master/tutorials/linux/change-timezone.md) to UTC
6. [Tuned up my `.bash_profile`](https://github.com/veliovgroup/ostrio/blob/master/tutorials/linux/bash_profile-tuning.md) for ease of Terminal use
7. Installed `mongo` and started service with `systemctl start mongod`
8. Copy-pasted `mongod.conf` MongoDB configuration file from this repo to `/etc/mongod.conf` changing default [PORT] to a random value
9. Create `/data` and `/data/mongo` directories with access permission by `mongodb` user; To double-check *service* user's names in Lunix use `cat /etc/passwd`
10. Install Nginx following instruction from Phusion Passenger website
11. Copy-pasted `nginx.conf` from this repo to `/etc/nginx/nginx.conf`
12. Install meteor with `curl https://install.meteor.com/ | sh`
13. Install NVM (Node Version Manager) to be able to run different meteor and node applications under different versions of node.js
14. Add load command for NVM script to `.bash_profile`
15. Create storage directory for uploaded files and set correct permissions `mkdir -p /data/meteor-files && chown www-data:www-data /data/meteor-files`

## Further steps

Recommended further steps

1. Enhance security of the server with [changing default SSH port](https://github.com/veliovgroup/ostrio/blob/master/tutorials/linux/security/change-ssh-port.md) and restricting SSH authentication [only by using SSH-key](https://github.com/veliovgroup/ostrio/blob/master/tutorials/linux/security/use-ssh-keys.md)
2. Integrate ostr.io to enable [24/7 monitoring](https://snmp-monitoring.com/), get [the best SEO score](https://prerendering.com/), and [protect a domain name](https://domain-protection.info/)
