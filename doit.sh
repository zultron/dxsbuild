#!/bin/bash -xe

ARCHES="amd64 i386 armhf"
DISTROS="jessie trusty"
PACKAGES="dovetail-automata-keyring python-pyftpdlib rtai xenomai linux-latest \
    linux-tools linux czmq pyzmq"

for arch in $ARCHES; do
    for distro in $DISTROS; do
	./dbuild -rda $arch $distro

	for package in $PACKAGES; do
	    if test $arch = amd64; then
		# build source package once
		./dbuild -Sda $arch $distro $package
	    fi

	    if test $arch = armhf -a $package = rtai; then
		# don't build rtai for armhf
		continue
	    fi

	    ./dbuild -bda $arch -j 8 $distro $package

	    ./dbuild -Rd $distro $package

	    ./dbuild -L $distro
	done
    done
done

