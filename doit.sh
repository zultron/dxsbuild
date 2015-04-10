#!/bin/bash -xe

ARCHES="amd64 i386 armhf"
DISTROS="jessie trusty"
PACKAGES="dovetail-automata-keyring rtai xenomai linux linux-latest \
    linux-tools czmq pyzmq"

for arch in $ARCHES; do
    echo '############### arch $arch ###############'
    for distro in $DISTROS; do
	echo '############### distro $distro ###############'
	./dbuild -rda $arch $distro

	for package in $PACKAGES; do
	    echo '############### package $package ###############'
	    if test $arch = amd64; then
		echo '----------- build source package -----------'
		./dbuild -Sda $arch $distro $package
	    fi

	    if test $arch = armhf -a $package = rtai; then
		# don't build rtai for armhf
		continue
	    fi

	    echo '----------- build binary package -----------'
	    ./dbuild -bda $arch -j 8 $distro $package

	    echo '----------- add package to repo -----------'
	    ./dbuild -Rd $distro $package

	    echo '----------- repo list -----------'
	    ./dbuild -L $distro
	done
    done
done

