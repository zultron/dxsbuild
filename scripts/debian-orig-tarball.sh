########################################
# Debian orig tarball operations

source_tarball_init() {
    local VERSION=${PACKAGE_VER:-vers}
    local BASENAME=${PACKAGE}_${PACKAGE_VER}

    INTERMEDIATE_TARBALL=${PACKAGE}_vers.orig.tar.${PACKAGE_COMP[$PACKAGE]}

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

    debug "      Package format:  ${PACKAGE_FORMAT[$PACKAGE]}"
}

source_tarball_download() {
    if test -z "${PACKAGE_SOURCE_URL[$PACKAGE]}"; then
	debug "      (No TARBALL_URL defined; not downloading source tarball)"
	return
    fi

    # Set up variables
    source_tarball_init

    if is_git_source; then
	git_tree_update \
	    $SOURCE_GIT_DIR \
	    ${PACKAGE_SOURCE_URL[$PACKAGE]} \
	    ${PACKAGE_SOURCE_GIT_BRANCH[$PACKAGE]:-master} \
	    ${PACKAGE_SOURCE_GIT_COMMIT[$PACKAGE]}
	git_tree_source_tarball \
	    $SOURCE_GIT_DIR \
	    ${PACKAGE_SOURCE_GIT_BRANCH[$PACKAGE]:-master} \
	    $SOURCE_PKG_DIR/$INTERMEDIATE_TARBALL
	    
    else
	if test ! -f \
	    $SOURCE_PKG_DIR/${PACKAGE}_vers.orig.tar.${PACKAGE_COMP[$PACKAGE]}
	then
	    msg "    Downloading source tarball"
	    debug "      Source: ${PACKAGE_SOURCE_URL[$PACKAGE]}"
	    debug "      Dest: $SOURCE_PKG_DIR/$INTERMEDIATE_TARBALL"
	    run_user mkdir -p $SOURCE_PKG_DIR
	    run_user wget ${PACKAGE_SOURCE_URL[$PACKAGE]} \
		-O $SOURCE_PKG_DIR/$INTERMEDIATE_TARBALL
	else
	    debug "      (Source tarball exists; not downloading)"
	fi
    fi
}

source_tarball_unpack() {
    if test -z "${PACKAGE_SOURCE_URL[$PACKAGE]}"; then
	debug "      (No PACKAGE_SOURCE_URL defined; not unpacking)"
	return
    fi

    msg "    Unpacking source tarball"
    run_user tar xCf $BUILD_SRC_DIR  $SOURCE_PKG_DIR/$INTERMEDIATE_TARBALL \
	--strip-components=1
}

source_tarball_finalize() {
    # Set up variables
    source_tarball_init

    if test -f $SOURCE_PKG_DIR/$INTERMEDIATE_TARBALL; then
	debug "    Linking tarball to Debian orig tarball name"
	run_user ln -f \
	    $SOURCE_PKG_DIR/$INTERMEDIATE_TARBALL \
	    $SOURCE_PKG_DIR/$ORIG_TARBALL
    fi
}


