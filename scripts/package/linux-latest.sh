GIT_URL=https://github.com/zultron/linux-latest-deb.git
DEBIAN_PACKAGE_FORMAT='3.0 (native)'
DEBIAN_PACKAGE_COMP=xz
SBUILD_RESOLVER=aptitude  # Default 'apt' resolver chokes on linux-support-3.8-1
GIT_BRANCH=3.8.13

CONFIGURE_PACKAGE_DEPS="python debhelper linux-support-3.8-1"

configure_package() {
    debian/rules debian/control || true # always fails
    debian/rules clean
}
