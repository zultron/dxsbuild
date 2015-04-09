########################################
# Debian orig tarball operations
debug "    Sourcing debian-orig-tarball.sh"

source_tarball_init() {
    case "$DEBIAN_PACKAGE_COMP" in
	gz)
	    DPKG_BUILD_ARGS=-Zgzip
	    ;;
	xz)
	    DPKG_BUILD_ARGS=-Zxz
	    ;;
	# Default to bz2
	bz2|*)
	    DPKG_BUILD_ARGS=-Zbzip2
	    DEBIAN_PACKAGE_COMP=bz2
	    ;;
    esac

    local BASENAME=${PACKAGE}_${PACKAGE_VER}
    case "$DEBIAN_PACKAGE_FORMAT" in
	'3.0 (quilt)')
	    DEBIAN_TARBALL=${BASENAME}.orig.tar.${DEBIAN_PACKAGE_COMP}
	    ;;
	'3.0 (native)')
	    DEBIAN_TARBALL=${BASENAME}.tar.${DEBIAN_PACKAGE_COMP}
	    ;;
	*)
	    error "Package ${PACKAGE}:" \
		"Unknown package format '${DEBIAN_PACKAGE_FORMAT}'"
	    ;;
    esac
}

source_tarball_download() {
    if test -n "$TARBALL_URL"; then
	if test ! -f $SOURCE_PKG_DIR/$DEBIAN_TARBALL; then
	    msg "    Downloading source tarball"
	    debug "      Source: $TARBALL_URL"
	    debug "      Dest: $SOURCE_PKG_DIR/$DEBIAN_TARBALL"
	    run_user mkdir -p $SOURCE_PKG_DIR
	    run_user wget $TARBALL_URL -O $SOURCE_PKG_DIR/$DEBIAN_TARBALL
	else
	    debug "      (Source tarball exists; not downloading)"
	fi
    else
	debug "      (No TARBALL_URL defined; not downloading source tarball)"
    fi
}

source_tarball_unpack() {
    if test -z "$TARBALL_URL"; then
	debug "      (No TARBALL_URL defined; not unpacking source tarball)"
	return
    fi

    msg "    Unpacking source tarball"
    run_user tar xCf $BUILD_SRC_DIR $SOURCE_PKG_DIR/$DEBIAN_TARBALL \
	--strip-components=1
}


