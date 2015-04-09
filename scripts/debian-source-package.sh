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
    debianization_init  # Init vars after unpacking

    debug "      Package format:  ${DEBIAN_PACKAGE_FORMAT:=3.0 (quilt)}"
}

########################################
# Source package setup
source_package_setup() {
    msg "    Preparing source directory $BUILD_SRC_DIR"
    run_user rm -rf $BUILD_SRC_DIR
    run_user mkdir -p $BUILD_SRC_DIR/debian
}

########################################
# Source package configuration

configure_package_wrapper() {
    # Some packages may define a configuration step
    if declare -f configure_package >/dev/null; then
	msg "    Configuring source package"
	sbuild_configure_package
    else
	debug "      (No configure_package function defined)"
    fi
}

########################################
# Build source package from source tree

source_package_build_from_tree() {
    msg "    Building source package"
    debug "      Debianized source tree: $BUILD_SRC_DIR"
    (
	cd $BUILD_SRC_DIR
	run_user dpkg-source -b \
	    --format="'${DEBIAN_PACKAGE_FORMAT}'" .
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

    # Init variables
    source_package_init

    # Download source tarball and unpack
    source_tarball_init
    source_tarball_download
    source_tarball_unpack

    # Some packages may define a configuration step
    configure_package_wrapper

    # Add new changelog
    debianization_add_changelog

    # Build the source package and clean up
    source_package_build_from_tree
    source_package_cleanup
}

