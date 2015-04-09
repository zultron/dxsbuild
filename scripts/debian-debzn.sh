########################################
# Debianization git tree operations
debug "    Sourcing debian-debzn.sh"

parse_changelog() {
    dpkg-parsechangelog --file $BUILD_DIR/changelog.orig --show-field $1
}

debianization_init() {
    test -z "$PACKAGE_VERSION" || return

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
    PACKAGE_NEW_VERSION_SUFFIX="~1${CODENAME}${PACKAGE_VERSION_SUFFIX}"
    PACKAGE_NEW_VERSION="${PACKAGE_VERSION}${PACKAGE_NEW_VERSION_SUFFIX}"
    debug "      New package version-release:  $PACKAGE_NEW_VERSION"
    DSC_FILE=${PACKAGE}_${PACKAGE_NEW_VERSION}.dsc
    debug "      .dsc file name:  $DSC_FILE"
    CHANGELOG=/tmp/changelog-$PACKAGE-$CODENAME

    if test -z "$MAINTAINER"; then
	MAINTAINER="$(git config user.name)" || MAINTAINER="mk-dbuild user"
    fi
    if test -z "$EMAIL"; then
	EMAIL="$(git config user.email)" || EMAIL="mk-dbuild@example.com"
    fi
    debug "      Maintainer <email>:  $MAINTAINER <$EMAIL>"
}

debianization_git_tree_update() {
    if test -z "$GIT_URL"; then
	debug "    (No GIT_URL defined; not handling debianization git tree)"
	return
    fi

    if test ! -d $DEBZN_GIT_DIR/.git; then
	msg "    Cloning new debianization git tree"
	debug "      Source: $GIT_URL"
	debug "      Dir: $DEBZN_GIT_DIR"
	debug "      Git branch:  ${GIT_BRANCH:-master}"
	run_user git clone -o dbuild -b ${GIT_BRANCH:-master} --depth=1 \
	    $GIT_URL $DEBZN_GIT_DIR
    else
	msg "    Updating debianization git tree"
	debug "      Dir: $DEBZN_GIT_DIR"
	debug "      Git branch:  ${GIT_BRANCH:-master}"
	run_user git --git-dir=$DEBZN_GIT_DIR/.git --work-tree=$DEBZN_GIT_DIR \
	    pull --ff-only dbuild ${GIT_BRANCH:-master}
    fi

    debug "    Saving original changelog"
    run_user cp $DEBZN_GIT_DIR/changelog $BUILD_DIR/changelog.orig
}

debianization_add_changelog() {
    # https://www.debian.org/doc/debian-policy/ch-source.html#s-dpkgchangelog
    msg "    Adding new changelog entry"

    # Calculate first line of changelog entry
    PACKAGE_CHANGELOG_HEAD="$(echo "${PACKAGE}" "(${PACKAGE_NEW_VERSION})" \
	"${PACKAGE_DISTRIBUTION};" "urgency=${PACKAGE_URGENCY}")"

    # Calculate trailer line of changelog entry
    PACKAGE_CHANGELOG_TRAILER=" -- $MAINTAINER <$EMAIL>  $(date -R)"

    # Write changelog entry
    (
	echo "$PACKAGE_CHANGELOG_HEAD"
	echo "  * Rebuilt in mk-debuild"
	echo "    - See https://github.com/zultron/mk-dbuild"
	echo "$PACKAGE_CHANGELOG_TRAILER"
	echo
    ) > $CHANGELOG

    debug "      Full changelog:"
    run_debug cat $CHANGELOG
    run bash -c "cat $BUILD_DIR/changelog.orig >> $CHANGELOG"
    run_user cp $CHANGELOG $BUILD_SRC_DIR/debian/changelog
}

debianization_git_tree_unpack() {
    if test -n "$GIT_URL"; then
	msg "    Copying debianization from git tree"
	debug "      Debzn git dir: $DEBZN_GIT_DIR"
	debug "      Dest dir: $BUILD_SRC_DIR/debian"
	debug "      Git branch:  ${GIT_BRANCH:-master}"
	run_user git --git-dir=$DEBZN_GIT_DIR/.git archive \
	    --prefix=debian/ ${GIT_BRANCH:-master} | \
	    run_user tar xCf $BUILD_SRC_DIR -
    else
	debug "      (No GIT_URL defined; not unpacking debianization from git)"
    fi
}

