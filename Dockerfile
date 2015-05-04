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
# - Debian signing keys
#     Fixes "W: Cannot check Release signature; keyring file not available
#                /usr/share/keyrings/debian-archive-keyring.gpg"
RUN	apt-get install -y debian-archive-keyring
# - Raspbian signing keys
#   - Put in sbuild default keyring
RUN	wget -O - -q http://archive.raspbian.org/raspbian.public.key | \
	    apt-key --keyring /usr/share/keyrings/debian-archive-keyring.gpg \
	        add -

############################
# Monkey patches
#
# Fix `sbuild-createchroot --foreign` flag
RUN	sed -i /usr/sbin/sbuild-createchroot -e '/set_conf..FOREIGN/ s/0/1/'

############################
# Debug output
ENV	DEBUG true

# List apt keys
RUN	! $DEBUG || { echo "System apt keys:"; apt-key list; }
RUN	! $DEBUG || { echo "Debootstrap apt keys:"; \
	    apt-key --keyring /usr/share/keyrings/debian-archive-keyring.gpg \
	        list; }

############################
# Start in the dbuild directory
WORKDIR	/srv

