DISTRO="jessie"

# List of packages to build for this distribution
#
# RT kernel packages
DISTRO_PACKAGES[$DISTRO]="xenomai rtai linux linux-tools linux-latest"
# ZeroMQ packages
DISTRO_PACKAGES[$DISTRO]+=" czmq"
# Zultron Debian package repo
DISTRO_PACKAGES[$DISTRO]+=" dovetail-automata-keyring"
# Machinekit
DISTRO_PACKAGES[$DISTRO]+=" machinekit"

# Apt package repositories to configure for this distribution
DISTRO_REPOS[$DISTRO]="debian emdebian"
