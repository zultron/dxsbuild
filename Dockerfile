#							-*-conf-*-
FROM ubuntu:trusty
MAINTAINER John Morris <john@zultron.com>

############################
# Apt:
# - update package index
RUN	apt-get update
# - don't install recommended packages
RUN	echo "APT::Install-Recommends \"0\";\nAPT::Install-Suggests \"0\";" \
	    > /etc/apt/apt.conf.d/10local

############################
# Install packages:
# - build tools
RUN	apt-get install -y build-essential fakeroot devscripts
# - cross-build tools
RUN	apt-get install -y xdeb sbuild pdebuild-cross
# - aufs tools for sbuild
RUN	apt-get install -y aufs-tools
# - git
RUN	apt-get install -y git ca-certificates openssh-client
# - reprepro
RUN	apt-get install -y reprepro
# - qemu and gdb
RUN	apt-get install -y qemu-user-static binfmt-support gdb-arm-none-eabi
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

