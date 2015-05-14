arch_check() {
    local a
    for a in $*; do
	case " $ARCHES " in
	    *" $a "*) continue ;;
	    *) return 1 ;;
	esac
    done
    return 0
}

arch_default() {
    # The default architecture is the first in the $DISTRO_ARCHES list
    local DISTRO=$1
    echo ${DISTRO_ARCHES[$DISTRO]} | awk '{print $1}'
}

arch_host() {
    # The host arch is given with the '-a' option
    local DISTRO=$1
    local ARCH=$2

    if test -z "$ARCH"; then
	ARCH=$(arch_default $DISTRO)
    fi
    echo $ARCH
}

arch_is_emulated() {
    local MACHINE_ARCH=$(arch_machine)
    local HOST_ARCH=$1

    if test $MACHINE_ARCH = $HOST_ARCH; then
	return 1
    elif test $MACHINE_ARCH = amd64 -a $HOST_ARCH = i386; then
	return 1
    else
	return 0
    fi
}

arch_build() {
    # For non-binary pkg builds, simply return the host arch.
    #
    # The build arch for a package is the host arch if the package
    # cannot be cross-built. Otherwise, if the host arch is a
    # 'personality' of the machine arch (e.g. amd64->i386), use the
    # host arch. Otherwise, use the machine arch.
    local DISTRO=$1
    local ARCH=$2
    local HOST_ARCH=$(arch_host $DISTRO $ARCH)
    local BUILD_ARCH=

    if ! modes BUILD_PACKAGE; then
	# When not building a package (e.g. building a schroot),
	# always use requested host arch as build arch.
	echo $HOST_ARCH
	return

    elif ${PACKAGE_NATIVE_BUILD_ONLY[$PACKAGE]} || \
	${DISTRO_NATIVE_BUILD_ONLY[$DISTRO]}
    then
	# When the package or distro is marked as unable to
	# cross-build, always use requested host arch as build arch
	# (with emulation where needed).
	echo $HOST_ARCH
	return

    elif ! distro_base_repo $DISTRO $(arch_machine) >/dev/null; then
	# When the distro doesn't support the machine arch, use the
	# requested host arch as build arch (with emulation where
	# needed).
	echo $HOST_ARCH
	return

    elif ! arch_is_emulated $HOST_ARCH; then
	# If arch doesn't need emulation, then set BUILD_ARCH to
	# HOST_ARCH.  In a case like amd64 and i386, the schroot arch
	# and BUILD_ARCH will both be i386, where no emulation is
	# needed.
	BUILD_ARCH=$HOST_ARCH

    else
	# Otherwise, cross-compile:  set BUILD_ARCH to the machine
	# arch.
	BUILD_ARCH=$(arch_machine)
    fi
    
    # Finally, if the chosen arch isn't supported by the distro, take
    # our changes with the first arch in the supported list.
    if ! distro_has_arch $DISTRO $BUILD_ARCH; then
	debug "      (Distro $DISTRO doesn't support arch $BUILD_ARCH)"
	BUILD_ARCH=$(echo ${DISTRO_ARCHES[$DISTRO]} | awk '{print $1}')
	debug "      (...falling back to $BUILD_ARCH)"
    fi

    echo $BUILD_ARCH
}

arch_machine() {
    # The machine arch is the Docker host's arch
    dpkg-architecture -qDEB_BUILD_ARCH
}
