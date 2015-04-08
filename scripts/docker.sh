debug "    Sourcing docker.sh"

docker_build() {
    msg "Building Docker container image '$DOCKER_IMAGE' from 'Dockerfile'"
    mkdir -p docker
    cp $SCRIPTS_DIR/schroot-04tmpfs docker
    cp Dockerfile docker
    run docker build -t $DOCKER_IMAGE docker
    rm -rf docker
}

docker_run() {
    DOCKER_BIND_MOUNTS="-v `pwd`:/srv"
    if test -z "$*"; then
	msg "Starting interactive shell in Docker container '$DOCKER_IMAGE'"
    fi
    run docker run --privileged -i -t -e IN_DOCKER=true \
	$DOCKER_BIND_MOUNTS \
	$DOCKER_IMAGE "$@"
}

