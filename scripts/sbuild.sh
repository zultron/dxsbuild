debug "    Sourcing sbuild.sh"

sbuild_chroot_init() {
    # By default, only build arch-indep packages on build arch
    BUILD_INDEP="--no-arch-all"
    if dpkg-architecture -e$HOST_ARCH || $FORCE_INDEP; then
	BUILD_INDEP="--arch-all"
    fi

    # Detect foreign architecture
    # FIXME:  This only takes care of amd64-cross-armhf
    if ! dpkg-architecture -earmhf && test $HOST_ARCH = armhf; then
	FOREIGN=true
	debug "      Detected foreign arch:  $BUILD_ARCH != $HOST_ARCH"
    else
	FOREIGN=false
	debug "      Detected non-foreign arch:  $BUILD_ARCH ~= $HOST_ARCH"
    fi

    if mode BUILD_SBUILD_CHROOT SBUILD_SHELL || \
	! $FOREIGN || test -z "$NATIVE_BUILD_ONLY"; then
	SBUILD_CHROOT_ARCH=$HOST_ARCH
	debug "      Using host-arch $SBUILD_CHROOT_ARCH"
    else
	SBUILD_CHROOT_ARCH=$BUILD_ARCH
	debug "      Using build-arch $SBUILD_CHROOT_ARCH"
    fi
    SBUILD_CHROOT=$CODENAME-$SBUILD_CHROOT_ARCH-sbuild
    debug "      Sbuild chroot: $SBUILD_CHROOT"
    CHROOT_DIR=$SBUILD_CHROOT_DIR/$CODENAME-$SBUILD_CHROOT_ARCH
    debug "      Sbuild chroot dir: $CHROOT_DIR"

    # sbuild verbosity
    if $DEBUG; then
	SBUILD_VERBOSE=--verbose
    fi
    if $DDEBUG; then
	SBUILD_DEBUG=-D
    fi
}

sbuild_chroot_save_keys() {
    debug "    Saving signing keys from sbuild into $GNUPGHOME"
    debug "      Sbuild key dir:  $SBUILD_KEY_DIR"
    run_user mkdir -p $GNUPGHOME; run_user chmod 700 $GNUPGHOME
    run cp $SBUILD_KEY_DIR/sbuild-key.* /tmp
    run chown user /tmp/sbuild-key.*
    run_user cp /tmp/sbuild-key.* $GNUPGHOME
}

sbuild_chroot_restore_keys() {
    debug "    Restoring signing keys from $GNUPGHOME into sbuild"
    debug "      Sbuild key dir:  $SBUILD_KEY_DIR"
    run install -o user -g sbuild $GNUPGHOME/sbuild-key.* $SBUILD_KEY_DIR
}

sbuild_chroot_install_keys() {
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
	    sbuild_chroot_restore_keys
	fi
    fi
    debug "      Sbuild keyring contents:"
    run_debug apt-key --keyring $SBUILD_KEY_DIR/sbuild-key.pub list
}

sbuild_restore_config() {
    if test -f $CONFIG_DIR/chroot.d/$SBUILD_CHROOT; then
	debug "    Restoring saved schroot config $SBUILD_CHROOT"
	run cp $CONFIG_DIR/chroot.d/$SBUILD_CHROOT /etc/schroot/chroot.d
	run_debug ls -l /etc/schroot/chroot.d | tail -n +2
    else
	debug "      (No saved config for $SBUILD_CHROOT)"
    fi
}

sbuild_save_config() {
    if test -f /etc/schroot/chroot.d/$SBUILD_CHROOT-*; then
	debug "    Saving generated schroot config from Docker"
	run_user mkdir -p $CONFIG_DIR/chroot.d
	run_user cp /etc/schroot/chroot.d/${SBUILD_CHROOT}-* \
	    $CONFIG_DIR/chroot.d/$SBUILD_CHROOT

	if ! grep -q setup.fstab $CONFIG_DIR/chroot.d/$SBUILD_CHROOT; then
	    debug "    Adding fstab setting to schroot config"
	    run_user sed -i $CONFIG_DIR/chroot.d/$SBUILD_CHROOT \
		-e '"$ a setup.fstab=default/fstab"'
	    run cat $CONFIG_DIR/chroot.d/$SBUILD_CHROOT
	else
	    debug "      (Found fstab setting in schroot config)"
	fi
    else
	debug "      (No new schroot config found in /etc/schroot/chroot.d)"
    fi
}

