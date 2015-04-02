# Print info messages
msg() {
    echo -e "INFO:	$@" >&2
}

debug() {
    if $DEBUG; then
	echo -e "DEBUG:	$@" >&2
    fi
}

error() {
    echo -e "ERROR:	$@" >&2
    exit 1
}

usage() {
    test -z "$1" || msg "$1"
    msg "Usage:"
    msg "    $0 -i | -c [-d]"
    msg "        -i:		Build docker image"
    msg "        -c:		Spawn interactive shell in docker container"
    msg "    $0 -r | -s | -L [-d] [-a ARCH] CODENAME"
    msg "        -r:		Create sbuild chroot"
    msg "        -s:		Spawn interactive shell in sbuild chroot"
    msg "        -L:		List apt package repository contents"
    msg "    $0 -S | -b | -R [-f] [-d] CODENAME PACKAGE"
    msg "        -S:		Build source package"
    msg "        -b:		Run package build (build source pkg if needed)"
    msg "        -R:		Build apt package repository"
    msg "        -f:		Force indep package build when build != host"
    msg "    Global options:"
    msg "        -a ARCH:	Set build arch"
    msg "        -d:	Print verbose debug output"
    msg "        -dd:	Print extra verbose debug output"
    exit 1
}

mode() {
    test $MODE = "$1" -o \( -z "$1" -a $MODE != NONE \) || return 1
    return 0
}

# Process command line opts
MODE=NONE
DOCKER_SUPERUSER="-u `id -u`"
DEBUG=false
DDEBUG=false
NEEDED_ARGS=0
ARG_LIST=""
BUILD_ARCH=$(dpkg-architecture -qDEB_BUILD_ARCH)
FORCE_INDEP=false
while getopts icrsLSbRfa:d ARG; do
    ARG_LIST+=" -${ARG}${OPTARG:+ $OPTARG}"
    case $ARG in
	i) MODE=BUILD_DOCKER_IMAGE ;;
	c) MODE=DOCKER_SHELL ;;
	r) MODE=BUILD_SBUILD_CHROOT; NEEDED_ARGS=1 ;;
	s) MODE=SBUILD_SHELL; NEEDED_ARGS=1 ;;
	L) MODE=LIST_APT_REPO; NEEDED_ARGS=1 ;;
	S) MODE=BUILD_SOURCE_PACKAGE; NEEDED_ARGS=2 ;;
	b) MODE=BUILD_PACKAGE; NEEDED_ARGS=2 ;;
	R) MODE=BUILD_APT_REPO; NEEDED_ARGS=2 ;;
	f) FORCE_INDEP=true ;;
	a) BUILD_ARCH=$OPTARG ;;
	d) ! $DEBUG || DDEBUG=true; DEBUG=true ;;
        *) usage
    esac
done
shift $((OPTIND-1))

# Save arg state before mangling
NUM_ARGS=$#
ARG_LIST+=" $*"

# CL args
CODENAME="$1"; shift || true
PACKAGE="$*"

# Mode and possible non-flag args must be set
mode && test $NEEDED_ARGS = $NUM_ARGS || usage

# Init variables
. scripts/base-config.sh

# Check codename
test $NUM_ARGS -lt 1 -o -f $DISTRO_CONFIG_DIR/${CODENAME:-bogus}.sh || \
    usage "Codename '$CODENAME' not valid"

# Check package
test $NUM_ARGS -lt 2 -o -f $PACKAGE_CONFIG_DIR/${PACKAGE:-bogus}.sh || \
    usage "Package '$PACKAGE' not valid"

# Set variables
DOCKER_CONTAINER=$CODENAME-$PACKAGE
test -n "$IN_DOCKER" || IN_DOCKER=false

# Debug info
debug "Mode: $MODE"

# Source configs
if test -n "$CODENAME"; then
    . $DISTRO_CONFIG_DIR/$CODENAME.sh
fi
if test -n "$PACKAGE"; then
. $PACKAGE_CONFIG_DIR/$PACKAGE.sh
fi

# Source scripts
debug "Sourcing include scripts:"
. $SCRIPTS_DIR/docker.sh
. $SCRIPTS_DIR/sbuild.sh
. $SCRIPTS_DIR/distro.sh
. $SCRIPTS_DIR/debian-source-package.sh
. $SCRIPTS_DIR/debian-binary-package.sh
. $SCRIPTS_DIR/debian-pkg-repo.sh


# Debug
! $DDEBUG || set -x


# Sanity checks

# Be sure package is valid for distro
PACKAGES=" $PACKAGES "
if test $NUM_ARGS -gt 2 -a "$PACKAGES" = "${PACKAGES/ $PACKAGE /}"; then
    echo "Package '$PACKAGE' not valid for codename '$CODENAME'" >&2
    exit 1
fi

