VERSION=3.8.13
TARBALL_URL=http://www.kernel.org/pub/linux/kernel/v3.0/linux-${VERSION}.tar.xz
GIT_URL=https://github.com/zultron/linux-tools-deb.git
DEBIAN_PACKAGE_COMP=xz
# 'apt' resolver chokes on libperl-dev:armhf -> perl:armhf
# 'aptitude' resolver installs a bunch of amd64-arch pkgs
NATIVE_BUILD_ONLY=true

CONFIGURE_PACKAGE_DEPS="python debhelper"

configure_package() {
    debian/rules debian/control || true # always fails
    debian/rules clean
}
