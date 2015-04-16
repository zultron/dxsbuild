#!/bin/bash -e

ARCHES="amd64 i386 armhf"
DISTROS="jessie wheezy trusty rpi8"
PACKAGES="dovetail-automata-keyring rtai xenomai linux linux-latest \
    linux-tools libsodium zeromq3 czmq pyzmq libwebsockets jansson \
    python-pyftpdlib machinekit"
BUILD_CHROOTS="true"

##################
#
# Override above configuration here
#ARCHES=""
#DISTROS=""
#PACKAGES=""
#BUILD_CHROOTS="false"
#CHROOTS_CONFIG_ONLY="-P"   # Don't install packages; just configure chroot
#
#
##################

for distro in $DISTROS; do
    if $BUILD_CHROOTS; then
	for arch in $ARCHES; do
	    if test $distro = rpi8 -a $arch != armhf; then
		# Only have armhf for rpi
		continue
	    fi

	    echo "########### dxsbuild schroot, $distro:  $arch ###########"
	    ./dxsbuild -rda $arch $CHROOTS_CONFIG_ONLY $distro
	done
    fi

    for package in $PACKAGES; do
	if test $distro != wheezy; then
	    # except for wheezy, skip some packages
	    case $package in
		libsodium|zeromq3|pyzmq) continue ;;
		jansson|libwebsockets) continue ;;
		python-pyftpdlib) continue ;;
	    esac
	fi

	if test $distro = rpi8; then
	    # no kernel packages on raspbian yet
	    case $package in
		rtai|linux|linux-latest|linux-tools) continue ;;
	    esac
	fi

	echo "########### dxsbuild source, $distro: $package ###########"
	./dxsbuild -Sd $distro $package

	for arch in $ARCHES; do
	    if test $distro = rpi8 -a $arch != armhf; then
		# only build raspbian for armhf
		continue
	    fi

	    if test $arch != amd64 -a $distro != rpi8; then
		# skip arch-indep packages on non-amd64, except rpi
		case $package in
		    dovetail-automata-keyring) continue ;;
		    linux-latest) continue ;;
		    python-pyftpdlib) continue ;;
		esac
	    fi

	    if test $arch = armhf -a $package = rtai; then
		# don't build rtai for armhf
		continue
	    fi

	    if test $distro != wheezy; then
		# skip wheezy-only deps
		case $package in
		    libsodium|zeromq3|pyzmq) continue ;;
		    libwebsockets|jansson) continue ;;
		    python-pyftpdlib) continue ;;
		esac
	    fi

	    echo "########### dxsbuild binary, $distro: $package:$arch ###########"
	    ./dxsbuild -bda $arch -j 8 $distro $package

	done

	echo "########### dxsbuild repo, $distro: $package ###########"
	./dxsbuild -Rd $distro $package
	./dxsbuild -L $distro

    done
done

