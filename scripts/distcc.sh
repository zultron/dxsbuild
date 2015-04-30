distcc_init() {
    $DISTCC_ENABLE || return 0

    local HOST_ARCH=$(arch_host $DISTRO $HOST_ARCH)
    if arch_is_emulated $HOST_ARCH; then
	# use cross-gcc
	local HOST_MULTIARCH=$(dpkg-architecture \
	    -a$HOST_ARCH -qDEB_HOST_MULTIARCH)
	debug "      CC/CXX:  using 'distcc ${HOST_MULTIARCH}-g{cc,++}'"
	CC="distcc ${HOST_MULTIARCH}-gcc"
	CXX="distcc ${HOST_MULTIARCH}-g++"
    else
	debug "      CC/CXX:  using 'distcc g{cc,++}'"
	CC="distcc gcc"
	CXX="distcc g++"
    fi
    CCACHE_PREFIX="distcc"
    DISTCC_DIR="$CONFIG_DIR/distcc"
}

distcc_start() {
    $DISTCC_ENABLE || return 0

    debug "    Starting distcc service"
    run mkdir -p $DISTCC_DIR
    run chmod 1777 $DISTCC_DIR
    # run service distcc restart
    run bash -c "distccd --pid-file=$DISTCC_DIR/distccd.pid \\
	--log-file=$DISTCC_DIR/distccd.log --daemon \\
	--allow 127.0.0.1 --listen 127.0.0.1 --nice 10 \\
	--log-level $DISTCC_LOG_LEVEL"
}
