PKG="linux-latest"

# Package sources
PACKAGE_DEBZN_GIT_URL[$PKG]="https://github.com/zultron/linux-latest-deb.git"
PACKAGE_DEBZN_GIT_BRANCH[$PKG]="3.8.13"
PACKAGE_FORMAT[$PKG]='3.0 (native)'

# Build params
#     Default 'apt' resolver chokes on linux-support-3.8-1
PACKAGE_SBUILD_RESOLVER[$PKG]="aptitude"

# Source package configuration
PACKAGE_CONFIGURE_DEPS[$PKG]="python debhelper linux-support-3.8-1"
PACKAGE_CONFIGURE_FUNC[$PKG]="configure_linux_latest"

configure_linux_latest() {
    debian/rules debian/control || true # always fails
    debian/rules clean
}
