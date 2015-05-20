#							-*-conf-*-
FROM debian:jessie
MAINTAINER John Morris <john@zultron.com>

############################
# Apt:
# - set jessie mirror
RUN	sed -i /etc/apt/sources.list \
	    -e 's,http://httpredir[^ ]*,http://http.debian.net/debian,'
# - don't install recommended packages
RUN	echo "APT::Install-Recommends \"0\";\nAPT::Install-Suggests \"0\";" \
	    > /etc/apt/apt.conf.d/10local
# - silence apt warnings about ttys, etc.
ENV	DEBIAN_FRONTEND noninteractive
# - update package index
RUN	apt-get update
# - install utilities
RUN	apt-get install -y wget
# - configure emdebian repo
RUN	echo 'deb http://emdebian.org/tools/debian jessie main' > \
	    /etc/apt/sources.list.d/emdebian.list
RUN	wget -O - -q \
	    http://emdebian.org/tools/debian/emdebian-toolchain-archive.key \
	    | apt-key --keyring /etc/apt/trusted.gpg.d/sbuild-extra.gpg add -
# - add foreign architectures
RUN	dpkg --add-architecture armhf
RUN	sed -i /etc/apt/sources.list \
	    -e 's/^deb /deb [arch=amd64,i386,armhf] /'
# - update package index again for emdebian and cross-build packages
RUN	apt-get update

############################
# Install packages:
# - build tools
RUN	apt-get install -y build-essential fakeroot devscripts \
	    sbuild debootstrap
# - cross-build tools
RUN	apt-get install -y crossbuild-essential-armhf
# - aufs tools for sbuild
RUN	apt-get install -y aufs-tools
# - git
RUN	apt-get install -y git ca-certificates openssh-client
# - reprepro
RUN	apt-get install -y reprepro
# - qemu and gdb
RUN	apt-get install -y qemu-user-static binfmt-support gdb-arm-none-eabi
# - distcc and ccache
RUN	apt-get install -y distcc ccache
RUN	sed -i  /etc/default/distcc \
	    -e '/^STARTDISTCC/ s/false/true/' \
	    -e '$ a #' \
	    -e '$ a DAEMON_ARGS="--pid-file=/var/run/$NAME.pid \\\
	          --log-file=/srv/repo/log/$NAME.log --daemon"'
# - Buildbot
run	apt-get install -y python-pip python-dev supervisor sudo ssh

# - Debian signing keys
#     Fixes "W: Cannot check Release signature; keyring file not available
#                /usr/share/keyrings/debian-archive-keyring.gpg"
RUN	apt-get install -y debian-archive-keyring
# - RCN signing keys
RUN	wget -O - -q \
	    http://repos.rcn-ee.net/debian/conf/repos.rcn-ee.net.gpg.key | \
	    apt-key --keyring /usr/share/keyrings/debian-archive-keyring.gpg \
	        add -
# - Raspbian signing keys
#   - Put in sbuild default keyring
RUN	wget -O - -q http://archive.raspbian.org/raspbian.public.key | \
	    apt-key --keyring /usr/share/keyrings/debian-archive-keyring.gpg \
	        add -
# - update package index YET again for updated keys
RUN	apt-get update

############################
# Monkey patches
#
# Fix `sbuild-createchroot --foreign` flag
RUN	sed -i /usr/sbin/sbuild-createchroot -e '/set_conf..FOREIGN/ s/0/1/'

############################
# Non-root user
# - create user 'user' with sbuild and passwordless sudo privs
RUN	useradd -m -d /home/user user
RUN	adduser user sbuild
RUN	adduser user sudo
RUN	sed -i /etc/sudoers -e '/^%sudo/ s/ ALL$/ NOPASSWD:ALL/'

############################
# Proxy setup
# (templated in `docker.sh`)
#ENV	http_proxy http://myproxy:3128
#ENV	https_proxy http://myproxy:3128

############################
# Debug output
ENV	DOCKER_DEBUG true

# List apt keys
RUN	! $DOCKER_DEBUG || { echo "Debootstrap apt keys:"; \
	    apt-key --keyring /usr/share/keyrings/debian-archive-keyring.gpg \
	        list; }

############################
# Buildbot install
#
# Cribbed from
# https://github.com/buildbot/buildbot/blob/master/master/contrib/Dockerfile
#
# - install Buildbot software
RUN	pip install buildbot buildbot_slave

# - set supervisord buildbot
RUN	echo "\
            \n[program:buildmaster]\
            \ncommand=twistd --nodaemon --no_save -y buildbot.tac\n\
            \ndirectory=/srv/buildbot/master\n\
            \nuser=user\n\
            \n[program:buildworker]\n\
            \ncommand=twistd --nodaemon --no_save -y buildbot.tac\n\
            \ndirectory=/srv/buildbot/slave\n\
            \nuser=user\n" \
                > /etc/supervisor/conf.d/buildbot.conf

# Make host port 8010 match container port 8010
EXPOSE :8010

############################
# Tell scripts we're inside Docker
ENV	IN_DOCKER true
# Fix path to include this directory
ENV	PATH /srv/bin:/usr/lib/ccache:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bin

# Start in the dbuild directory
WORKDIR	/srv

# Run supervisord
CMD ["/usr/bin/supervisord", "-n"]
