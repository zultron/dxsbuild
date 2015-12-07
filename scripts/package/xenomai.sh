PKG="xenomai"
BASEURL="http://download.gna.org/xenomai/stable"
VERSION="2.6.4"

# Package sources
PACKAGE_SOURCE_URL[$PKG]="$BASEURL/xenomai-$VERSION.tar.bz2"
PACKAGE_DEBZN_GIT_URL[$PKG]="https://github.com/zultron/xenomai-deb.git"

# Build params
#     RCN supplies ARM kernels
PACKAGE_EXCLUDE_ARCHES[$PKG]="armhf"
