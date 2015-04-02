debug "Sourcing configs/package/xenomai.sh"

VERSION=2.6.4
RELEASE=1
TARBALL_URL=http://download.gna.org/xenomai/stable/xenomai-$VERSION.tar.bz2
GIT_URL=https://github.com/zultron/xenomai-deb.git
DEBIAN_PACKAGE_FORMAT='3.0 (quilt)'
DEBIAN_PACKAGE_COMP=bz2


BINARY_PACKAGES="
    libxenomai-dev_${VERSION}_*.deb
    libxenomai1_${VERSION}_*.deb
    xenomai-doc_${VERSION}_all.deb
    xenomai-kernel-source_${VERSION}_all.deb
    xenomai-runtime_${VERSION}_*.deb
"
