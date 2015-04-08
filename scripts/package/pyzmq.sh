VERSION=14.3.0
RELEASE=4
TARBALL_URL=https://github.com/zeromq/pyzmq/archive/v${VERSION}.tar.gz
GIT_URL=https://github.com/zultron/pyzmq-deb.git
DEBIAN_PACKAGE_FORMAT='3.0 (quilt)'
DEBIAN_PACKAGE_COMP=gz
# 'apt' resolver:  'Build-Depends dependency for
#    sbuild-build-depends-pyzmq-dummy cannot be satisfied because the
#    package python-nose cannot be found'
# 'aptitude' resolver installs a bunch of amd64 pkgs
# 'xapt' unavailable in Jessie
NATIVE_BUILD_ONLY=true
