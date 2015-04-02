debug "Sourcing configs/package/rtai.sh"

GIT_REV=a416758
VERSION=4.0.5.${GIT_REV}
RELEASE=1
TARBALL_URL=https://github.com/ShabbyX/RTAI/archive/${GIT_REV}.tar.gz
GIT_URL=https://github.com/zultron/rtai-deb.git
GIT_REPO=rtai-deb

BINARY_PACKAGES="
    rtai-source_${VERSION}-${RELEASE}_*.deb
    librtai-dev_${VERSION}-${RELEASE}_*.deb
    librtai1_${VERSION}-${RELEASE}_*.deb
    rtai_${VERSION}-${RELEASE}_*.deb
    python-rtai_${VERSION}-${RELEASE}_all.deb
    rtai-doc_${VERSION}-${RELEASE}_all.deb
"
