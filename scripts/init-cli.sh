# Print info messages
st() {
    if $IN_SCHROOT; then
	echo -n '[S]'
    elif $IN_DOCKER; then
	echo -n '[D]'
    else
	echo -n '[_]'
    fi
}

msg() {
    echo -e "$(st)INFO : $@" >&2
}

debug() {
    if $DEBUG; then
	echo -e "$(st)DEBUG: $@" >&2
    fi
}

error() {
    local p="$(st)ERROR:"
    echo "$p ************************** ERROR *************************" >&2
    echo "$p $@" >&2
    echo "$p ************************** ERROR *************************" >&2
    wrap_up 1
}

run() {
    ! $DEBUG || debug "      Command:  $@"
    "$@"
}

run_user() {
    ! $DEBUG || debug "      Command (as 'user'):  $@"
    su -c "$*" user
}

run_debug() {
    "$@" | while read l; do debug "        $l"; done
}

wrap_up() {
    RES=${1:-100}

    if $IN_SCHROOT; then
	debug "    Exiting ($RES) schroot"
    elif $IN_DOCKER; then
	debug "    Exiting ($RES) Docker container"
    else
	debug "Finished with exit status $RES at $(date)"
    fi

    trap - EXIT ERR  # clear traps
    exit $RES
}

trap 'wrap_up $? from_exit_trap' EXIT
trap 'wrap_up 1 from_trap_err' ERR

usage() {
    test -z "$1" || msg "$1"
    msg "Usage:"
    msg "    $0 -i | -c [-d]"
    msg "        -i:		Build docker image"
    msg "        -c:		Spawn interactive shell in docker container"
    msg "    $0 -r [-P] | -s | -L [-d] [-a ARCH] DISTRO"
    msg "        -r:		Create sbuild chroot"
    msg "        -P:		Don't install packages; just configure chroot"
    msg "        -s:		Spawn interactive shell in sbuild chroot"
    msg "        -L:		List apt package repository contents"
    msg "    $0 -S | -b [-j n] | -R [-f] [-d] DISTRO PACKAGE"
    msg "        -S:		Build source package"
    msg "        -b:		Run package build (build source pkg if needed)"
    msg "        -R:		Build apt package repository"
    msg "        -f:		Force indep package build when build != host"
    msg "        -j n:		(-b only) Number of parallel jobs"
    msg "    Global options:"
    msg "        -a ARCH:	Set build arch"
    msg "        -u UID:	Run as user ID UID (default $DOCKER_UID)"
    msg "        -U:		Run as root (UID 0)"
    msg "        -d:		Print verbose debug output"
    msg "        -dd:		Print extra verbose debug output"
    exit 1
}

mode() {
    test $MODE != NONE || return 1  # MODE == NONE:  error
    test -n "$*" || return 0  # no args && MODE != NONE:  success
    for m in $*; do
	test $MODE != $m || return 0  # MODE == cmdline arg:  success
    done
    return 1  # MODE != cmdline arg:  error
}

# When not IN_DOCKER, don't do anything distro-specific
test -n "$IN_DOCKER" || IN_DOCKER=false

