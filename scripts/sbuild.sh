debug "    Sourcing sbuild.sh"

sbuild_chroot_init() {
    # By default, only build arch-indep packages on build arch
    if test $HOST_ARCH = $(arch_default $DISTRO) || $FORCE_INDEP; then
	BUILD_INDEP="--arch-all"
    else
	BUILD_INDEP="--no-arch-all"
    fi

    SBUILD_CHROOT=$DISTRO-$(arch_build $DISTRO $HOST_ARCH)-sbuild
    debug "      Sbuild chroot: $SBUILD_CHROOT"
    CHROOT_DIR=$SBUILD_CHROOT_DIR/$DISTRO-$(arch_build $DISTRO $HOST_ARCH)
    debug "      Sbuild chroot dir: $CHROOT_DIR"

    if $BUILD_SCHROOT_SKIP_PACKAGES; then
	debug "      Running in setup-only mode"
	BUILD_SCHROOT_SETUP_ONLY=--setup-only
    fi

    if test -n "$PACKAGE" && test -n "${PACKAGE_SBUILD_RESOLVER[$PACKAGE]}"
    then
	local r=${PACKAGE_SBUILD_RESOLVER[$PACKAGE]}
	debug "      Using sbuild resolver $r"
	SBUILD_RESOLVER_ARG=--build-dep-resolver=$r
    fi

    if test $HOST_ARCH = i386; then
	SCHROOT_PERSONALITY=linux32
    else
	SCHROOT_PERSONALITY=linux
    fi

    if mode BUILD_PACKAGE && ${PACKAGE_QEMU_NOCHECK[$PACKAGE]} \
	&& arch_is_emulated $HOST_ARCH
    then
	debug "      Skipping tests under qemu"
	DEB_BUILD_OPTIONS+=" nocheck"
    fi

    # sbuild verbosity
    if $DEBUG; then
	SBUILD_VERBOSE=--verbose
    fi
    if $DDEBUG; then
	SBUILD_DEBUG=-D
    fi
}

sbuild_install_sbuild_conf() {
    debug "    Installing sbuild.conf into /etc/sbuild/sbuild.conf"
    run cp $SCRIPTS_DIR/sbuild.conf /etc/sbuild
    run sed -i /etc/sbuild/sbuild.conf \
	-e "s/@CODENAME@/${DISTRO_CODENAME[$DISTRO]}/" \
	-e "s/@DISTRO@/$DISTRO/" \
	-e "s/@MAINTAINER@/$MAINTAINER/" \
	-e "s/@EMAIL@/$EMAIL/" \
	-e "s/@PACKAGE_NEW_VERSION_SUFFIX@/$PACKAGE_NEW_VERSION_SUFFIX/" \
	-e "s,@CCACHE_DIR@,$CCACHE_DIR," \
	-e "s,@LOG_DIR@,$BASE_DIR/$LOG_DIR," \
	-e "s/@/\\\\@/g"
    debug "      Contents of /etc/sbuild/sbuild.conf:"
    run_debug grep -v -e '^$' -e '^ *#' /etc/sbuild/sbuild.conf

    debug "    Installing fstab into /etc/schroot/sbuild/fstab"
    run cp $SCRIPTS_DIR/sbuild-fstab /etc/schroot/sbuild/fstab
}

sbuild_install_log_dir() {
    debug "    Creating log directory"
    run_user mkdir -p $LOG_DIR
}

sbuild_install_keys() {
    SBUILD_KEY_DIR=/var/lib/sbuild/apt-keys

    if ! test -f $GNUPGHOME/sbuild-key.sec; then
	debug "    Generating new sbuild keys"
	run sbuild-update --keygen

	debug "    Saving signing keys from sbuild into $GNUPGHOME"
	debug "      Sbuild key dir:  $SBUILD_KEY_DIR"
	run_user mkdir -p $GNUPGHOME; run_user chmod 700 $GNUPGHOME
	run cp $SBUILD_KEY_DIR/sbuild-key.* /tmp
	run chown user /tmp/sbuild-key.*
	run_user cp /tmp/sbuild-key.* $GNUPGHOME
    fi

    if test -f $SBUILD_KEY_DIR/sbuild-key.sec; then
	debug "      (sbuild package keys installed; doing nothing)"
    else
	debug "    Installing signing keys from $GNUPGHOME into sbuild"
	debug "      Sbuild key dir:  $SBUILD_KEY_DIR"
	run install -o user -g sbuild $GNUPGHOME/sbuild-key.* \
	    $SBUILD_KEY_DIR
    fi
    debug "      Sbuild keyring contents:"
    run_debug apt-key --keyring $SBUILD_KEY_DIR/sbuild-key.pub list
}

sbuild_install_config() {
    local BUILD_ARCH=$(arch_build $DISTRO $HOST_ARCH)
    debug "    Installing schroot config:  $DISTRO-$BUILD_ARCH"

    if $SBUILD_USE_AUFS; then
	debug "    Installing aufs on tmpfs config"
	run install -m 755 $SCRIPTS_DIR/schroot-04tmpfs \
	    /etc/schroot/setup.d/04tmpfs
	SCHROOT_UNION_TYPE="aufs"
    else
	SCHROOT_UNION_TYPE="none"
    fi

    run bash -c "sed $SCRIPTS_DIR/schroot.conf \\
	-e 's/@DISTRO@/$DISTRO/g' \\
	-e 's/@BUILD_ARCH@/$BUILD_ARCH/g' \\
	-e 's/@SCHROOT_PERSONALITY@/$SCHROOT_PERSONALITY/g' \\
	-e 's/@SCHROOT_UNION_TYPE@/$SCHROOT_UNION_TYPE/g' \\
	> /etc/schroot/chroot.d/$SBUILD_CHROOT"

    debug "      Contents of /etc/schroot/chroot.d/$SBUILD_CHROOT:"
    run_debug cat /etc/schroot/chroot.d/$SBUILD_CHROOT
}

