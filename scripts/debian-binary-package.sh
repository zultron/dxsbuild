debug "    Sourcing debian-binary-package.sh"
#
# These routines handle building the package.

ccache_setup() {
    if ! test -d $CCACHE_DIR; then
	debug "    Creating ccache directory $CCACHE_DIR"
	run_user mkdir -p $CCACHE_DIR
    fi
}

binary_package_build() {
    msg "Building binary package '$PACKAGE'"
    source_package_init
    ccache_setup
    sbuild_build_package
}

