# Example package configuration with all params

# Convenience variables only used in this file
PKG="mypkg"  # Name of source package

# Package sources
#
# These parameters describe the package sources. The only mandatory
# ones are the tarball url and/or the debianization url.

PACKAGE_TARBALL_URL[$PKG]="http://www.example.com/mypkg-1.0.tar.gz"
PACKAGE_DEBZN_GIT_URL[$PKG]="https://github.com/octocat/mypkg-deb.git"
#PACKAGE_DEBZN_GIT_BRANCH[$PKG]="maint"		# Default "master"
#PACKAGE_COMP[$PKG]="gz"			# Default: guess from tarball
#PACKAGE_FORMAT[$PKG]="3.0 (native)"		# Default "3.0 (quilt)"

# Build params
#
# These optional parameters affect when and how the package is built

#PACKAGE_SBUILD_RESOLVER[$PKG]="aptitude"	# See sbuild(1)
#PACKAGE_NATIVE_BUILD_ONLY[$PKG]="true"		# Cross-compile broken; use qemu
#PACKAGE_EXCLUDE_ARCHES[$PKG]="armhf"		# Don't build these arches

# Source package configuration
#
# Some packages need an extra configuration step before building the
# source package from the debianized source tree. These configure a
# function that will be run in the distro schroot, along with needed
# package deps.

#PACKAGE_CONFIGURE_DEPS[$PKG]="python"		# Required
#PACKAGE_CONFIGURE_FUNC[$PKG]="configure_mypkg"	# Below function

#configure_mypkg() {
#    do_something
#}
