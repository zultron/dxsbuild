PKG="python-pyftpdlib"
VERSION="1.2.0"
BASEURL="https://github.com/giampaolo/pyftpdlib/archive"
GIT_BASEURL="https://github.com/zultron"

# Package sources
PACKAGE_SOURCE_URL[$PKG]="$BASEURL/release-$VERSION.tar.gz"
PACKAGE_DEBZN_GIT_URL[$PKG]="$GIT_BASEURL/python-pyftpdlib-deb.git"
