PKG="czmq"
VERSION="2.2.0"

# Package sources
PACKAGE_SOURCE_URL[$PKG]="http://download.zeromq.org/czmq-${VERSION}.tar.gz"
PACKAGE_DEBZN_GIT_URL[$PKG]="https://github.com/zultron/czmq-deb.git"

# Build params
PACKAGE_QEMU_NOCHECK[$PKG]="true"  # Tests hang in qemu
PACKAGE_NATIVE_BUILD_ONLY[$PKG]="true"

# Source package configuration
PACKAGE_CONFIGURE_FUNC[$PKG]="configure_czmq"

configure_czmq() {
    if test $DISTRO = trusty; then
	debug "    Removing Build-Depends: libsodium for Trusty"
	sed -ie '/libsodium-dev/ d' debian/control
    fi
}
