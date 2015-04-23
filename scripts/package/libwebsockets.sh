PKG="libwebsockets"
GIT_REV="95a8abb"

# Package sources
PACKAGE_SOURCE_URL[$PKG]="https://github.com/warmcat/libwebsockets.git"
PACKAGE_SOURCE_GIT_BRANCH[$PKG]="$GIT_REV"
PACKAGE_SOURCE_GIT_DEPTH[$PKG]="0"
PACKAGE_DEBZN_GIT_URL[$PKG]="https://github.com/zultron/libwebsockets-deb.git"

# Build params
PACKAGE_NATIVE_BUILD_ONLY[$PKG]="true"		# Cross-compile broken; use qemu
