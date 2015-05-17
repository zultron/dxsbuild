#
# Routines for building source packages
#

# Routines for downloading/unpacking the Debian original tarball
. $SCRIPTS_DIR/debian-orig-tarball.sh
# Routines for cloning/copying the Debianization files
. $SCRIPTS_DIR/debian-debzn.sh

source_package_dsc_glob() {
    echo $(readlink -e $(build_dir)/${PACKAGE}_*$(package_version_suffix).dsc)
}
source_package_dir() { echo $(build_dir)/tree-$DISTRO; }

########################################
# Source package setup
source_package_setup() {
    distro_check_package $DISTRO $PACKAGE

    msg "    Preparing source directory $(source_package_dir)"
    run_user rm -rf $(source_package_dir)
    run_user mkdir -p $(source_package_dir)/debian

    msg "    Removing old files"
    run_user rm -f \
	$(debzn_tarball_glob) \
	$(source_package_dsc_glob)

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
    if $IN_SCHROOT || test -n "${PACKAGE_CONFIGURE_FUNC[$PACKAGE]}"; then
	run_configure_package_func	
    elif test -n "${PACKAGE_CONFIGURE_CHROOT_FUNC[$PACKAGE]}"; then
	run_configure_package_chroot_func
    else
	debug "      (No source pkg configure function defined)"
    fi

}

run_configure_package_func() {
    if test -n "${PACKAGE_CONFIGURE_FUNC[$PACKAGE]}"; then
	local FUNC="${PACKAGE_CONFIGURE_FUNC[$PACKAGE]}"
    else
	local FUNC="${PACKAGE_CONFIGURE_CHROOT_FUNC[$PACKAGE]}"
    fi
    debug "    Running configure function: ${FUNC}"
    (
	cd $(source_package_dir)
	$FUNC
    )
}

########################################
# Build source package from source tree

source_package_build_from_tree() {
    msg "    Building source package"
    debug "      Debianized source tree: $(source_package_dir)"
    (
	cd $(source_package_dir)
	run_user dpkg-source -b \
	    --format="'${PACKAGE_FORMAT[$PACKAGE]}'" .
    )
}

########################################
# Source package clean up
source_package_cleanup() {
    if $SOURCE_CLEAN; then
	msg "    Cleaning up source tree $(source_package_dir)"
	run_user rm -rf $(source_package_dir)
    else
	debug "      (Not cleaning source tree in $(source_package_dir))"
    fi
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