sbuild_chroot_setup() {
    local BUILD_ARCH=$(arch_build $DISTRO $HOST_ARCH)
    msg "Creating sbuild chroot, distro $DISTRO, arch $BUILD_ARCH"
    sbuild_chroot_init
    sbuild_install_config
    sbuild_install_sbuild_conf
    sbuild_install_keys

    # Clean out any existing apt config and set http proxy
    distro_clear_apt
    distro_set_apt_proxy

    if arch_is_emulated $HOST_ARCH && test $BUILD_ARCH=armhf; then
	debug "    Pre-seeding chroot with qemu-arm-static binary"
	run mkdir -p $CHROOT_DIR/usr/bin
	run cp /usr/bin/qemu-arm-static $CHROOT_DIR/usr/bin
    fi

    debug "    Running sbuild-createchroot"
    run sbuild-createchroot $SBUILD_VERBOSE \
	--components=$(distro_base_components $DISTRO $BUILD_ARCH) \
	--arch=$BUILD_ARCH \
	--include=ccache \
	$BUILD_SCHROOT_SETUP_ONLY \
	${DISTRO_CODENAME[$DISTRO]} $CHROOT_DIR \
	$(distro_base_mirror $DISTRO $BUILD_ARCH)

    # Set up apt configuration
    distro_configure_apt $DISTRO

    # Set up local repo
    deb_repo_init  # Set up variables
    deb_repo_setup
}

sbuild_adjust_log_link() {
    debug "    Adjusting log symlink to relative"
    local LOG_LINK=$(echo \
	$BUILD_DIR/${PACKAGE}_*~1${DISTRO}*_${HOST_ARCH}.build)
    test -h $LOG_LINK || \
	error "Unable to find log link from glob '$LOG_LINK'"
    local LOG=$(readlink $LOG_LINK | sed "s,^/srv/,../../,")
    run_user rm -f $BUILD_DIR/${PACKAGE}_*.build
    run_user ln -sf $LOG $LOG_LINK
}

run_configure_package_chroot_func() {
    sbuild_chroot_init
    sbuild_install_sbuild_conf
    sbuild_install_config
    deb_repo_setup	# repo config

    # FIXME run with union-type=aufs in schroot.conf

    if test -z "${PACKAGE_CONFIGURE_CHROOT_DEPS[$PACKAGE]}"; then
	debug "      (No source pkg configure deps to install)"

    else
	debug "      Installing source package configure deps in schroot:"
	debug "        ${PACKAGE_CONFIGURE_CHROOT_DEPS[$PACKAGE]}"
	run schroot -c $SBUILD_CHROOT $SBUILD_VERBOSE -- \
	    apt-get update
	run schroot -c $SBUILD_CHROOT $SBUILD_VERBOSE -- \
	    apt-get install --no-install-recommends -y \
	    ${PACKAGE_CONFIGURE_CHROOT_DEPS[$PACKAGE]}
    fi

    debug "      Running configure function in schroot"
    run schroot -u user -c $SBUILD_CHROOT $SBUILD_VERBOSE -- \
	./$DXSBUILD -C $(! $DEBUG || echo -d) $DISTRO $PACKAGE

    if test -z "${PACKAGE_CONFIGURE_CHROOT_DEPS[$PACKAGE]}"; then
	debug "      (No source pkg configure deps to remove)"

    else
	debug "      Removing source package configure deps"
	run schroot -c $SBUILD_CHROOT $SBUILD_VERBOSE -- \
	    apt-get purge -y --auto-remove \
	    ${PACKAGE_CONFIGURE_CHROOT_DEPS[$PACKAGE]}
    fi
}

sbuild_build_package() {
    local BUILD_ARCH=$(arch_build $DISTRO $HOST_ARCH)
    local HOST_ARCH=$(arch_host $DISTRO $HOST_ARCH)
    local DSC_FILE=$BUILD_DIR/${PACKAGE}_*.dsc
    debug "      Build arch:  $BUILD_ARCH;  Host arch: $HOST_ARCH"
    debug "      Build dir: $BUILD_DIR"
    debug "      Source package .dsc file: $DSC_FILE"

    test -f $DSC_FILE || error "No .dsc file '$DSC_FILE'"

    sbuild_chroot_init
    sbuild_install_sbuild_conf
    sbuild_install_log_dir
    sbuild_install_keys
    sbuild_install_config

    test -d "$CHROOT_DIR" || error "Absent chroot directory:  $CHROOT_DIR"

    debug "    Running sbuild"
    (
	cd $BUILD_DIR
	run_user bash -c "'DEB_BUILD_OPTIONS=\"$DEB_BUILD_OPTIONS\" sbuild \\
	    --host=$HOST_ARCH --build=$BUILD_ARCH \\
	    -d ${DISTRO_CODENAME[$DISTRO]} $BUILD_INDEP $SBUILD_VERBOSE \\
	    $SBUILD_DEBUG ${PARALLEL_JOBS:+-j $PARALLEL_JOBS} \\
	    -c $SBUILD_CHROOT \\
	    $SBUILD_RESOLVER_ARG \\
	    $DSC_FILE'"
    )

    sbuild_adjust_log_link
}

sbuild_shell() {
    msg "Starting shell in sbuild chroot $SBUILD_CHROOT"

    sbuild_chroot_init
    sbuild_install_sbuild_conf
    sbuild_install_config
    if test $DOCKER_UID = 0; then
	run sbuild-shell $SBUILD_CHROOT
    else
	run_user sbuild-shell $SBUILD_CHROOT
    fi
}

