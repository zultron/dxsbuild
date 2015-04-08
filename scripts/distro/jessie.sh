# RT kernel packages
PACKAGES="xenomai rtai linux linux-tools linux-latest"
# ZeroMQ packages
PACKAGES+=" czmq"
# Zultron Debian package repo
PACKAGES+=" dovetail-automata-keyring"

# Jessie arches
ARCHES="amd64 i386 armhf"

# Jessie distro mirror and keys
DISTRO_MIRROR=http://http.debian.net/debian

distro_configure_repos() {
    # Cross-build tools
    repo_configure_emdebian

    # Dovetail Automata; enable to pull deps not built locally
    #repo_configure_dovetail_automata  # include for partial builds

    # RCN's ARM repo
    # repo_configure_rcn
}

