arch_default() {
    # The default architecture is the first in the $DISTRO_ARCHES list
    local DISTRO=$1
    echo ${DISTRO_ARCHES[$DISTRO]} | awk '{print $1}'
}

arch_host() {
    # The host arch is given with the '-a' option
    local DISTRO=$1
    local ARCH=$2

    if test $ARCH = 'default'; then
	ARCH=$(arch_default)
    fi
    echo $ARCH
}

arch_build() {
    # The build arch for a package is the host arch if the package
    # cannot be cross-built. Otherwise, if the host arch is a
    # 'personality' of the machine arch (e.g. amd64->i386), use the
    # host arch. Otherwise, use the machine arch.
    local DISTRO=$1
    local ARCH=$2
    local HOST_ARCH=$(arch_host $DISTRO $ARCH)

    if $NATIVE_BUILD_ONLY || \
	! distro_base_repo $DISTRO $HOST_ARCH >/dev/null; then
	echo $HOST_ARCH
	return
    fi

    # By default, the build arch is the machine arch...
    local BUILD_ARCH=$(arch_machine)

    # ...But check for 'personality' compatibility
    if test $BUILD_ARCH = amd64 -a $HOST_ARCH = i386; then
	BUILD_ARCH=i386
    fi
    
    echo $BUILD_ARCH
}

arch_machine() {
    # The machine arch is the Docker host's arch
    dpkg-architecture -qDEB_BUILD_ARCH
}

arch_is_foreign() {
    local DISTRO=$1
    local ARCH=$2
    local RES
    test $(arch_host $DISTRO $ARCH) = $(arch_build $DISTRO $ARCH) && \
	RES=0 || RES=1
    return $RES
}
