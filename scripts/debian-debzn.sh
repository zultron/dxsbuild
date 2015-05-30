########################################
# Debianization git tree operations

debzn_git_dir() { echo $(build_base_dir)/debzn-git; }
debzn_git_rev() { git_rev $(debzn_git_dir); }

debzn_tarball_glob() { \
    echo $(
	readlink -e $(build_dir)/${PACKAGE_NAME[$PACKAGE]}_*$(
	    package_version_suffix).debian.tar.*); }

parse_changelog() {
    dpkg-parsechangelog --file $(source_package_dir)/debian/changelog \
	--show-field $1
}

debianization_git_tree_update() {
    if test -z "${PACKAGE_DEBZN_GIT_URL[$PACKAGE]}"; then
	debug "    (No PACKAGE_DEBZN_GIT_URL defined; not handling git tree)"
	return
    fi

    git_tree_update \
	$(debzn_git_dir) \
	${PACKAGE_DEBZN_GIT_URL[$PACKAGE]} \
	${PACKAGE_DEBZN_GIT_BRANCH[$PACKAGE]:-master}
}

debianization_init() {
    PACKAGE_VERSION=$(parse_changelog version)
    debug "      Upstream package version-release:  $PACKAGE_VERSION"
    PACKAGE_UPSTREAM_VERSION=$(echo $PACKAGE_VERSION | sed 's/\(.*\)-.*/\1/')
    debug "      Package version:  $PACKAGE_UPSTREAM_VERSION"
    PACKAGE_RELEASE=$(echo $PACKAGE_VERSION | \
	sed -e 's/^\([^-]*\)$/\1-/' -e 's/[^-]*-//')
    debug "      Upstream package release:  $PACKAGE_RELEASE"
    PACKAGE_DISTRIBUTION=$(parse_changelog distribution)
    debug "      Package distribution:  $PACKAGE_DISTRIBUTION"
    PACKAGE_URGENCY=$(parse_changelog urgency)
    debug "      Package urgency:  $PACKAGE_URGENCY"
    PACKAGE_NEW_VERSION="${PACKAGE_VERSION}$(package_version_suffix -d)"
    debug "      New package version-release:  $PACKAGE_NEW_VERSION"
    DSC_FILE=$(source_package_dsc_glob)
    debug "      .dsc file name:  $(basename '$DSC_FILE')"
    CHANGELOG=/tmp/changelog-$PACKAGE-$DISTRO

    if test -z "$MAINTAINER"; then
	MAINTAINER="$(git --git-dir=$(debzn_git_dir) config user.name)" || \
	    error "Please set 'MAINTAINER' in local-config.sh"
    fi
    if test -z "$EMAIL"; then
	EMAIL="$(git --git-dir=$(debzn_git_dir) config user.email)" || \
	    error "Please set 'EMAIL' in local-config.sh"
    fi
    debug "      Maintainer <email>:  $MAINTAINER <$EMAIL>"
}

debianization_changelog() {
    debianization_init

    echo "    - Deb git:" \
	$(git_tree_info \
	$(debzn_git_dir) \
	${PACKAGE_DEBZN_GIT_URL[$PACKAGE]})
}

debianization_add_changelog() {
    # https://www.debian.org/doc/debian-policy/ch-source.html#s-dpkgchangelog
    msg "    Adding new changelog entry"

    debianization_init

    # Calculate first line of changelog entry
    PACKAGE_CHANGELOG_HEAD="$(echo "${PACKAGE_NAME[$PACKAGE]}" \
	"(${PACKAGE_NEW_VERSION})" \
	"${PACKAGE_DISTRIBUTION};" "urgency=${PACKAGE_URGENCY}")"

    # Calculate trailer line of changelog entry
    PACKAGE_CHANGELOG_TRAILER=" -- $MAINTAINER <$EMAIL>  $(date -R)"

    # Write changelog entry
    debug "      Intermediate changelog file: $CHANGELOG"
    (
	echo "$PACKAGE_CHANGELOG_HEAD"
	echo
	echo "  * Rebuilt in mk-debuild"
	echo "    - See https://github.com/zultron/dxsbuild"
	source_tarball_changelog
	debianization_changelog
	echo
	echo "$PACKAGE_CHANGELOG_TRAILER"
	echo
    ) > $CHANGELOG

    debug "      Full changelog:"
    run_debug cat $CHANGELOG
    run bash -c "cat $(source_package_dir)/debian/changelog >> $CHANGELOG"
    run_user cp $CHANGELOG $(source_package_dir)/debian/changelog
}

debianization_git_tree_unpack() {
    if test -n "${PACKAGE_DEBZN_GIT_URL[$PACKAGE]}"; then
	msg "    Copying debianization from git tree"
	debug "      Debzn git dir: $(debzn_git_dir)"
	debug "      Dest dir: $(source_package_dir)/debian"
	debug "      Git branch:  ${PACKAGE_DEBZN_GIT_BRANCH[$PACKAGE]}"
	run_user bash -c "'git --git-dir=$(debzn_git_dir) archive \\
	    --prefix=debian/ dxsbuild_branch | \\
	    tar xCf $(source_package_dir) -'"
    else
	debug "      (No PACKAGE_DEBZN_GIT_URL defined; not unpacking from git)"
    fi
}

