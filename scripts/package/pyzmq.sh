debug "Sourcing pyzmq.sh"

VERSION=14.3.0
RELEASE=4
TARBALL_URL=https://github.com/zeromq/pyzmq/archive/v${VERSION}.tar.gz
GIT_URL=https://github.com/zultron/pyzmq-deb.git
DEBIAN_PACKAGE_FORMAT='3.0 (quilt)'
DEBIAN_PACKAGE_COMP=gz
NATIVE_BUILD_ONLY=true  # "package python-nose cannot be found" (???)
