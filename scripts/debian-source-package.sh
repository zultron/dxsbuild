debug "    Sourcing debian-source-package.sh"
#
# Routines for building source packages
#

# Routines for downloading/unpacking the Debian original tarball
. $SCRIPTS_DIR/debian-orig-tarball.sh
# Routines for cloning/copying the Debianization files
. $SCRIPTS_DIR/debian-debzn.sh

########################################
# Source package init vars
source_package_init() {
    distro_check_package $DISTRO $PACKAGE

    debug "    Saving original changelog"
    run_user cp $BUILD_SRC_DIR/debian/changelog $BUILD_DIR/changelog.orig

    debianization_init
    source_tarball_init

    debug "      Package format:  ${PACKAGE_FORMAT[$PACKAGE]}"
}

########################################
# Source package setup
source_package_setup() {
    msg "    Preparing source directory $BUILD_SRC_DIR"
    run_user rm -rf $BUILD_SRC_DIR
    run_user mkdir -p $BUILD_SRC_DIR/debian

    # Proxy
    if test -n "$HTTP_PROXY"; then
	debug "    Setting proxy:  $HTTP_PROXY"
	export http_proxy="$HTTP_PROXY"
	export https_proxy="$HTTP_PROXY"
    fi

}

########################################
# Source package configuration

configure_package() {
    if test -z "${PACKAGE_CONFIGURE_FUNC[$PACKAGE]}"; then
	debug "      (No source pkg configure function defined)"
	return
    fi

    sbuild_configure_package
}

run_configure_package_func() {
    debug "    Running configure function: ${PACKAGE_CONFIGURE_FUNC[$PACKAGE]}"
    (
	cd $BUILD_SRC_DIR
	run ${PACKAGE_CONFIGURE_FUNC[$PACKAGE]}
    )
}

########################################
# Build source package from source tree

source_package_build_from_tree() {
    msg "    Building source package"
    debug "      Debianized source tree: $BUILD_SRC_DIR"
    (
	cd $BUILD_SRC_DIR
	run_user dpkg-source -b \
	    --format="'${PACKAGE_FORMAT[$PACKAGE]}'" .
    )
}

########################################
# Source package clean up
source_package_cleanup() {
    msg "    Cleaning up source tree $BUILD_SRC_DIR"
    run_user rm -rf $BUILD_SRC_DIR
}

########################################
# Source package build
source_package_build() {
    msg "Building source package '$PACKAGE'"
    # Initialize directories
    source_package_setup

    # Update debianization git tree and copy to source tree
    debianization_git_tree_update
    debianization_git_tree_unpack

    # Download source tarball and unpack
    source_tarball_download
    source_tarball_unpack

    # Init variables
    source_package_init

    # Add new changelog
    debianization_add_changelog

    # Some packages may define a configuration step
    configure_package

    # Build the source package and clean up
    source_package_build_from_tree
    source_package_cleanup
}

