debug "Sourcing configs/package/linux-tools.sh"

VERSION=60
GIT_URL=https://github.com/zultron/linux-latest-deb.git
DEBIAN_PACKAGE_FORMAT='3.0 (quilt)'
DEBIAN_PACKAGE_COMP=xz

EXTRA_BUILD_PACKAGES="python debhelper linux-support-3.8-1"

configure_package() {
    debian/rules debian/control || true # always fails
    debian/rules clean
}
