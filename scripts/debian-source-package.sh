debug "    Sourcing debian-source-package.sh"
#
# Routines for building source packages
#

# Routines for downloading/unpacking the Debian original tarball
. $SCRIPTS_DIR/debian-orig-tarball.sh
# Routines for cloning/copying the Debianization files
. $SCRIPTS_DIR/debian-debzn.sh

########################################
# Source package setup
source_package_setup() {
    distro_check_package $DISTRO $PACKAGE

    msg "    Preparing source directory $BUILD_SRC_DIR"
    run_user rm -rf $BUILD_SRC_DIR
    run_user mkdir -p $BUILD_SRC_DIR/debian

    msg "    Removing old files"
    run_user rm -f \
	$BUILD_DIR/${PACKAGE}_*.debian.tar.* \
	$BUILD_DIR/${PACKAGE}_*.dsc \
	$BUILD_DIR/${PACKAGE}_*.changes \
	$BUILD_DIR/*.deb

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

    # Download source tarball and unpack
    source_tarball_download
    source_tarball_unpack

    # Update debianization git tree and copy to source tree
    debianization_git_tree_update
    debianization_git_tree_unpack

    # Add new changelog and finalize tarball
    debianization_add_changelog
    source_tarball_finalize

    # Some packages may define a configuration step
    configure_package

    # Build the source package and clean up
    source_package_build_from_tree
    source_package_cleanup
}

