debug "    Sourcing docker.sh"

docker_build() {
    msg "Building Docker container image '$DOCKER_IMAGE' from 'Dockerfile'"
    mkdir -p docker
    set -x
    cp $SCRIPTS_DIR/schroot-04tmpfs docker
    cp Dockerfile docker
    docker build -t $DOCKER_IMAGE docker
    rm -rf docker
}

docker_run() {
    DOCKER_BIND_MOUNTS="-v `pwd`:/srv"
    if test -z "$*"; then
	msg "Starting shell in Docker container '$DOCKER_IMAGE'"
    else
	msg "Running command in Docker container '$DOCKER_IMAGE'"
    fi
    debug "    Docker command:"
    debug "      docker run --privileged -i -t -e IN_DOCKER=true \\"
    debug "        $DOCKER_BIND_MOUNTS \\"
    debug "        $DOCKER_IMAGE $@"
    docker run --privileged -i -t -e IN_DOCKER=true \
	$DOCKER_BIND_MOUNTS \
	$DOCKER_IMAGE "$@"
}

