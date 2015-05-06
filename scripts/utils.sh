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

