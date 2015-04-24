is_git_source() {
    if test -n "${PACKAGE_SOURCE_GIT_BRANCH[$PACKAGE]}" -a \
	 -n "${PACKAGE_SOURCE_GIT_COMMIT[$PACKAGE]}"; then
	return 0
    fi

    case "${PACKAGE_SOURCE_URL[$PACKAGE]}" in
	git:*|*.git) return 0 ;;
	*) return 1 ;;
    esac
}

git_rev() {
    local GIT_DIR=$1
    local GIT_BRANCH=${2:-${PACKAGE_DEBZN_GIT_BRANCH[$PACKAGE]:-master}}

    run_user git --git-dir=$GIT_DIR/.git --work-tree=$GIT_DIR \
	rev-parse --short $GIT_BRANCH
}

git_tree_update() {
    local GIT_DIR=$1
    local GIT_URL=$2
    local GIT_BRANCH=$3
    local GIT_COMMIT=$4

    if test ! -d $GIT_DIR/.git; then
	msg "    Cloning new git tree"
	debug "      Git dir: $GIT_DIR"
	debug "      Git URL: $GIT_URL"
	debug "      Git branch:  $GIT_BRANCH"
	debug "      Git commit:  $GIT_COMMIT"
	run_user mkdir -p $GIT_DIR
	run_user git clone -o dxsbuild \
	    ${PACKAGE_SOURCE_GIT_DEPTH[$PACKAGE]} \
	    $GIT_URL $GIT_DIR
    fi

    msg "    Updating git tree"
    debug "      Git dir: $GIT_DIR"
    debug "      Git branch:  $GIT_BRANCH"
    run_user git --git-dir=$GIT_DIR/.git --work-tree=$GIT_DIR \
	fetch dxsbuild
    run_user git --git-dir=$GIT_DIR/.git --work-tree=$GIT_DIR \
	checkout $GIT_BRANCH
    run_user git --git-dir=$GIT_DIR/.git --work-tree=$GIT_DIR \
	reset --hard ${GIT_COMMIT:-dxsbuild/$GIT_BRANCH}
}

git_tree_source_tarball() {
    local GIT_DIR=$1
    local GIT_BRANCH=$2
    local TARBALL=$3
    local COMP_CMD
    case $TARBALL in
	*.gz) COMP_CMD="gzip" ;;
	*.bz2) COMP_CMD="bzip2" ;;
	*.xz) COMP_CMD="xz" ;;
	*) error "Unknown compression $COMP" ;;
    esac

    run_user bash -c "'git --git-dir=$GIT_DIR/.git archive \\
	--prefix=$PACKAGE/ $GIT_BRANCH | \\
	$COMP_CMD > $TARBALL'"
}
