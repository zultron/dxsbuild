PKG="libsodium"
VERSION="1.0.0"

# Package sources
BASE_URL="http://download.libsodium.org/libsodium/releases"
PACKAGE_SOURCE_URL[$PKG]="$BASE_URL/libsodium-${VERSION}.tar.gz"
PACKAGE_DEBZN_GIT_URL[$PKG]="https://github.com/zultron/libsodium-deb.git"

# Build params
# dh_strip -s
# arm-linux-gnueabihf-strip:debian/libsodium/usr/lib/libsodium.so.13.0.2:
#   File format not recognized
# dh_strip: arm-linux-gnueabihf-strip --remove-section=.comment
#   --remove-section=.note --strip-unneeded
#   debian/libsodium/usr/lib/libsodium.so.13.0.2 returned exit code 1
# make: *** [binary-arch] Error 29
PACKAGE_NATIVE_BUILD_ONLY[$PKG]="true"
