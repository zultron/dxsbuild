debug "Sourcing configs/package/linux-tools.sh"

VERSION=3.8.13
RELEASE=3da
TARBALL_URL=http://www.kernel.org/pub/linux/kernel/v3.0/linux-${VERSION}.tar.xz
GIT_URL=https://github.com/zultron/linux-tools-deb.git
DEBIAN_PACKAGE_FORMAT='3.0 (quilt)'
DEBIAN_PACKAGE_COMP=xz

EXTRA_BUILD_PACKAGES="python debhelper"

configure_package() {
    debian/rules debian/control || true # always fails
    debian/rules clean
}