# Process command line opts
MODE=NONE
test -n "$DOCKER_UID" || DOCKER_UID=$(id -u); DOCKER_UID_DEFAULT=true
DEBUG=false
DDEBUG=false
NEEDED_ARGS=0
ARG_LIST=""
HOST_ARCH=default  # If no -a arg, gets filled out in architecture.sh
RERUN_IN_DOCKER=true
IN_SCHROOT=false
FORCE_INDEP=false
PARALLEL_JOBS=""
BUILD_SCHROOT_SKIP_PACKAGES=false
while getopts icrPsLSbRCfj:a:u:Ud ARG; do
    ARG_LIST+=" -${ARG}${OPTARG:+ $OPTARG}"
    case $ARG in
	i) MODE=BUILD_DOCKER_IMAGE; RERUN_IN_DOCKER=false ;;
	c) MODE=DOCKER_SHELL; RERUN_IN_DOCKER=false ;;
	r) MODE=BUILD_SBUILD_CHROOT; NEEDED_ARGS=1 ;;
	P) BUILD_SCHROOT_SKIP_PACKAGES=true ;;
	s) MODE=SBUILD_SHELL; NEEDED_ARGS=1 ;;
	L) MODE=LIST_APT_REPO; NEEDED_ARGS=1 ;;
	S) MODE=BUILD_SOURCE_PACKAGE; NEEDED_ARGS=2 ;;
	b) MODE=BUILD_PACKAGE; NEEDED_ARGS=2 ;;
	R) MODE=BUILD_APT_REPO; NEEDED_ARGS=2 ;;
	C) MODE=CONFIGURE_PKG; NEEDED_ARGS=2; IN_SCHROOT=true; IN_DOCKER=true ;;
	f) FORCE_INDEP=true ;;
	j) PARALLEL_JOBS="$OPTARG" ;;
	a) HOST_ARCH=$OPTARG ;;
	u) DOCKER_UID=$OPTARG; DOCKER_UID_DEFAULT=false ;;
	U) DOCKER_UID=0; DOCKER_UID_DEFAULT=false ;;
	d) ! $DEBUG || DDEBUG=true; DEBUG=true ;;
        *) usage
    esac
done
shift $((OPTIND-1))

# User
! $DOCKER_UID_DEFAULT || ARG_LIST+=" -u $DOCKER_UID"

# Save non-option args before mangling
NUM_ARGS=$#
ARG_LIST+=" $*"

# CL args
DISTRO="$1"; shift || true
PACKAGE="$*"

# Mode and possible non-flag args must be set
mode && test $NEEDED_ARGS = $NUM_ARGS || usage

# Init variables
. scripts/base-config.sh

# Debug info
if ! $IN_DOCKER && ! $IN_SCHROOT; then
    debug "Running '$0 $ARG_LIST' at $(date)"
    debug "      Mode: $MODE"
    debug "      ([_] = top level script; [S] = in schroot; [D] = in Docker)"
    debug "      Running with user ID $DOCKER_UID"
fi

# If needed, re-run command in Docker container
if ! $IN_DOCKER && $RERUN_IN_DOCKER; then
    . $SCRIPTS_DIR/docker.sh
    debug "    Re-running command in Docker container"
    if mode DOCKER_SHELL SBUILD_SHELL; then
	debug "      Allocating tty in Docker container"
	DOCKER_TTY=-t docker_run $0 $ARG_LIST
    else
	debug "      Not allocating tty in Docker container"
	docker_run $0 $ARG_LIST
    fi
    wrap_up $?
fi

# Check distro name
test $NUM_ARGS -lt 1 -o -f $DISTRO_CONFIG_DIR/${DISTRO:-bogus}.sh || \
    usage "Distro name '$DISTRO' not valid"

# Check package
test $NUM_ARGS -lt 2 -o -f $PACKAGE_CONFIG_DIR/${PACKAGE:-bogus}.sh || \
    usage "Package '$PACKAGE' not valid"

# Set variables
DOCKER_CONTAINER=$DISTRO-$PACKAGE

# Source scripts
debug "Sourcing include scripts"
. $SCRIPTS_DIR/architecture.sh
. $SCRIPTS_DIR/docker.sh
. $SCRIPTS_DIR/sbuild.sh
. $SCRIPTS_DIR/distro.sh
. $SCRIPTS_DIR/debian-package.sh
. $SCRIPTS_DIR/debian-pkg-repo.sh

# Source distro, repo and package configs
distro_read_all_configs
repo_read_all_configs
package_read_all_configs

# Source optional config override file
if test -f $BASE_DIR/local-config.sh; then
    debug "    Sourcing local config"
    . $BASE_DIR/local-config.sh
fi

# Print config debug info
# distro_debug
# package_debug
# exit 1

# Debug
! $DDEBUG || set -x

# Set up user in Docker
if $IN_DOCKER && ! $IN_SCHROOT; then
    docker_set_user
fi
