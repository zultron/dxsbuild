PKG="linux-tools"
VERSION="3.8.13"
BASEURL="http://www.kernel.org/pub/linux/kernel/v3.0"

# Package sources
PACKAGE_SOURCE_URL[$PKG]="$BASEURL/linux-${VERSION}.tar.xz"
PACKAGE_DEBZN_GIT_URL[$PKG]="https://github.com/zultron/linux-tools-deb.git"

# Build params
#     'apt' resolver chokes on libperl-dev:armhf -> perl:armhf
#     'aptitude' resolver installs a bunch of amd64-arch pkgs
PACKAGE_NATIVE_BUILD_ONLY[$PKG]="true"

# Source package configuration
PACKAGE_CONFIGURE_DEPS[$PKG]="python debhelper"
PACKAGE_CONFIGURE_FUNC[$PKG]="configure_linux_tools"

configure_linux_tools() {
    debian/rules debian/control || true # always fails
    debian/rules clean
}
