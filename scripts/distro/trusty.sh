# RT kernel packages
DISTRO_PACKAGES[trusty]="xenomai rtai linux linux-tools linux-latest"
# ZeroMQ packages
DISTRO_PACKAGES[trusty]+=" czmq"
# Zultron Debian package repo
DISTRO_PACKAGES[trusty]+=" dovetail-automata-keyring"

# Repos to configure for trusty
DISTRO_REPOS[trusty]="trusty trusty-ports"
