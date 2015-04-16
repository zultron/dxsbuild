# Raspbian native + cross-build configuration
#
# Rasbian is based on Jessie, so set $CODENAME and add the amd64
# cross-build chroot as needed.
#
# http://www.raspbian.org/RaspbianRepository

DISTRO="rpi8"

# List of packages to build for this distribution
#
# RT kernel packages
DISTRO_PACKAGES[$DISTRO]="xenomai"
# ZeroMQ packages
DISTRO_PACKAGES[$DISTRO]+=" czmq"
# Zultron Debian package repo
DISTRO_PACKAGES[$DISTRO]+=" dovetail-automata-keyring"
# Machinekit
DISTRO_PACKAGES[$DISTRO]+=" machinekit"

# Apt package repositories to configure for this distribution
DISTRO_REPOS[$DISTRO]="raspbian"

# Codename
DISTRO_CODENAME[$DISTRO]="jessie"

# Distro architectures
#
# Mixing Raspbian-armhf and Debian-amd64 doesn't work because of
# package differences:
#
# linux-libc-dev : Breaks: linux-libc-dev:armhf (!= 3.16.7-ckt7-1)
#     but 3.16.7-ckt4-1+rpi1 is to be installed.
# linux-libc-dev:armhf : Breaks: linux-libc-dev (!= 3.16.7-ckt4-1+rpi1)
#     but 3.16.7-ckt7-1 is installed.
#
# So, only armhf, and no cross-compiling
DISTRO_ARCHES[$DISTRO]="armhf"

# Create separate apt repository directory
#
# Avoid conflict with Debian jessie/armhf
DISTRO_SEPARATE_REPO_DIR[$DISTRO]="true"
