debug "    Sourcing debian-binary-package.sh"
#
# These routines handle building the package.

binary_package_check_arch() {
    local ARCH=$(arch_host $DISTRO $HOST_ARCH)

    # Check package's list of excluded arches
    for a in ${PACKAGE_EXCLUDE_ARCHES[$PACKAGE]}; do
	if test $a = $ARCH; then
	    error "Package $PACKAGE excluded from arch $ARCH"
	fi
    done
}

binary_package_init() {
    distro_check_package $DISTRO $PACKAGE
    binary_package_check_arch

    source_tarball_init

    case "${PACKAGE_COMP[$PACKAGE]}" in
	gz) DPKG_BUILD_ARGS=-Zgzip ;;
	xz) DPKG_BUILD_ARGS=-Zxz ;;
	bz2) DPKG_BUILD_ARGS=-Zbzip2 ;;
	*) error "Package $PACKAGE:  Unknown package compression format" ;;
    esac
}

ccache_setup() {
    if ! test -d $CCACHE_DIR; then
	debug "    Creating ccache directory $CCACHE_DIR"
	run_user mkdir -p $CCACHE_DIR
    fi
}

binary_package_build() {
    msg "Building binary package '$PACKAGE'"
    binary_package_init
    ccache_setup
    sbuild_build_package
}

