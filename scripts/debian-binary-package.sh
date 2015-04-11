debug "    Sourcing debian-binary-package.sh"
#
# These routines handle building the package.

ccache_setup() {
    if ! test -d $CCACHE_DIR; then
	debug "    Creating ccache directory $CCACHE_DIR"
	run_user mkdir -p $CCACHE_DIR
    fi
}

binary_package_check_arch() {
    local ARCH=$(arch_host $DISTRO $HOST_ARCH)

    # Check package's list of excluded arches
    for a in $EXCLUDE_ARCHES; do
	if test $a = $ARCH; then
	    error "Package $PACKAGE excluded from arch $ARCH"
	fi
    done
}

binary_package_build() {
    msg "Building binary package '$PACKAGE'"
    source_package_init
    binary_package_check_arch
    ccache_setup
    sbuild_build_package
}

