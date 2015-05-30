PKG="xenomai-3"
BASEURL="http://git.xenomai.org/xenomai-3.git/snapshot"
VERSION="3.0-rc4"

# Package sources
PACKAGE_NAME[$PKG]="xenomai"
PACKAGE_SOURCE_URL[$PKG]="$BASEURL/xenomai-3-$VERSION.tar.bz2"
PACKAGE_DEBZN_GIT_URL[$PKG]="https://github.com/zultron/xenomai-deb.git"
PACKAGE_DEBZN_GIT_BRANCH[$PKG]="${VERSION}"
