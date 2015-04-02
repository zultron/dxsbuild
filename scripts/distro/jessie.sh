debug "    Sourcing jessie.sh"

# RT kernel packages
PACKAGES="xenomai rtai linux linux-tools linux-latest"
# ZeroMQ packages
PACKAGES+=" czmq"
# Misc
PACKAGES+=" libwebsockets jansson python-pyftpdlib"
# Zultron Debian package repo
PACKAGES+=" dovetail-automata-keyring"

# Jessie arches
ARCHES="amd64 i386 armhf"

# Jessie distro mirror and keys
DISTRO_MIRROR=http://http.debian.net/debian

distro_configure_repos() {
    # Debian distro
    repo_add_apt_source debian $DISTRO_MIRROR
    repo_add_apt_key 7DE089671804772E

    # Dovetail Automata; enable to pull deps not built locally
    #repo_configure_dovetail_automata  # include for partial builds

    # Cross-build tools
    repo_configure_emdebian

    # RCN's ARM repo
    # repo_configure_rcn
}