sbuild_chroot_setup() {
    msg "Creating sbuild chroot, distro $CODENAME, arch $SBUILD_CHROOT_ARCH"
    sbuild_chroot_init

    local MIRROR=$DISTRO_MIRROR
    # If e.g. $DISTRO_MIRROR_armhf defined, use it
    eval local MIRROR_ARCH=\${DISTRO_MIRROR_${HOST_ARCH}}
    test -z "$MIRROR_ARCH" || MIRROR=$MIRROR_ARCH

    COMPONENTS=main${DISTRO_COMPONENTS:+,$DISTRO_COMPONENTS}
    debug "      Components:  $COMPONENTS"
    debug "      Distro mirror:  $MIRROR"

    # If the chroot config already exists, restore it
    sbuild_restore_config
    sbuild_chroot_install_keys

    if $FOREIGN && test $BUILD_ARCH=armhf; then
	debug "    Pre-seeding chroot with qemu-arm-static binary"
	mkdir -p $CHROOT_DIR/usr/bin
	cp /usr/bin/qemu-arm-static $CHROOT_DIR/usr/bin
    fi

    if test -f $CHROOT_DIR/etc/apt/sources.list; then
	debug "    Cleaning old apt sources lists"
	run bash -c "> $CHROOT_DIR/etc/apt/sources.list"
	run rm -f $CHROOT_DIR/etc/apt/sources.list.d/*
    fi

    debug "    Running sbuild-createchroot"
    run sbuild-createchroot $SBUILD_VERBOSE \
    	--components=$COMPONENTS \
    	--arch=$SBUILD_CHROOT_ARCH \
    	$CODENAME $CHROOT_DIR $MIRROR

    # Save generated sbuild config from Docker
    sbuild_save_config

    debug "    Configuring apt sources"
    distro_configure_repos
    # Set up local repo
    deb_repo_init  # Set up variables
    deb_repo_setup
    repo_add_apt_source local file://$BASE_DIR/$REPO_DIR/$CODENAME
}

sbuild_configure_package() {
    sbuild_chroot_init
    sbuild_restore_config

    # FIXME run with union-type=aufs in schroot.conf

    debug "      Installing extra packages in schroot:"
    debug "        $EXTRA_BUILD_PACKAGES"
    run schroot -c $SBUILD_CHROOT $SBUILD_VERBOSE -- \
	apt-get update
    run schroot -c $SBUILD_CHROOT $SBUILD_VERBOSE -- \
	apt-get install --no-install-recommends -y \
	$EXTRA_BUILD_PACKAGES

    debug "      Running configure function in schroot"
    run schroot -u user -c $SBUILD_CHROOT $SBUILD_VERBOSE -- \
	./$DBUILD -C $(! $DEBUG || echo -d) $CODENAME $PACKAGE

    debug "      Uninstalling extra packages"
    run schroot -c $SBUILD_CHROOT $SBUILD_VERBOSE -- \
	apt-get purge -y --auto-remove \
	$EXTRA_BUILD_PACKAGES
}

sbuild_build_package() {
    debug "      Build dir: $BUILD_DIR"
    debug "      Source package .dsc file: $DSC_FILE"

    test -f $BUILD_DIR/$DSC_FILE || error "No .dsc file '$DSC_FILE'"

    sbuild_chroot_init
    sbuild_chroot_install_keys
    sbuild_restore_config

    test -d "$CHROOT_DIR" || error "Absent chroot directory:  $CHROOT_DIR"

    debug "    Running sbuild"
    (
	cd $BUILD_DIR
	run_user sbuild \
	    --host=$HOST_ARCH --build=$SBUILD_CHROOT_ARCH \
	    -d $CODENAME $BUILD_INDEP $SBUILD_VERBOSE $SBUILD_DEBUG $NUM_JOBS \
	    -c $SBUILD_CHROOT \
	    ${SBUILD_RESOLVER:+--build-dep-resolver=$SBUILD_RESOLVER} \
	    $DSC_FILE
    )
}

sbuild_shell() {
    msg "Starting shell in sbuild chroot $SBUILD_CHROOT"

    sbuild_chroot_init
    sbuild_restore_config
    if test $DOCKER_UID = 0; then
	run sbuild-shell $SBUILD_CHROOT
    else
	run_user sbuild-shell $SBUILD_CHROOT
    fi
}

