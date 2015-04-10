# RT kernel packages
PACKAGES="xenomai rtai linux linux-tools linux-latest"
# ZeroMQ packages
PACKAGES+=" czmq"
# Misc
PACKAGES+=" libwebsockets jansson python-pyftpdlib"
# Zultron Debian package repo
PACKAGES+=" dovetail-automata-keyring"

# Docker 'official' Wheezy base image
DOCKER_BASE=debian:wheezy

# Wheezy arches
ARCHES="amd64 i386 armhf"

CROSS_BUILD_PACKAGES="
	gcc-arm-linux-gnueabihf
	cpp-arm-linux-gnueabihf
	g++-arm-linux-gnueabihf
	binutils-arm-linux-gnueabihf
"
#	    pkg-config-arm-linux-gnueabihf # Not in emdebian?

repo_configure_dovetail_automata() {
    # Dovetail Automata LLC Machinekit repository; currently Wheezy,
    # Jessie, Trusty
    echo "deb http://deb.dovetail-automata.com $DISTRO main" > \
	/etc/apt/sources.list.d/machinekit.list

    apt-key adv --keyserver hkp://keys.gnupg.net --recv-key 7F32AE6B73571BB9
}

repo_configure_emdebian() {
    # Emdebian.org cross-build toolchain
    echo "deb [arch=amd64] http://emdebian.org/tools/debian/ $CODENAME main" > \
	/etc/apt/sources.list.d/emdebian.list

    wget -O - -q \
	http://emdebian.org/tools/debian/emdebian-toolchain-archive.key \
	| apt-key add -
}

repo_configure_rcn() {
    # Robert C Nelson's Beaglebone Black distro; currently Wheezy,
    # Jessie, Trusty

    echo "deb [arch=armhf] http://repos.rcn-ee.net/debian $CODENAME main" \
	> /etc/apt/sources.list.d/rcn.list

    wget -O - -q \
	http://repos.rcn-ee.net/debian/conf/repos.rcn-ee.net.gpg.key \
	| apt-key add -
}

distro_configure_repos() {
    #repo_configure_dovetail_automata
    repo_configure_emdebian
    repo_configure_rcn
}

