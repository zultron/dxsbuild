########################################
# Debianization git tree operations
debug "    Sourcing debian-debzn.sh"

parse_changelog() {
    dpkg-parsechangelog --file $BUILD_SRC_DIR/debian/changelog --show-field $1
}

debianization_git_tree_update() {
    if test -z "${PACKAGE_DEBZN_GIT_URL[$PACKAGE]}"; then
	debug "    (No PACKAGE_DEBZN_GIT_URL defined; not handling git tree)"
	return
    fi

    git_tree_update \
	$DEBZN_GIT_DIR \
	${PACKAGE_DEBZN_GIT_URL[$PACKAGE]} \
	${PACKAGE_DEBZN_GIT_BRANCH[$PACKAGE]:-master}
}

debianization_init() {
    PACKAGE_VERSION=$(parse_changelog version)
    debug "      Upstream package version-release:  $PACKAGE_VERSION"
    PACKAGE_VER=$(echo $PACKAGE_VERSION | sed 's/\(.*\)-.*/\1/')
    debug "      Package version:  $PACKAGE_VER"
    PACKAGE_RELEASE=$(echo $PACKAGE_VERSION | \
	sed -e 's/^\([^-]*\)$/\1-/' -e 's/[^-]*-//')
    debug "      Upstream package release:  $PACKAGE_RELEASE"
    PACKAGE_DISTRIBUTION=$(parse_changelog distribution)
    debug "      Package distribution:  $PACKAGE_DISTRIBUTION"
    PACKAGE_URGENCY=$(parse_changelog urgency)
    debug "      Package urgency:  $PACKAGE_URGENCY"
    DISTRO_SUFFIX="~1${DISTRO/-/.}"
    PACKAGE_NEW_VERSION_SUFFIX="${DISTRO_SUFFIX}${PACKAGE_VERSION_SUFFIX}"
    if is_git_source; then
	local PREFIX="~$(date +%s)git$(git_rev)"
	PACKAGE_NEW_VERSION_SUFFIX="${PREFIX}${PACKAGE_NEW_VERSION_SUFFIX}"
    fi
    PACKAGE_NEW_VERSION="${PACKAGE_VERSION}${PACKAGE_NEW_VERSION_SUFFIX}"
    debug "      New package version-release:  $PACKAGE_NEW_VERSION"
    DSC_FILE=${PACKAGE}_${PACKAGE_NEW_VERSION}.dsc
    debug "      .dsc file name:  $DSC_FILE"
    CHANGELOG=/tmp/changelog-$PACKAGE-$DISTRO

    if test -z "$MAINTAINER"; then
	MAINTAINER="$(git config user.name)" || MAINTAINER="dxsbuild user"
    fi
    if test -z "$EMAIL"; then
	EMAIL="$(git config user.email)" || EMAIL="dxsbuild@example.com"
    fi
    debug "      Maintainer <email>:  $MAINTAINER <$EMAIL>"
}

debianization_add_changelog() {
    # https://www.debian.org/doc/debian-policy/ch-source.html#s-dpkgchangelog
    msg "    Adding new changelog entry"

    debianization_init

    # Calculate first line of changelog entry
    PACKAGE_CHANGELOG_HEAD="$(echo "${PACKAGE}" "(${PACKAGE_NEW_VERSION})" \
	"${PACKAGE_DISTRIBUTION};" "urgency=${PACKAGE_URGENCY}")"

    # Calculate trailer line of changelog entry
    PACKAGE_CHANGELOG_TRAILER=" -- $MAINTAINER <$EMAIL>  $(date -R)"

    # Write changelog entry
    debug "      Intermediate changelog file: $CHANGELOG"
    (
	echo "$PACKAGE_CHANGELOG_HEAD"
	echo "  * Rebuilt in mk-debuild"
	echo "    - See https://github.com/zultron/dxsbuild"
	echo "$PACKAGE_CHANGELOG_TRAILER"
	echo
    ) > $CHANGELOG

    debug "      Full changelog:"
    run_debug cat $CHANGELOG
    run bash -c "cat $BUILD_SRC_DIR/debian/changelog >> $CHANGELOG"
    run_user cp $CHANGELOG $BUILD_SRC_DIR/debian/changelog
}

debianization_git_tree_unpack() {
    if test -n "${PACKAGE_DEBZN_GIT_URL[$PACKAGE]}"; then
	msg "    Copying debianization from git tree"
	debug "      Debzn git dir: $DEBZN_GIT_DIR"
	debug "      Dest dir: $BUILD_SRC_DIR/debian"
	debug "      Git branch:  ${PACKAGE_DEBZN_GIT_BRANCH[$PACKAGE]}"
	run_user bash -c "'git --git-dir=$DEBZN_GIT_DIR/.git archive \\
	    --prefix=debian/ ${PACKAGE_DEBZN_GIT_BRANCH[$PACKAGE]} | \\
	    tar xCf $BUILD_SRC_DIR -'"
    else
	debug "      (No PACKAGE_DEBZN_GIT_URL defined; not unpacking from git)"
    fi
}

