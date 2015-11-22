docker_user() {
    if test $DOCKER_UID = 0; then
	echo root
    else
	echo user
    fi
}

docker_set_user() {
    if ! $IN_DOCKER || $IN_SCHROOT; then
	# Only set up user in Docker container
	return 0
    fi

    if test "$DOCKER_UID" = 0; then
	error "Set user ID on command line or in 'local-config.sh'"
	return 0
    fi

    if test "$(id -u user 2>/dev/null)" = $DOCKER_UID; then
	debug '      (`user` uid already correct)'
    else
	debug "    Setting docker user to $DOCKER_UID"
	run usermod -u $DOCKER_UID user
	debug "      'user' passwd entry:  $(getent passwd user)"
    fi
}

docker_setup() {
    if ! $IN_DOCKER || $IN_SCHROOT; then
	# Only set up in Docker container
	return 0
    fi

    docker_set_user
}

docker_build() {
    msg "Building Docker container image '$DOCKER_IMAGE' from 'Dockerfile'"
    local DOCKER_HTTP_PROXY DOCKER_HTTPS_PROXY
    if test -n "$HTTP_PROXY"; then
	DOCKER_HTTP_PROXY="ENV http_proxy $HTTP_PROXY"
	DOCKER_HTTPS_PROXY="ENV https_proxy $HTTP_PROXY"
    else
	DOCKER_HTTP_PROXY="#ENV http_proxy $HTTP_PROXY"
	DOCKER_HTTPS_PROXY="#ENV https_proxy $HTTP_PROXY"
    fi
    sed $OUTSIDE_SHARE_DIR/Dockerfile \
	-e "/^#ENV\s*http_proxy/ c $DOCKER_HTTP_PROXY" \
	-e "/^#ENV\s*https_proxy/ c $DOCKER_HTTPS_PROXY" | \
	run docker build $DOCKER_NO_CACHE -t $DOCKER_IMAGE -
}

docker_run() {
    DOCKER_BIND_MOUNTS="-v `pwd`:/srv"
    DOCKER_BIND_MOUNTS+=" -v $OUTSIDE_SBUILD_CHROOT_DIR:$SBUILD_CHROOT_DIR"
    DOCKER_BIND_MOUNTS+=" -v $OUTSIDE_REPO_BASE_DIR:$REPO_BASE_DIR"
    if $BUILDBOT_MASTER_ENABLE; then
	DOCKER_PORTS+=" -p 8010:8010"
    fi
    if $DOCKER_ALWAYS_ALLOCATE_TTY || test -z "$*"; then
	msg "Starting interactive shell in Docker container '$DOCKER_IMAGE'"
	DOCKER_TTY=-t
	test -n "$*" || OTHER_ARGS=("bash" "-i")
    fi
    run docker run --privileged -i -e IN_DOCKER=true $DOCKER_TTY --rm=true \
	$DOCKER_BIND_MOUNTS \
	$DOCKER_PORTS \
	$DOCKER_IMAGE "${OTHER_ARGS[@]}"
}

