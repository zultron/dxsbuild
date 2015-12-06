DISTRO="trusty"

# List of packages to build for this distribution
#
# RT kernel packages
DISTRO_PACKAGES[$DISTRO]="xenomai linux linux-tools linux-latest"
# ZeroMQ packages
DISTRO_PACKAGES[$DISTRO]+=" zeromq3 czmq pyzmq"
# Misc
DISTRO_PACKAGES[$DISTRO]+=" libwebsockets"
# Zultron Debian package repo
DISTRO_PACKAGES[$DISTRO]+=" dovetail-automata-keyring"
# Machinekit
DISTRO_PACKAGES[$DISTRO]+=" machinekit"

# Apt package repositories to configure for this distribution
DISTRO_REPOS[$DISTRO]="trusty trusty-ports"
