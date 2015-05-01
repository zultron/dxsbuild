PKG="zeromq3"
VERSION="4.0.5"

# Package sources
PACKAGE_SOURCE_URL[$PKG]="http://download.zeromq.org/zeromq-${VERSION}.tar.gz"
PACKAGE_DEBZN_GIT_URL[$PKG]="https://github.com/zultron/zeromq3-deb.git"

# Build params
PACKAGE_QEMU_NOCHECK[$PKG]="true"		# Tests hang in qemu
PACKAGE_NATIVE_BUILD_ONLY[$PKG]="true"		# Cross-compile broken; use qemu
