debug "    Sourcing sbuild.sh"

sbuild_chroot_init() {
    # By default, only build arch-indep packages on build arch
    if arch_is_foreign $DISTRO $HOST_ARCH || $FORCE_INDEP; then
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
	-e "s/@/\\\\@/g"
    debug "      Contents of /etc/sbuild/sbuild.conf:"
    run_debug grep -v -e '^$' -e '^ *#' /etc/sbuild/sbuild.conf

    debug "    Installing fstab into /etc/schroot/sbuild/fstab"
    run cp $SCRIPTS_DIR/sbuild-fstab /etc/schroot/sbuild/fstab
}

sbuild_chroot_save_keys() {
    debug "    Saving signing keys from sbuild into $GNUPGHOME"
    debug "      Sbuild key dir:  $SBUILD_KEY_DIR"
    run_user mkdir -p $GNUPGHOME; run_user chmod 700 $GNUPGHOME
    run cp $SBUILD_KEY_DIR/sbuild-key.* /tmp
    run chown user /tmp/sbuild-key.*
    run_user cp /tmp/sbuild-key.* $GNUPGHOME
}

sbuild_install_keys() {
    SBUILD_KEY_DIR=/var/lib/sbuild/apt-keys
    if test -f $SBUILD_KEY_DIR/sbuild-key.sec; then
	if test -f $GNUPGHOME/sbuild-key.sec; then
	    debug "      (sbuild package keys installed; doing nothing)"
	else
	    sbuild_chroot_save_keys
	fi
    else
	if ! test -f $GNUPGHOME/sbuild-key.sec; then
	    debug "    Generating new sbuild keys"
	    run sbuild-update --keygen
	    sbuild_chroot_save_keys
	else
	    debug "    Installing signing keys from $GNUPGHOME into sbuild"
	    debug "      Sbuild key dir:  $SBUILD_KEY_DIR"
	    run install -o user -g sbuild $GNUPGHOME/sbuild-key.* \
		$SBUILD_KEY_DIR
	fi
    fi
    debug "      Sbuild keyring contents:"
    run_debug apt-key --keyring $SBUILD_KEY_DIR/sbuild-key.pub list
}

sbuild_install_config() {
    if test -f $CONFIG_DIR/chroot.d/$SBUILD_CHROOT; then
	debug "    Installing saved schroot config $SBUILD_CHROOT"
	run cp $CONFIG_DIR/chroot.d/$SBUILD_CHROOT /etc/schroot/chroot.d
	debug "      Contents of /etc/schroot/chroot.d/$SBUILD_CHROOT:"
	run_debug cat /etc/schroot/chroot.d/$SBUILD_CHROOT
    else
	debug "      (No saved config for $SBUILD_CHROOT)"
    fi
}

sbuild_save_config() {
    SBUILD_CHROOT=$DISTRO-$SBUILD_CHROOT_ARCH-sbuild
    SBUILD_CHROOT_GEN=$(readlink -e \
	/etc/schroot/chroot.d/${DISTRO_CODENAME[$DISTRO]}-$SBUILD_CHROOT_ARCH-sbuild-* || true)
    if test -n "$SBUILD_CHROOT_GEN"; then
	debug "    Saving generated schroot config from Docker"
	run_user mkdir -p $CONFIG_DIR/chroot.d
	run_user cp $SBUILD_CHROOT_GEN \
	    $CONFIG_DIR/chroot.d/$SBUILD_CHROOT

	if test $DISTRO != ${DISTRO_CODENAME[$DISTRO]}; then
	    debug "    Patching schroot config name"
	    run sed -i $CONFIG_DIR/chroot.d/$SBUILD_CHROOT \
		-e '1 s/.*/[raspbian-jessie-amd64-sbuild]/'
	fi

	debug "      Chroot config:"
	run_debug cat $CONFIG_DIR/chroot.d/$SBUILD_CHROOT

    else
	debug "      (No new schroot config found in /etc/schroot/chroot.d)"
    fi
}

sbuild_chroot_setup() {
    local BUILD_ARCH=$(arch_build $DISTRO $HOST_ARCH)
    msg "Creating sbuild chroot, distro $DISTRO, arch $BUILD_ARCH"
    sbuild_chroot_init
    sbuild_install_config
    sbuild_install_sbuild_conf
    sbuild_install_keys

    # Clean out any existing apt config
    distro_clear_apt

    if arch_is_foreign $DISTRO $HOST_ARCH && test $BUILD_ARCH=armhf; then
	debug "    Pre-seeding chroot with qemu-arm-static binary"
	mkdir -p $CHROOT_DIR/usr/bin
	cp /usr/bin/qemu-arm-static $CHROOT_DIR/usr/bin
    fi

    debug "    Running sbuild-createchroot"
    run sbuild-createchroot $SBUILD_VERBOSE \
	--components=$(distro_base_components $DISTRO $BUILD_ARCH) \
	--arch=$BUILD_ARCH \
	--include=ccache \
	$BUILD_SCHROOT_SETUP_ONLY \
	${DISTRO_CODENAME[$DISTRO]} $CHROOT_DIR \
	$(distro_base_mirror $DISTRO $BUILD_ARCH)

    # Save generated sbuild config from Docker
    sbuild_save_config

    # Set up apt configuration
    distro_configure_apt $DISTRO

    # Set up local repo
    deb_repo_init  # Set up variables
    deb_repo_setup
}

sbuild_configure_package() {
    sbuild_chroot_init
    sbuild_install_sbuild_conf
    sbuild_install_config

    # FIXME run with union-type=aufs in schroot.conf

    debug "      Installing extra packages in schroot:"
    debug "        $CONFIGURE_PACKAGE_DEPS"
    run schroot -c $SBUILD_CHROOT $SBUILD_VERBOSE -- \
	apt-get update
    run schroot -c $SBUILD_CHROOT $SBUILD_VERBOSE -- \
	apt-get install --no-install-recommends -y \
	$CONFIGURE_PACKAGE_DEPS

    debug "      Running configure function in schroot"
    run schroot -u user -c $SBUILD_CHROOT $SBUILD_VERBOSE -- \
	./$DBUILD -C $(! $DEBUG || echo -d) $DISTRO $PACKAGE

    debug "      Uninstalling extra packages"
    run schroot -c $SBUILD_CHROOT $SBUILD_VERBOSE -- \
	apt-get purge -y --auto-remove \
	$CONFIGURE_PACKAGE_DEPS
}

sbuild_build_package() {
    local BUILD_ARCH=$(arch_build $DISTRO $HOST_ARCH)
    debug "      Build dir: $BUILD_DIR"
    debug "      Source package .dsc file: $DSC_FILE"

    test -f $BUILD_DIR/$DSC_FILE || error "No .dsc file '$DSC_FILE'"

    sbuild_chroot_init
    sbuild_install_sbuild_conf
    sbuild_install_keys
    sbuild_install_config

    test -d "$CHROOT_DIR" || error "Absent chroot directory:  $CHROOT_DIR"

    debug "    Running sbuild"
    (
	cd $BUILD_DIR
	run_user sbuild \
	    --host=$HOST_ARCH --build=$BUILD_ARCH \
	    -d ${DISTRO_CODENAME[$DISTRO]} $BUILD_INDEP $SBUILD_VERBOSE \
	    $SBUILD_DEBUG $NUM_JOBS \
	    -c $SBUILD_CHROOT \
	    ${SBUILD_RESOLVER:+--build-dep-resolver=$SBUILD_RESOLVER} \
	    $DSC_FILE
    )
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

