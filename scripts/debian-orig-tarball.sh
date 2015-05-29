########################################
# Debian orig tarball operations

source_pkg_dir() { echo $(build_base_dir); }
source_git_dir() { echo $(build_base_dir)/source-git; }
source_git_rev() { git_rev "$(source_git_dir)" \
    "${PACKAGE_DEBZN_GIT_BRANCH[$PACKAGE]:-master}" \
    "${PACKAGE_SOURCE_GIT_COMMIT[$PACKAGE]}"; }


source_tarball_init() {
    local VERSION=${PACKAGE_UPSTREAM_VERSION:-vers}
    local BASENAME=${PACKAGE}_${PACKAGE_UPSTREAM_VERSION}

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
	    $(source_git_dir) \
	    ${PACKAGE_SOURCE_URL[$PACKAGE]} \
	    ${PACKAGE_SOURCE_GIT_BRANCH[$PACKAGE]:-master} \
	    ${PACKAGE_SOURCE_GIT_COMMIT[$PACKAGE]}
	git_tree_source_tarball \
	    $(source_git_dir) \
	    ${PACKAGE_SOURCE_GIT_BRANCH[$PACKAGE]:-master} \
	    $(source_pkg_dir)/$INTERMEDIATE_TARBALL \
	    ${PACKAGE_SOURCE_GIT_COMMIT[$PACKAGE]}
	    
    else
	if test ! -f \
	    $(source_pkg_dir)/${PACKAGE}_vers.orig.tar.${PACKAGE_COMP[$PACKAGE]}
	then
	    msg "    Downloading source tarball"
	    debug "      Source: ${PACKAGE_SOURCE_URL[$PACKAGE]}"
	    debug "      Dest: $(source_pkg_dir)/$INTERMEDIATE_TARBALL"
	    run_user mkdir -p $(source_pkg_dir)
	    run_user wget ${PACKAGE_SOURCE_URL[$PACKAGE]} \
		-O $(source_pkg_dir)/$INTERMEDIATE_TARBALL
	else
	    debug "      (Source tarball exists; not downloading)"
	fi
    fi
}

source_tarball_changelog() {
    source_tarball_init

    if is_git_source; then
	echo "    - Src git:" \
	    $(git_tree_info \
	    $(source_git_dir) \
	    ${PACKAGE_SOURCE_URL[$PACKAGE]})
    else
	echo "    - Src tarball: ${PACKAGE_SOURCE_URL[$PACKAGE]}"
    fi
}

source_tarball_unpack() {
    if test -z "${PACKAGE_SOURCE_URL[$PACKAGE]}"; then
	debug "      (No PACKAGE_SOURCE_URL defined; not unpacking)"
	return
    fi

    msg "    Unpacking source tarball"
    run_user tar xCf $(source_package_dir) \
	$(source_pkg_dir)/$INTERMEDIATE_TARBALL \
	--strip-components=1
}

source_tarball_finalize() {
    # Set up variables
    source_tarball_init

    if test -f $(source_pkg_dir)/$INTERMEDIATE_TARBALL; then
	debug "    Linking tarball to Debian orig tarball name"
	run_user ln -f \
	    $(source_pkg_dir)/$INTERMEDIATE_TARBALL \
	    $(source_pkg_dir)/$ORIG_TARBALL
    fi
}


