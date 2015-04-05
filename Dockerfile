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
# - git
RUN	apt-get install -y git ca-certificates openssh-client
# - reprepro
RUN	apt-get install -y reprepro
# - Debian signing keys
#     Fixes "W: Cannot check Release signature; keyring file not available
#                /usr/share/keyrings/debian-archive-keyring.gpg"
RUN	apt-get install -y debian-archive-keyring

############################
# Sbuild configuration:
# - chroot configs
RUN	rmdir /etc/schroot/chroot.d && \
	    ln -s /srv/configs/chroot.d /etc/schroot/chroot.d
# - bind mounts
RUN	echo "/srv\t\t/srv\t\tnone\trw,bind\t\t0\t0" \
	    >> /etc/schroot/default/fstab
# - signing key
RUN	sbuild-update --keygen

# - aufs on tmpfs config
ADD	schroot-04tmpfs /etc/schroot/setup.d/04tmpfs

############################
# Start in the dbuild directory
WORKDIR	/srv

