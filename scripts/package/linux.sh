debug "Sourcing configs/package/linux.sh"

VERSION=3.8.13
RELEASE=11
TARBALL_URL=http://www.kernel.org/pub/linux/kernel/v3.0/linux-${VERSION}.tar.xz
GIT_URL=https://github.com/zultron/linux-ipipe-deb.git
GIT_BRANCH=3.8.13
DEBIAN_PACKAGE_FORMAT='3.0 (quilt)'
DEBIAN_PACKAGE_COMP=xz
NATIVE_BUILD_ONLY=true  # Build-Depends: gcc-4.9

FEATURESETS="xenomai rtai"
DISABLED_FEATURESETS=""  # Set to 'xenomai' or 'rtai' to skip build

EXTRA_BUILD_PACKAGES=python
# Add xenomai-kernel-source if not disabled
DISABLED_FEATURESETS=" $DISABLED_FEATURESETS "
test "${DISABLED_FEATURESETS/xenomai/}" != "$DISABLED_FEATURESETS" || \
EXTRA_BUILD_PACKAGES+=" xenomai-kernel-source"
# Add rtai-source if not disabled
DISABLED_FEATURESETS=" $DISABLED_FEATURESETS "
test "${DISABLED_FEATURESETS/rtai/}" != "$DISABLED_FEATURESETS" || \
EXTRA_BUILD_PACKAGES+=" rtai-source"

configure_package() {
    for featureset in $DISABLED_FEATURESETS; do
	debug "      Disabling featureset $featureset"
	sed -i 's/^\( *'$featureset'$\)/#\1/' debian/config/defines
    done
    debug "      Running configure script"
    debian/rules debian/control NOFAIL=true
    debian/rules clean
}
