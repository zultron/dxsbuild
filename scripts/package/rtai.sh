PKG="rtai"
GIT_REV="a416758"
GIT_BASEURL="https://github.com/ShabbyX/RTAI/archive"

# Package sources
PACKAGE_TARBALL_URL[$PKG]="$GIT_BASEURL/${GIT_REV}.tar.gz"
PACKAGE_DEBZN_GIT_URL[$PKG]="https://github.com/zultron/rtai-deb.git"

# Build params
PACKAGE_EXCLUDE_ARCHES[$PKG]="armhf"
