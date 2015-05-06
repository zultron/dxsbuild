# debug, log functions
. scripts/utils.sh

trap 'wrap_up $? from_exit_trap' EXIT
trap 'wrap_up 1 from_trap_err' ERR

usage() {
    test -z "$1" || msg "$1"
    msg "Usage:"
    msg "  $0 -i [-N] | -c [-d]"
    msg "     -i:            Build docker image"
    msg "     -N:            Do not use cache when building image"
    msg "     -c:            Spawn interactive shell in docker container"
    msg "  $0 -r [-P] | -L [-d] [-a ARCH] DISTRO"
    msg "     -r:            Create sbuild chroot"
    msg "     -P:            Don't install packages; just configure chroot"
    msg "     -L:            List apt package repository contents"
    msg "  $0 -s [-a ARCH] DISTRO [COMMAND ARGS ...]"
    msg "     -s:            Spawn interactive shell in sbuild chroot"
    msg "                    With COMMAND, execute and exit"
    msg "  $0 -S | -b [-j n] [-O \"opts\"] | -R [-f] [-d] DISTRO PACKAGE"
    msg "     -S:            Build source package"
    msg "     -b:            Run package build (build source pkg if needed)"
    msg "     -R:            Build apt package repository"
    msg "     -f:            Force indep package build when build != host"
    msg "     -j n:          (-b only) Number of parallel jobs"
    msg "     -O \"opt ...\":  (-b only) Set DEB_BUILD_OPTIONS"
    msg "  Global options:"
    msg "     -a ARCH:       Set build arch"
    msg "     -u UID:        Run as user ID UID (default $DOCKER_UID)"
    msg "     -U:            Run as root (UID 0)"
    msg "     -d:            Print verbose debug output"
    msg "     -dd:           Print extra verbose debug output"
    msg "     -o \"opt ...\":  Set extra sbuild options"
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

# Process command line opts
declare -a ARG_LIST  # For saving modified command line opts
MODE=NONE
test -n "$DOCKER_UID" || DOCKER_UID=$(id -u); DOCKER_UID_DEFAULT=true
NEEDED_ARGS=0
MORE_ARGS_OK=false
HOST_ARCH=default  # If no -a arg, gets filled out in architecture.sh
RERUN_IN_DOCKER=true
FORCE_INDEP=false
PARALLEL_JOBS=""
BUILD_SCHROOT_SKIP_PACKAGES=false
while getopts iNcrPsLSbRCfj:O:a:u:Udo: ARG; do
    ARG_LIST+=("-$ARG" ${OPTARG:+"$OPTARG"})
    case $ARG in
	i) MODE=BUILD_DOCKER_IMAGE; RERUN_IN_DOCKER=false ;;
	N) DOCKER_NO_CACHE=--no-cache=true ;;
	c) MODE=DOCKER_SHELL; RERUN_IN_DOCKER=false ;;
	r) MODE=BUILD_SBUILD_CHROOT; NEEDED_ARGS=1 ;;
	P) BUILD_SCHROOT_SKIP_PACKAGES=true ;;
	s) MODE=SBUILD_SHELL; NEEDED_ARGS=1; MORE_ARGS_OK=true ;;
	L) MODE=LIST_APT_REPO; NEEDED_ARGS=1 ;;
	S) MODE=BUILD_SOURCE_PACKAGE; NEEDED_ARGS=2 ;;
	b) MODE=BUILD_PACKAGE; NEEDED_ARGS=2 ;;
	R) MODE=BUILD_APT_REPO; NEEDED_ARGS=2 ;;
	C) MODE=CONFIGURE_PKG; NEEDED_ARGS=2; IN_SCHROOT=true; IN_DOCKER=true ;;
	f) FORCE_INDEP=true ;;
	j) PARALLEL_JOBS="$OPTARG" ;;
	O) DEB_BUILD_OPTIONS+=" $OPTARG" ;;
	a) HOST_ARCH=$OPTARG ;;
	u) DOCKER_UID=$OPTARG; DOCKER_UID_DEFAULT=false ;;
	U) DOCKER_UID=0; DOCKER_UID_DEFAULT=false ;;
	d) ! $DEBUG || DDEBUG=true; DEBUG=true ;;
	o) SBUILD_EXTRA_OPTIONS+=" $OPTARG" ;;
        *) usage
    esac
done
shift $((OPTIND-1))

# User
! $DOCKER_UID_DEFAULT || ARG_LIST+=(-u $DOCKER_UID)

# Save non-option args before mangling
NUM_ARGS=$#
ARG_LIST+=("$@")

# CL args
DISTRO="$1"; shift || true
if mode BUILD_SOURCE_PACKAGE BUILD_PACKAGE BUILD_APT_REPO; then
    PACKAGE="$*"
else
    declare -a OTHER_ARGS=("$@")
fi

# Mode and possible non-flag args must be set
mode && test \
    $NEEDED_ARGS = $NUM_ARGS -o \
    \( $NEEDED_ARGS -le $NUM_ARGS -a $MORE_ARGS_OK = true \) \
    || usage

# Init variables
. scripts/base-config.sh

# Debug info
if ! $IN_DOCKER && ! $IN_SCHROOT; then
    debug "Running '$0 ${ARG_LIST[@]}' at $(date)"
    debug "      Mode: $MODE"
    debug "      ([_] = top level script; [S] = in schroot; [D] = in Docker)"
    debug "      Running with user ID $DOCKER_UID"
fi

# If needed, re-run command in Docker container
if ! $IN_DOCKER && $RERUN_IN_DOCKER; then
    . $SCRIPTS_DIR/docker.sh
    debug "    Re-running command in Docker container"
    if mode DOCKER_SHELL SBUILD_SHELL || $DOCKER_ALWAYS_ALLOCATE_TTY; then
	debug "      Allocating tty in Docker container"
	DOCKER_TTY=-t docker_run $0 "${ARG_LIST[@]}"
    else
	debug "      Not allocating tty in Docker container"
	docker_run $0 "${ARG_LIST[@]}"
    fi
    wrap_up $?
fi

# Check distro name
test $NUM_ARGS -lt 1 -o -f $DISTRO_CONFIG_DIR/${DISTRO:-bogus}.sh || \
    usage "Distro name '$DISTRO' not valid"

# Check package
if mode BUILD_SOURCE_PACKAGE BUILD_PACKAGE BUILD_APT_REPO && \
    ! test -f $PACKAGE_CONFIG_DIR/${PACKAGE:-bogus}.sh
then
    usage "Package '$PACKAGE' not valid"
fi

# Source scripts
ddebug "Sourcing include scripts"
for script in architecture docker sbuild distcc distro \
    debian-package debian-pkg-repo
do
    ddebug "    Sourcing ${script}.sh"
    . $SCRIPTS_DIR/${script}.sh
done

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
