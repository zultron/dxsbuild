PKG="machinekit"
GIT_REV="357b816ae3"
GIT_BASEURL="https://github.com/zultron/machinekit/archive"

# Package sources
PACKAGE_TARBALL_URL[$PKG]="$GIT_BASEURL/${GIT_REV}.tar.gz"

# Source package configuration
PACKAGE_CONFIGURE_FUNC[$PKG]="configure_machinekit"

configure_machinekit() {

    case $DISTRO in
	wheezy) TCL_VER=8.5 ;;
	jessie|trusty) TCL_VER=8.6 ;;
    esac

    run debian/configure -prxt $TCL_VER
}
