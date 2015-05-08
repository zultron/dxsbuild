# Defaults
DEBUG=false
DDEBUG=false
IN_SCHROOT=false

# When not IN_DOCKER, don't do anything distro-specific
test -n "$IN_DOCKER" || IN_DOCKER=false


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
    echo -e "$(st)  INFO: $@" >&2
}

debug() {
    if $DEBUG; then
	echo -e "$(st) DEBUG: $@" >&2
    fi
}

ddebug() {
    if $DDEBUG; then
	echo -e "$(st)DDEBUG: $@" >&2
    fi
}

error() {
    local p="$(st) ERROR:"
    echo "$p ************************** ERROR *************************" >&2
    echo "$p $@" >&2
    echo "$p ************************** ERROR *************************" >&2
    wrap_up 1
}

announce() {
    local p="$(st) ************************************************************"
    echo "$p" >&2
    printf "$(st)    $@\n" >&2
    echo "$p" >&2
}

run() {
    (
	debug "Running command as root:"
	! $DEBUG || set -x
	"$@"
    )
}

run_user() {
    (
	debug "Running command as user:"
	! $DEBUG || set -x
	su -c "$*" user
    )
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

uncomma() {
    echo ${*//,/ }
}

foreach_distro() {
    msg="$1"; shift
    for DISTRO in $DISTROS; do
	announce "$DISTRO:  $msg"
	"$@"
    done
}

foreach_distro_arch() {
    msg="$1"; shift
    for DISTRO in $DISTROS; do
	for HOST_ARCH in ${HOST_ARCHES:-$ARCHES}; do
	    if distro_has_arch $DISTRO $HOST_ARCH; then
		announce "$DISTRO:$HOST_ARCH:  $msg"
		"$@"
	    fi
	done
    done
}

modes() {
    test "$MODES" != " " || return 1  # MODES not set:  error
    test -n "$*" || return 0  # no args && MODE != NONE:  success
    # Otherwise, all args must match
    for m in $*; do
    	case "$MODES" in
	    " $m ") : ;;
	    *) return 1 ;;
	esac
    done
    return 0
}


trap 'wrap_up $? from_exit_trap' EXIT
trap 'wrap_up 1 from_trap_err' ERR


# Silence some errors: functions overridden by include scripts when
# applicable
package_version_suffix() { :; }
