########################################
# Debian orig tarball operations
debug "    Sourcing debian-orig-tarball.sh"

source_tarball_init() {
    case "${PACKAGE_COMP[$PACKAGE]}" in
	gz) DPKG_BUILD_ARGS=-Zgzip ;;
	xz) DPKG_BUILD_ARGS=-Zxz ;;
	bz2) DPKG_BUILD_ARGS=-Zbzip2 ;;
	*) error "Package $PACKAGE:  Unknown package compression format" ;;
    esac

    local BASENAME=${PACKAGE}_${PACKAGE_VER}
    case "${PACKAGE_FORMAT[$PACKAGE]}" in
	'3.0 (quilt)')
	    ORIG_TARBALL=${BASENAME}.orig.tar.${PACKAGE_COMP[$PACKAGE]}
	    ;;
	'3.0 (native)')
	    ORIG_TARBALL=${BASENAME}.tar.${PACKAGE_COMP[$PACKAGE]}
	    ;;
	*)
	    error "Package ${PACKAGE}:" \
		"Unknown package format '${PACKAGE_FORMAT[$PACKAGE]}'"
	    ;;
    esac
}

source_tarball_download() {
    if test -n "${PACKAGE_TARBALL_URL[$PACKAGE]}"; then
	if test ! -f $SOURCE_PKG_DIR/$ORIG_TARBALL; then
	    msg "    Downloading source tarball"
	    debug "      Source: ${PACKAGE_TARBALL_URL[$PACKAGE]}"
	    debug "      Dest: $SOURCE_PKG_DIR/$ORIG_TARBALL"
	    run_user mkdir -p $SOURCE_PKG_DIR
	    run_user wget ${PACKAGE_TARBALL_URL[$PACKAGE]} \
		-O $SOURCE_PKG_DIR/$ORIG_TARBALL
	else
	    debug "      (Source tarball exists; not downloading)"
	fi
    else
	debug "      (No TARBALL_URL defined; not downloading source tarball)"
    fi
}

source_tarball_unpack() {
    if test -z "${PACKAGE_TARBALL_URL[$PACKAGE]}"; then
	debug "      (No PACKAGE_TARBALL_URL defined; not unpacking)"
	return
    fi

    msg "    Unpacking source tarball"
    run_user tar xCf $BUILD_SRC_DIR $SOURCE_PKG_DIR/$ORIG_TARBALL \
	--strip-components=1
}


