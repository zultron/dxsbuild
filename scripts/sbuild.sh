debug "    Sourcing sbuild.sh"

sbuild_chroot_init() {
    # By default, only build arch-indep packages on build arch
    BUILD_INDEP="--no-arch-all"
    if dpkg-architecture -e$HOST_ARCH || $FORCE_INDEP; then
	BUILD_INDEP="--arch-all"
    fi

    # Detect foreign architecture
    # FIXME:  This only takes care of amd64-cross-armhf
    FOREIGN=false
    if ! dpkg-architecture -earmhf && test $HOST_ARCH = armhf; then
	FOREIGN=true
	debug "      Detected foreign arch:  $BUILD_ARCH != $HOST_ARCH"
    fi

    if mode BUILD_SBUILD_CHROOT SBUILD_SHELL || \
	test -n "$NATIVE_BUILD_ONLY"; then
	SBUILD_CHROOT_ARCH=$HOST_ARCH
    else
	SBUILD_CHROOT_ARCH=$BUILD_ARCH
    fi
    debug "      Sbuild chroot arch: $SBUILD_CHROOT_ARCH"
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

sbuild_chroot_install_keys() {
    SBUILD_KEY_DIR=/var/lib/sbuild/apt-keys
    if test -f $SBUILD_KEY_DIR/sbuild-key.sec; then
	if test -f $GNUPGHOME/sbuild-key.sec; then
	    debug "      (sbuild package keys installed; doing nothing)"
	else
	    debug "    Saving signing keys from sbuild into $GNUPGHOME"
	    debug "      Sbuild key dir:  $SBUILD_KEY_DIR"
	    mkdir -p $GNUPGHOME; chmod 700 $GNUPGHOME
	    run cp $SBUILD_KEY_DIR/sbuild-key.* $GNUPGHOME
	fi
    else
	if ! test -f $GNUPGHOME/sbuild-key.sec; then
	    debug "    Generating new sbuild keys"
	    run sbuild-update --keygen
	    debug "    Saving signing keys from sbuild into $GNUPGHOME"
	    debug "      Sbuild key dir:  $SBUILD_KEY_DIR"
	    mkdir -p $GNUPGHOME; chmod 700 $GNUPGHOME
	    run cp $SBUILD_KEY_DIR/sbuild-key.* $GNUPGHOME
	else
	    debug "    Copying signing keys from $GNUPGHOME into sbuild"
	    debug "      Sbuild key dir:  $SBUILD_KEY_DIR"
	    run cp $GNUPGHOME/sbuild-key.* $SBUILD_KEY_DIR
	fi
    fi
    debug "      Sbuild keyring contents:"
    apt-key --keyring $SBUILD_KEY_DIR/sbuild-key.pub list | \
	while read line; do
	    debug "        $line"
    done
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
    mkdir -p $CONFIG_DIR/chroot.d
    if $FOREIGN && test $BUILD_ARCH=armhf; then
	debug "    Pre-seeding chroot with qemu-arm-static binary"
	mkdir -p $CHROOT_DIR/usr/bin
	cp /usr/bin/qemu-arm-static $CHROOT_DIR/usr/bin
    fi
    debug "    Running sbuild-createchroot"
    run sbuild-createchroot $SBUILD_VERBOSE \
    	--components=$COMPONENTS \
    	--arch=$SBUILD_CHROOT_ARCH \
    	$CODENAME $CHROOT_DIR $MIRROR

    debug "    Updating config files"
    test -f $CONFIG_DIR/chroot.d/$SBUILD_CHROOT || \
	mv $CONFIG_DIR/chroot.d/${SBUILD_CHROOT}-* \
	$CONFIG_DIR/chroot.d/$SBUILD_CHROOT
    debug "    Updating chroot fstab"
    grep -q setup.fstab $CONFIG_DIR/chroot.d/$SBUILD_CHROOT || \
	echo setup.fstab=default/fstab >> $CONFIG_DIR/chroot.d/$SBUILD_CHROOT

    # Add local sbuild chroot users
    # FIXME
    #sbuild-adduser 1000

    debug "    Configuring apt sources"
    > $CHROOT_DIR/etc/apt/sources.list
    distro_configure_repos
    # Set up local repo
    deb_repo_init  # Set up variables
    deb_repo_setup
    repo_add_apt_source local file://$BASE_DIR/$REPO_DIR/$CODENAME
}

sbuild_configure_package() {
    sbuild_chroot_init

    # FIXME run with union-type=aufs in schroot.conf

    debug "      Installing extra packages in schroot:"
    debug "        $EXTRA_BUILD_PACKAGES"
    run schroot -c $CODENAME-$SBUILD_CHROOT_ARCH-sbuild $SBUILD_VERBOSE -- \
	apt-get update
    run schroot -c $CODENAME-$SBUILD_CHROOT_ARCH-sbuild $SBUILD_VERBOSE -- \
	apt-get install --no-install-recommends -y \
	$EXTRA_BUILD_PACKAGES

    debug "      Running configure function in schroot"
    run schroot -c $CODENAME-$SBUILD_CHROOT_ARCH-sbuild $SBUILD_VERBOSE -- \
	./$DBUILD -C $(! $DEBUG || echo -d) $CODENAME $PACKAGE

    debug "      Uninstalling extra packages"
    run schroot -c $CODENAME-$SBUILD_CHROOT_ARCH-sbuild $SBUILD_VERBOSE -- \
	apt-get purge -y --auto-remove \
	$EXTRA_BUILD_PACKAGES
}

sbuild_build_package() {
    debug "      Build dir: $BUILD_DIR"
    debug "      Source package .dsc file: $DSC_FILE"

    test -f $BUILD_DIR/$DSC_FILE || error "No .dsc file '$DSC_FILE'"

    sbuild_chroot_init
    sbuild_chroot_install_keys

    debug "    Running sbuild"
    (
	cd $BUILD_DIR
	run sbuild \
	    --host=$HOST_ARCH --build=$SBUILD_CHROOT_ARCH \
	    -d $CODENAME $BUILD_INDEP $SBUILD_VERBOSE $SBUILD_DEBUG $NUM_JOBS \
	    -c $CODENAME-$SBUILD_CHROOT_ARCH-sbuild \
	    ${SBUILD_RESOLVER:+--build-dep-resolver=$SBUILD_RESOLVER} \
	    $DSC_FILE
    )
}

sbuild_shell() {
    msg "Starting shell in sbuild chroot $SBUILD_CHROOT"

    sbuild_chroot_init
    run sbuild-shell $SBUILD_CHROOT
}

