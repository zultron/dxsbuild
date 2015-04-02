########################################
# Debianization git tree operations
debug "    Sourcing debian-debzn.sh"

debianization_git_tree_update() {
    if test -z "$GIT_URL"; then
	debug "    (No GIT_URL defined; not handling debianization git tree)"
	return
    fi

    if test ! -d $DEBZN_GIT_DIR/.git; then
	msg "    Cloning new debianization git tree"
	debug "      Source: $GIT_URL"
	debug "      Dir: $DEBZN_GIT_DIR"
	git clone --depth=1 $GIT_URL $DEBZN_GIT_DIR
    else
	msg "    Updating debianization git tree"
	debug "      Dir: $DEBZN_GIT_DIR"
	git --git-dir=$DEBZN_GIT_DIR/.git --work-tree=$DEBZN_GIT_DIR \
	    pull --ff-only
    fi
}

debianization_git_tree_unpack() {
    if test -n "$GIT_URL"; then
	msg "    Copying debianization from git tree"
	debug "      Debzn git dir: $DEBZN_GIT_DIR"
	debug "      Dest dir: $BUILD_DIR/debian"
	mkdir -p $BUILD_DIR/debian
	git --git-dir=$DEBZN_GIT_DIR/.git archive --prefix=./ HEAD | \
	    tar xCf $BUILD_DIR/debian -
    else
	debug "    (No GIT_URL defined; not unpacking debianization from git)"
    fi
}

