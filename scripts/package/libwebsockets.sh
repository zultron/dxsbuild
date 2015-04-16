PKG="libwebsockets"
BASE_URL="http://git.libwebsockets.org/cgi-bin/cgit/libwebsockets/snapshot"
GIT_REV="95a8abb"

# Package sources
PACKAGE_SOURCE_URL[$PKG]="$BASE_URL/libwebsockets-${GIT_REV}.tar.gz"
PACKAGE_DEBZN_GIT_URL[$PKG]="https://github.com/zultron/libwebsockets-deb.git"
