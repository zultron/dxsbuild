distcc_wanted() {
    if $DISTCC_ENABLE && arch_is_emulated $HOST_ARCH; then
	true
    else
	if test "$1" = -v; then
	    if $DISTCC_ENABLE; then
		debug "      (Not starting distcc:  native architecture)"
	    else
		debug "      (Not starting distcc:  disabled)"
	    fi
	fi
	false
    fi
}

distcc_init() {
    distcc_wanted || return 0

    local HOST_ARCH=$(arch_host $DISTRO $HOST_ARCH)
    # use cross-gcc
    local HOST_MULTIARCH=$(dpkg-architecture \
	-a$HOST_ARCH -qDEB_HOST_MULTIARCH)
    debug "      CC/CXX:  using '${HOST_MULTIARCH}-g{cc,++}'"
    CC="${HOST_MULTIARCH}-gcc"
    CXX="${HOST_MULTIARCH}-g++"
    CCACHE_PREFIX="distcc"
    DISTCC_DIR="$CONFIG_DIR/distcc"
}

distcc_start() {
    distcc_wanted -v || return 0

    debug "    Starting distcc service"
    run mkdir -p $DISTCC_DIR
    run chmod 1777 $DISTCC_DIR
    # run service distcc restart
    run bash -c "distccd --pid-file=$DISTCC_DIR/distccd.pid \\
	--log-file=$DISTCC_DIR/distccd.log --daemon \\
	--allow 127.0.0.1 --listen 127.0.0.1 --nice 10 \\
	--log-level $DISTCC_LOG_LEVEL"
}
