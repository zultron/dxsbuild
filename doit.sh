#!/bin/bash -xe

ARCHES="amd64 i386 armhf"
DISTROS="jessie trusty"
PACKAGES="dovetail-automata-keyring rtai xenomai linux linux-latest \
    linux-tools czmq"

for distro in $DISTROS; do
    for arch in $ARCHES; do
	echo "########### dbuild schroot, $distro:  $arch ###########"
	./dbuild -rda $arch $distro
    done

    for package in $PACKAGES; do
	echo "########### dbuild source, $distro: $package ###########"
	./dbuild -Sd $distro $package

	for arch in $ARCHES; do
	    if test $arch = armhf -a $package = rtai; then
		# don't build rtai for armhf
		continue
	    fi

	    echo "########### dbuild binary, $distro: $package:$arch ###########"
	    ./dbuild -bda $arch -j 8 $distro $package

	done

	echo "########### dbuild repo, $distro: $package ###########"
	./dbuild -Rd $distro $package
	./dbuild -L $distro

    done
done

