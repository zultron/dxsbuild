# Raspbian native + cross-build configuration
#
# Rasbian is based on Jessie, so set $CODENAME and add the amd64
# cross-build chroot as needed.
#
# http://www.raspbian.org/RaspbianRepository

# Override codename when $DISTRO != $CODENAME
CODENAME=jessie

# RT kernel packages
PACKAGES="xenomai linux linux-tools linux-latest"
# ZeroMQ packages
PACKAGES+=" czmq"
# Zultron Debian package repo
PACKAGES+=" dovetail-automata-keyring"
# FIXME testing
PACKAGES+=" pyzmq"

# Raspbian arches
ARCHES="armhf"

# Mixing Raspbian-armhf and Debian-amd64 doesn't work because of
# package differences:
#
# linux-libc-dev : Breaks: linux-libc-dev:armhf (!= 3.16.7-ckt7-1) but 3.16.7-ckt4-1+rpi1 is to be installed.
# linux-libc-dev:armhf : Breaks: linux-libc-dev (!= 3.16.7-ckt4-1+rpi1) but 3.16.7-ckt7-1 is installed.
#
NATIVE_BUILD_ONLY=true

# Raspbian Jessie distro mirror
DISTRO_MIRROR_armhf=http://archive.raspbian.org/raspbian
# Debian jessie amd64 mirror for cross-compiling
DISTRO_MIRROR=http://http.debian.net/debian

distro_configure_repos() {
    # Dovetail Automata; enable to pull deps not built locally
    #repo_configure_dovetail_automata  # include for partial builds

    if ! dpkg-architecture -earmhf; then

	# Add Raspbian apt repo to cross-build schroots
	repo_add_apt_source jessie $DISTRO_MIRROR_armhf armhf
	repo_add_apt_key http://archive.raspbian.org/raspbian.public.key

	# Cross-build tools
	repo_configure_emdebian

    fi
}

