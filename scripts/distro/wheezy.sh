DISTRO="wheezy"

# List of packages to build for this distribution
#
# RT kernel packages
DISTRO_PACKAGES[wheezy]="xenomai rtai linux linux-tools linux-latest"
# ZeroMQ packages
DISTRO_PACKAGES[wheezy]+=" czmq"
# Misc
DISTRO_PACKAGES[wheezy]+=" libwebsockets jansson python-pyftpdlib"
# Zultron Debian package repo
DISTRO_PACKAGES[wheezy]+=" dovetail-automata-keyring"

# Apt package repositories to configure for this distribution
DISTRO_REPOS[wheezy]="debian rcn"
