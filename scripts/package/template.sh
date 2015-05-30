# Example package configuration with all params

# Convenience variables only used in this file
PKG="mypkg"  # Name of source package

# Package sources
#
# These parameters describe the package sources. The only mandatory
# ones are the tarball url and/or the debianization url.

#PACKAGE_NAME[$PKG]="mypkg"			# when key != name
PACKAGE_SOURCE_URL[$PKG]="http://www.example.com/mypkg-1.0.tar.gz"
#PACKAGE_SOURCE_GIT_BRANCH[$PKG]="master"
#PACKAGE_SOURCE_GIT_COMMIT[$PKG]="deadbeef"
PACKAGE_DEBZN_GIT_URL[$PKG]="https://github.com/octocat/mypkg-deb.git"
#PACKAGE_DEBZN_GIT_BRANCH[$PKG]="maint"		# Default "master"
#PACKAGE_COMP[$PKG]="gz"			# Default: guess from tarball
#PACKAGE_FORMAT[$PKG]="3.0 (native)"		# Default "3.0 (quilt)"

# Build params
#
# These optional parameters affect when and how the package is built

#PACKAGE_SBUILD_RESOLVER[$PKG]="aptitude"	# See sbuild(1)
#PACKAGE_EXCLUDE_ARCHES[$PKG]="armhf"		# Don't build these arches
#PACKAGE_NATIVE_BUILD_ONLY[$PKG]="true"		# Cross-compile broken; use qemu
#PACKAGE_QEMU_NOCHECK[$PKG]="true"		# Don't run tests in qemu

# Source package configuration
#
# Some packages need an extra configuration step before building the
# source package from the debianized source tree. There are two
# choices to accomplish this:
#
# This function will be run outside the chroot
#PACKAGE_CONFIGURE_FUNC[$PKG]="configure_mypkg"	# Below function
#
# This function will run inside the chroot; any packages listed in
# PACKAGE_CONFIGURE_CHROOT_DEPS will be installed in the chroot before
# running
#PACKAGE_CONFIGURE_CHROOT_DEPS[$PKG]="python"
#PACKAGE_CONFIGURE_CHROOT_FUNC[$PKG]="configure_mypkg"	# Below function
#
# The function itself.  It must have a unique name.
#configure_mypkg() {
#    do_something
#}
