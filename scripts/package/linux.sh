VERSION=3.8.13
TARBALL_URL=http://www.kernel.org/pub/linux/kernel/v3.0/linux-${VERSION}.tar.xz
GIT_URL=https://github.com/zultron/linux-ipipe-deb.git
GIT_BRANCH=${VERSION}
DEBIAN_PACKAGE_COMP=xz
NATIVE_BUILD_ONLY=true  # Build-Depends: gcc-4.9

FEATURESETS="xenomai rtai"
DISABLED_FEATURESETS=""  # Set to 'xenomai' or 'rtai' to skip build

CONFIGURE_PACKAGE_DEPS=python
# Add xenomai-kernel-source if not disabled
DISABLED_FEATURESETS=" $DISABLED_FEATURESETS "
test "${DISABLED_FEATURESETS/xenomai/}" != "$DISABLED_FEATURESETS" || \
CONFIGURE_PACKAGE_DEPS+=" xenomai-kernel-source"
# Add rtai-source if not disabled
DISABLED_FEATURESETS=" $DISABLED_FEATURESETS "
test "${DISABLED_FEATURESETS/rtai/}" != "$DISABLED_FEATURESETS" || \
CONFIGURE_PACKAGE_DEPS+=" rtai-source"

configure_package() {
    if test $CODENAME = trusty; then
	debug "    Setting gcc to 'gcc-4.8'"
	sed -ie '/^compiler:/ s/gcc-.*/gcc-4.8/' debian/config/defines
    fi
    for featureset in $DISABLED_FEATURESETS; do
	debug "    Disabling featureset $featureset"
	sed -i 's/^\( *'$featureset'$\)/#\1/' debian/config/defines
    done
    debug "    Running configure script"
    debian/rules debian/control NOFAIL=true
    debian/rules clean
}
