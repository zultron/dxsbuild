debug "    Sourcing sbuild.sh"

sbuild_chroot_init() {
    # By default, only build arch-indep packages on build arch
    BUILD_INDEP="--no-arch-all"
    if dpkg-architecture -e$BUILD_ARCH || $FORCE_INDEP; then
	BUILD_INDEP="--arch-all"
    fi

    # sbuild-chroot:  use the build-arch chroot by default
    SBUILD_CHROOT_ARCH=$(dpkg-architecture -qDEB_BUILD_ARCH)
    if dpkg-architecture -eamd64 && test $BUILD_ARCH = i386; then
	# ...but amd64-cross-i586 needs its own sbuild chroot
	SBUILD_CHROOT_ARCH=i386
    fi
    debug "      Sbuild chroot arch: $SBUILD_CHROOT_ARCH"
    SBUILD_CHROOT=$CODENAME-$SBUILD_CHROOT_ARCH-sbuild
    debug "      Sbuild chroot: $SBUILD_CHROOT"
    CHROOT_DIR=$SBUILD_CHROOT_DIR/$CODENAME-$SBUILD_CHROOT_ARCH
    debug "      Sbuild chroot dir: $CHROOT_DIR"

    # Extra debugging for sbuild
    if $DDEBUG; then
	SBUILD_DEBUG=-D
    fi
}

sbuild_chroot_setup() {
    msg "Creating sbuild chroot, distro $CODENAME, arch $HOST_ARCH"
    sbuild_chroot_init

    COMPONENTS=main${DISTRO_COMPONENTS:+,$DISTRO_COMPONENTS}
    debug "      Components:  $COMPONENTS"
    debug "      Distro mirror:  $DISTRO_MIRROR"
    sbuild-createchroot \
	--components=$COMPONENTS \
	--arch=$SBUILD_CHROOT_ARCH \
	$CODENAME $CHROOT_DIR $DISTRO_MIRROR

    # Fix config file name and add options
    mv $CONFIG_DIR/chroot.d/${SBUILD_CHROOT}-* \
	$CONFIG_DIR/chroot.d/$SBUILD_CHROOT
    echo setup.fstab=default/fstab >> $CONFIG_DIR/chroot.d/$SBUILD_CHROOT

    # Add local sbuild chroot users
    # FIXME
    #sbuild-adduser 1000

    # Remove default apt sources and configure new
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
    schroot -c $CODENAME-$SBUILD_CHROOT_ARCH-sbuild -- \
	apt-get update
    schroot -c $CODENAME-$SBUILD_CHROOT_ARCH-sbuild -- \
	apt-get install --no-install-recommends -y \
	$EXTRA_BUILD_PACKAGES

    debug "      Running configure function in schroot"
    schroot -c $CODENAME-$SBUILD_CHROOT_ARCH-sbuild -- \
	./build.sh -C $CODENAME $PACKAGE

    debug "      Uninstalling extra packages"
    schroot -c $CODENAME-$SBUILD_CHROOT_ARCH-sbuild -- \
	apt-get purge -y --auto-remove \
	$EXTRA_BUILD_PACKAGES
}

sbuild_build_package() {
    debug "      Build dir: $BUILD_DIR"
    debug "      Source package .dsc file: $DSC_FILE"

    sbuild_chroot_init

    (
	cd $BUILD_DIR
	sbuild \
	    --host=$BUILD_ARCH --build=$SBUILD_CHROOT_ARCH \
	    -d $CODENAME $BUILD_INDEP $SBUILD_DEBUG \
	    -c $CODENAME-$SBUILD_CHROOT_ARCH-sbuild \
	    $DSC_FILE
    )
}

sbuild_shell() {
    msg "Starting shell in sbuild chroot $SBUILD_CHROOT"

    sbuild_chroot_init
    sbuild-shell $SBUILD_CHROOT
}

