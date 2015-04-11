# Raspbian native + cross-build configuration
#
# Rasbian is based on Jessie, so set $CODENAME and add the amd64
# cross-build chroot as needed.
#
# http://www.raspbian.org/RaspbianRepository

# RT kernel packages
DISTRO_PACKAGES[raspbian-jessie]="xenomai linux linux-tools linux-latest"
# ZeroMQ packages
DISTRO_PACKAGES[raspbian-jessie]+=" czmq"
# Zultron Debian package repo
DISTRO_PACKAGES[raspbian-jessie]+=" dovetail-automata-keyring"
# FIXME testing
DISTRO_PACKAGES[raspbian-jessie]+=" pyzmq"

# Repos to configure for raspbian-jessie
DISTRO_REPOS[raspbian-jessie]="raspbian-jessie"

# Codename (when doesn't match distro name)
DISTRO_CODENAME[raspbian-jessie]="jessie"

# Mixing Raspbian-armhf and Debian-amd64 doesn't work because of
# package differences:
#
# linux-libc-dev : Breaks: linux-libc-dev:armhf (!= 3.16.7-ckt7-1) but 3.16.7-ckt4-1+rpi1 is to be installed.
# linux-libc-dev:armhf : Breaks: linux-libc-dev (!= 3.16.7-ckt4-1+rpi1) but 3.16.7-ckt7-1 is installed.
#
# So, only armhf
DISTRO_ARCHES[raspbian-jessie]="armhf"
