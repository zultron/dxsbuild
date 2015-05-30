#
# These routines handle building the package.

binary_package_glob() {
    for i in $(build_dir)/*_*$(package_version_suffix)_$HOST_ARCH.deb; do
	echo -n "$(readlink -e $i) "
    done
    echo
}

binary_package_changes_glob() {
    echo $(readlink -e $(build_dir
	    )/${PACKAGE_NAME[$PACKAGE]}_*$(package_version_suffix
	    )_$(arch_build $DISTRO $HOST_ARCH).changes)
}

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

    run_user rm -f \
	$(binary_package_changes_glob) \
	$(binary_package_glob)

    source_tarball_init

    case "${PACKAGE_COMP[$PACKAGE]}" in
	gz) DPKG_BUILD_ARGS=-Zgzip ;;
	xz) DPKG_BUILD_ARGS=-Zxz ;;
	bz2) DPKG_BUILD_ARGS=-Zbzip2 ;;
	*) error "Package $PACKAGE:  Unknown package compression format" ;;
    esac
}

ccache_setup() {
    if ! test -d $(ccache_dir); then
	debug "    Creating ccache directory $(ccache_dir)"
	run_user mkdir -p $(ccache_dir)
    fi
    debug "    Zeroing ccache stats"
    run_user env CCACHE_DIR=$(ccache_dir) ccache -z
}

ccache_stats() {
    msg "    ccache stats:"
    run_user env CCACHE_DIR=$(ccache_dir) \
	ccache -s
}

binary_package_build() {
    announce "$DISTRO:$HOST_ARCH:$PACKAGE  Building binary packages"
    binary_package_init
    ccache_setup
    sbuild_build_package
    ccache_stats
}

