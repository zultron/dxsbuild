DISTRO="trusty"

# List of packages to build for this distribution
#
# RT kernel packages
DISTRO_PACKAGES[trusty]="xenomai rtai linux linux-tools linux-latest"
# ZeroMQ packages
DISTRO_PACKAGES[trusty]+=" czmq"
# Zultron Debian package repo
DISTRO_PACKAGES[trusty]+=" dovetail-automata-keyring"

# Apt package repositories to configure for this distribution
DISTRO_REPOS[trusty]="trusty trusty-ports"
