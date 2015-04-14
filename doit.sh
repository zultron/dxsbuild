#!/bin/bash -e

ARCHES="amd64 i386 armhf"
DISTROS="jessie trusty wheezy"
PACKAGES="dovetail-automata-keyring rtai xenomai linux linux-latest \
    linux-tools czmq"

for distro in $DISTROS; do
    for arch in $ARCHES; do
	echo "########### dxsbuild schroot, $distro:  $arch ###########"
	./dxsbuild -rda $arch $distro
    done

    for package in $PACKAGES; do
	echo "########### dxsbuild source, $distro: $package ###########"
	./dxsbuild -Sd $distro $package

	for arch in $ARCHES; do
	    if test $arch = armhf -a $package = rtai; then
		# don't build rtai for armhf
		continue
	    fi

	    echo "########### dxsbuild binary, $distro: $package:$arch ###########"
	    ./dxsbuild -bda $arch -j 8 $distro $package

	done

	echo "########### dxsbuild repo, $distro: $package ###########"
	./dxsbuild -Rd $distro $package
	./dxsbuild -L $distro

    done
done

