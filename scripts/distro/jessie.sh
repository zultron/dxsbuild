# RT kernel packages
DISTRO_PACKAGES[jessie]="xenomai rtai linux linux-tools linux-latest"
# ZeroMQ packages
DISTRO_PACKAGES[jessie]+=" czmq"
# Zultron Debian package repo
DISTRO_PACKAGES[jessie]+=" dovetail-automata-keyring"

# Repos to configure for jessie
DISTRO_REPOS[jessie]="debian emdebian"
