FROM phusion/baseimage:0.9.19

MAINTAINER nest.yt
# Based on work by
# Ryan Seto <ryanseto@yak.net>

RUN apt-get update && \
	locale-gen en_US.UTF-8 && \
	rm -rf /etc/service/sshd /etc/my_init.d/00_regen_ssh_host_keys.sh && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y pwgen inotify-tools php mariadb-server mariadb-client && \
	apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
	sed -i -e 's/^datadir\s*=.*/datadir = \/data/' /etc/mysql/my.cnf && \
	sed -i -e 's/^bind-address/#bind-address/' /etc/mysql/my.cnf && \
	sed -i -e 's/^innodb_buffer_pool_size\s*=.*/innodb_buffer_pool_size = 128M/' /etc/mysql/my.cnf && \
	chmod +x /scripts/start.sh && \
	chmod +x /etc/service/adminer/run && \
	touch /firstrun

EXPOSE 3306 8200

# Expose our data, log, and configuration directories.
VOLUME ["/data", "/var/log/mysql", "/etc/mysql"]

# Use baseimage-docker's init system.
CMD ["/sbin/my_init", "--", "/scripts/start.sh"]
