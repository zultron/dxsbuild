FROM ubuntu:trusty
MAINTAINER John Morris <john@zultron.com>

# Update chroot package index
RUN	apt-get update

# Don't install recommended packages
RUN	echo "APT::Install-Recommends \"0\";\nAPT::Install-Suggests \"0\";" \
	    > /etc/apt/apt.conf.d/10local

# Install utils and build tools
RUN	apt-get install -y --no-install-recommends \
	    build-essential fakeroot devscripts

# Install cross-build tools
RUN	apt-get install -y --no-install-recommends xdeb sbuild pdebuild-cross

# Init key
RUN	sbuild-update --keygen

# Install git
RUN	apt-get install -y --no-install-recommends \
	    git ca-certificates openssh-client

# Install reprepro
RUN	apt-get install -y --no-install-recommends \
	    reprepro

# Sbuild chroot configs
RUN	rmdir /etc/schroot/chroot.d && \
	    ln -s /srv/configs/chroot.d /etc/schroot/chroot.d

# Make local apt package repository available to chroots
RUN	echo "/srv		/srv		none	rw,bind		0	0" \
	    >> /etc/schroot/default/fstab

# Install Debian signing keys
# Fixes "W: Cannot check Release signature; keyring file not available
#     /usr/share/keyrings/debian-archive-keyring.gpg"
RUN	apt-get install -y --no-install-recommends \
	    debian-archive-keyring

# The chroots directory will be mounted here
WORKDIR	/srv

