docker_user() {
    if test $DOCKER_UID = 0; then
	echo root
    else
	echo user
    fi
}

docker_set_user() {
    if $DOCKER_UID_DEFAULT && test "$DOCKER_UID" = 0; then
	msg "WARNING:  Running as root user"
	msg "WARNING:  Set user ID on command line or in 'local-config.sh'"
	return
    fi

    debug "    Setting docker user to $DOCKER_UID"
    SBUILD_GID=$(getent group sbuild | awk -F : '{print $3}')
    test -n "$SBUILD_GID" || \
	error "Unable to look up group 'sbuild'"
    debug "      Group 'sbuild' GID = $SBUILD_GID"
    DOCKER_PASSWD_ENTRY="user:*:$DOCKER_UID:$SBUILD_GID:User:/srv:/bin/bash"
    debug "      User ID:  $DOCKER_UID"
    echo "$DOCKER_PASSWD_ENTRY" >> /etc/passwd
    debug "    Adding user $DOCKER_UID to 'sbuild' group"
    sed -i /etc/group -e "/^sbuild:/ s/\$/user/"
    debug "      'user' passwd entry:  $(getent passwd user)"
    debug "      'sbuild' group entry:  $(getent group sbuild)"
}

docker_build() {
    msg "Building Docker container image '$DOCKER_IMAGE' from 'Dockerfile'"
    run bash -c "docker build $DOCKER_NO_CACHE -t $DOCKER_IMAGE - < Dockerfile"
}

docker_run() {
    DOCKER_BIND_MOUNTS="-v `pwd`:/srv"
    if $DOCKER_ALWAYS_ALLOCATE_TTY || test -z "$*"; then
	msg "Starting interactive shell in Docker container '$DOCKER_IMAGE'"
	DOCKER_TTY=-t
    fi
    run docker run --privileged -i -e IN_DOCKER=true $DOCKER_TTY \
	$DOCKER_BIND_MOUNTS \
	$DOCKER_IMAGE "$@"
}

