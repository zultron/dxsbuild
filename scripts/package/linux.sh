PKG="linux"
VERSION="3.8.13"
BASEURL="http://www.kernel.org/pub/linux/kernel/v3.0"

# Disable 'xenomai.x86', 'xenomai.beaglebone' or 'rtai.x86' builds
LINUX_DISABLED_FEATURESETS="xenomai.beaglebone rtai.x86"

# Package sources
PACKAGE_SOURCE_URL[$PKG]="$BASEURL/linux-${VERSION}.tar.xz"
PACKAGE_DEBZN_GIT_URL[$PKG]="https://github.com/zultron/linux-ipipe-deb.git"
PACKAGE_DEBZN_GIT_BRANCH[$PKG]="${VERSION}"

# Build params
PACKAGE_NATIVE_BUILD_ONLY[$PKG]="true"  # Build-Depends: gcc-4.9
#     RCN supplies ARM kernels
PACKAGE_EXCLUDE_ARCHES[$PKG]="armhf"

# Source package configuration
PACKAGE_CONFIGURE_CHROOT_DEPS[$PKG]="python python-six"
# Install Xenomai and RTAI source packages, if applicable
declare -A linux_confdeps=(
    [xenomai.x86]=xenomai-kernel-source
    # [xenomai.beaglebone]=xenomai-kernel-source
    # [rtai.x86]=rtai-source
)
for i in ${LINUX_DISABLED_FEATURESETS}; do linux_confdeps[$i]=; done
PACKAGE_CONFIGURE_CHROOT_DEPS[$PKG]+=" ${linux_confdeps[*]}"
PACKAGE_CONFIGURE_CHROOT_FUNC[$PKG]="configure_linux"

configure_linux() {
    # Set gcc compiler version
    local GCC_VER=4.8
    case $DISTRO in
	jessie) GCC_VER=4.8 ;;
	trusty) GCC_VER=4.8 ;;
	wheezy) GCC_VER=4.7 ;;
    esac
    debug "    Setting gcc to 'gcc-${GCC_VER}'"
    run sed -ie "/^compiler:/ s/gcc-.*/gcc-${GCC_VER}/" \
	debian/config/defines

    # Disable featuresets
    for featureset in $LINUX_DISABLED_FEATURESETS; do
	debug "    Disabling featureset $featureset"
	run sed -i debian/config/defines \
	    -e "/^ \+${featureset}$/ s/^/#/" \
	    -e "/\[featureset-${featureset}_base\]/,/^\[/ \
		    s/enabled: true/enabled: false/"
    done

    debug "    Running configure script"
    run debian/rules debian/control NOFAIL=true
    run debian/rules clean
}
