debug "Sourcing configs/package/linux.sh"

VERSION=3.8.13
RELEASE=11
TARBALL_URL=http://www.kernel.org/pub/linux/kernel/v3.0/linux-${VERSION}.tar.xz
DEBIAN_TARBALL=linux_$VERSION.orig.tar.xz
DEBIAN_PKG_URL=https://github.com/zultron/linux-ipipe-deb/archive/${VERSION}.tar.gz
GIT_URL=https://github.com/zultron/linux-ipipe-deb.git
GIT_REPO=linux-ipipe-deb
LOCAL_DEPS="
    x/xenomai/xenomai-kernel-source_*.deb
    r/rtai/rtai-source_*.deb
    r/rtai/python-rtai_*_all.deb
"

FEATURESETS="xenomai rtai"
DISABLED_FEATURESETS=""  # Set to 'xenomai' or 'rtai' to skip build

#############
# The Debian Linux package naming scheme is a small nightmare
LINUX_SUBVER=$(echo $VERSION | sed 's/\.[0-9]*$$//')
LINUX_PKG_ABI=1
LINUX_PKG_EXTENSION=${LINUX_SUBVER}-${LINUX_PKG_ABI}

ARCH=amd64  # FIXME:  need all arches

BINARY_PACKAGES="
    linux-support-${LINUX_PKG_EXTENSION}_${VERSION}-${RELEASE}_all.deb"
for fs_base in $FEATURESETS; do
    case $ARCH in
	amd64) fs=${fs_base}.x86; flav=amd64; arch=$ARCH ;;
	i386) fs=${fs_base}.x86; flav=686-pae; arch=$ARCH ;;
	armhf.bbb) fs=${fs_base}.beaglebone; flav=omap; arch=armhf ;;
	armhf.rpi) fs=${fs_base}.raspberry; flav=rpi; arch=armhf ;; # FIXME
    esac
    PKG_SUFF=${VERSION}-${RELEASE}_${arch}.deb
    BINARY_PACKAGES+="
	linux-image-${LINUX_PKG_EXTENSION}-${fs}-${flav}_${PKG_SUFF}
	linux-headers-${LINUX_PKG_EXTENSION}-${fs}-${flav}_${PKG_SUFF}
	linux-headers-${LINUX_PKG_EXTENSION}-common-${fs}_${PKG_SUFF}
    "  # FIXME:  need to filter packages for each arch
done
#############

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
    (
	cd $BUILD_DIR
	# Disable any requested featuresets
	for featureset in $DISABLED_FEATURESETS; do
	    sed -i 's/^\( *'$featureset'$\)/#\1/' debian/config/defines
	done
	# Configure package
	debian/rules debian/control NOFAIL=true
    )
}
