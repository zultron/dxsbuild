PKG="pyzmq"
VERSION="14.3.0"
BASEURL="https://github.com/zeromq/pyzmq/archive"

# Package sources
PACKAGE_TARBALL_URL[$PKG]="$BASEURL/v${VERSION}.tar.gz"
PACKAGE_DEBZN_GIT_URL[$PKG]="https://github.com/zultron/pyzmq-deb.git"

# Build params
#     'apt' resolver:  'Build-Depends dependency for
#        sbuild-build-depends-pyzmq-dummy cannot be satisfied because the
#        package python-nose cannot be found'
#     'aptitude' resolver installs a bunch of amd64 pkgs
#     'xapt' unavailable in Jessie
PACKAGE_NATIVE_BUILD_ONLY[$PKG]="true"
