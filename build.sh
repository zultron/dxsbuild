#!/bin/bash -ex

DOCKER_IMAGE=docker-sbuild
SBUILD_BASE_DIR=/srv
SBUILD_CHROOT_DIR=$SBUILD_BASE_DIR/chroots
SBUILD_PKG_DIR=$SBUILD_BASE_DIR/packages
SBUILD_SOURCE_DIR=$SBUILD_PKG_DIR/source
DOCKER_BIND_MOUNTS="-v `pwd`:$SBUILD_BASE_DIR"

test -n "$IN_DOCKER" || IN_DOCKER=false

docker_build() {
    mkdir -p docker
    (
	cd docker
	cat ../Dockerfile | docker build -t $DOCKER_IMAGE -
    )
    rmdir docker
}

docker_run() {
    docker run --privileged -i -t -e IN_DOCKER=true $DOCKER_BIND_MOUNTS \
	$DOCKER_IMAGE "$@"
}

sbuild_shell() {
    CODENAME=$1
    sbuild-shell $1
}

chroot_setup() {
    CODENAME=$1
    test -n "$CODENAME" || { echo "Supply codename, e.g. 'jessie'" >&2; exit 1; }

    case $CODENAME in
	trusty)
	    MIRROR=http://archive.ubuntu.com/ubuntu
	    PORTMIRROR=http://ports.ubuntu.com/ubuntu-ports
	    COMPONENTS="main universe"
	    ;;
	jessie) 
	    MIRROR=http://http.debian.net/debian
	    PORTMIRROR=http://http.debian.net/debian
	    COMPONENTS=main
	    EXTRA_SOURCES="deb http://emdebian.org/tools/debian/ $CODENAME main"
	    INSTALL_KEYS=7DE089671804772E  # Emdebian key
	    ;;
	*)
	    echo "Unknown codename '$1'" >&2; exit 1 ;;
    esac

    DIR=$SBUILD_CHROOT_DIR/$CODENAME-cross

    for KEY in $INSTALL_KEYS; do
	apt-key --keyring $DIR/etc/apt/trusted.gpg.d/sbuild-extra.gpg \
	    adv --keyserver hkp://keys.gnupg.net --recv-key $KEY
    done

    sbuild-createchroot --components=${COMPONENTS/ /,} \
	$CODENAME $DIR $MIRROR

    > $DIR/etc/apt/sources.list
    echo "deb [arch=amd64,i386] $MIRROR $CODENAME $COMPONENTS" \
	>> $DIR/etc/apt/sources.list
    echo "deb [arch=armhf] $PORTMIRROR $CODENAME $COMPONENTS" \
	>> $DIR/etc/apt/sources.list
    echo "deb-src  $MIRROR $CODENAME $COMPONENTS" \
	>> $DIR/etc/apt/sources.list
    if test -n "$EXTRA_SOURCES"; then
	echo "$EXTRA_SOURCES" >> $DIR/etc/apt/sources.list
    fi
}

build_package() {
    CODENAME=$1
    ARCH=$2
    PACKAGE=$3
    PKG_DIR=$SBUILD_PKG_DIR/$CODENAME

    mkdir -p $PKG_DIR

    (
	cd $PKG_DIR
	sbuild --host=$ARCH -d $CODENAME -c $CODENAME-amd64-sbuild \
	    $SBUILD_SOURCE_DIR/$PACKAGE
    )
}


if $IN_DOCKER; then
    "$@"
else
    if test -z "$1"; then
	docker_run
    elif test $1 = docker_build; then
	docker_build
    else
	docker_run ./build.sh "$@"
    fi
fi
