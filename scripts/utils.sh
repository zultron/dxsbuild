# Defaults
DEBUG=${DEBUG:-false}
DDEBUG=${DDEBUG:-false}
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
	template_add_sub DISTRO
	HOST_ARCH=$(arch_default $DISTRO) # Use default arch
	template_add_sub HOST_ARCH
	test -z "$msg" || announce "$DISTRO:  $msg"
	"$@"
    done
}

foreach_distro_arch() {
    msg="$1"; shift
    for DISTRO in $DISTROS; do
	template_add_sub DISTRO
	for HOST_ARCH in ${HOST_ARCHES:-$ARCHES}; do
	    template_add_sub HOST_ARCH
	    if distro_has_arch $DISTRO $HOST_ARCH; then
		test -z "$msg" || announce "$DISTRO:$HOST_ARCH:  $msg"
		"$@"
	    fi
	done
    done
}

foreach_arch() {
    msg="$1"; shift
    for HOST_ARCH in ${HOST_ARCHES:-$ARCHES}; do
	template_add_sub HOST_ARCH
	if distro_has_arch $DISTRO $HOST_ARCH; then
	    test -z "$msg" || announce "$DISTRO:$HOST_ARCH:  $msg"
	    "$@"
	fi
    done
}

modes() {
    test "$MODES" != " " || return 1  # MODES not set:  error
    test -n "$*" || return 0  # no args && MODE != NONE:  success
    # Otherwise, all args must match
    for m in $*; do
    	case "$MODES" in
	    *" $m "*) : ;;
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


##########################
# Template substitutions

declare -A TEMPLATE_SUBSTITUTIONS

template_add_sub() {
    local KEY="$1"
    local VAL="${2:-$(eval echo \$$KEY)}"
    echo "adding template sub '$KEY'='$VAL'"
    TEMPLATE_SUBSTITUTIONS[$KEY]="$VAL"
}

render_template() {
    if test "$1" = -s; then
	shift; echo "$@" | render_template
    elif test "$1" = -f; then
	shift; cat "$@" | render_template
    else
	local -a SED_ARGS
	local var
	for var in "${!TEMPLATE_SUBSTITUTIONS[@]}"; do
	    SED_ARGS+=(-e "s,@${var}@,${TEMPLATE_SUBSTITUTIONS[${var}]},")
	done
	sed \
	    "${SED_ARGS[@]}"
    fi
}
