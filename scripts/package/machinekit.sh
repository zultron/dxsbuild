PKG="machinekit"

# Disable 'posix', 'rt-preempt', 'xenomai', 'xenomai-kernel' or
# 'rtai-kernel' threads
MACHINEKIT_DISABLED_THREADS=""

# Package sources
PACKAGE_SOURCE_URL[$PKG]="https://github.com/machinekit/machinekit.git"

# Source package configuration
PACKAGE_CONFIGURE_CHROOT_FUNC[$PKG]="configure_machinekit"

# Calculate source configuration pkg deps
declare -A MACHINEKIT_CONFDEPS=( \
    [xenomai-kernel]="xenomai-kernel-source" \
    [rtai-kernel]="rtai-source" )
for i in ${MACHINEKIT_DISABLED_THREADS}; do
    MACHINEKIT_CONFDEPS[$i]=''
done
PACKAGE_CONFIGURE_CHROOT_DEPS[$PKG]+=" ${MACHINEKIT_CONFDEPS[*]}"

# Build params
PACKAGE_NATIVE_BUILD_ONLY[$PKG]="true"		# Cross-compile broken; use qemu

configure_machinekit() {

    # Calculate Tcl/Tk package versions
    case $DISTRO in
	wheezy) TCL_VER=8.5 ;;
	jessie|trusty|rpi8) TCL_VER=8.6 ;;
    esac

    # Calculate Xenomai and RTAI kernel versions
    case "$SBUILD_EXTRA_OPTIONS" in
	# Be sure 'apt-get update' is run
	--no-apt-update) run apt-get update ;;
    esac
    # Base versions
    XENOMAI_HEADER_BASE=$(apt-cache search -n \
	'^linux-headers-[-.0-9]*-xenomai\..*' | \
	awk '{ gsub("linux-headers-","",$1); gsub("\.[^.]*$","",$1); print $1}')
    debug "      Found Xenomai kernel version base '$XENOMAI_HEADER_BASE'"
    RTAI_HEADER_BASE=$(apt-cache search -n \
	'^linux-headers-[-.0-9]*-rtai\..*' | \
	awk '{ gsub("linux-headers-","",$1); gsub("\.[^.]*$","",$1); print $1}')
    debug "      Found RTAI kernel version base '$RTAI_HEADER_BASE'"
    # Architecture extensions
    case $HOST_ARCH in
	amd64|i?86) HEADER_EXT=x86-$HOST_ARCH ;;
	armhf) HEADER_EXT=beaglebone-omap ;;
	*) error "Unknown HOST_ARCH '$HOST_ARCH'" ;;
    esac

    # `debian/configure` command line arguments
    declare -A MACHINEKIT_CONFARGS=( \
	[posix]="-p" \
	[rt-preempt]="-r" \
	[xenomai]="-x" \
	[xenomai-kernel]="-X ${XENOMAI_HEADER_BASE}.x86-amd64 \
	    -X ${XENOMAI_HEADER_BASE}.x86-686-pae" \
	[rtai-kernel]="-R ${RTAI_HEADER_BASE}.x86-amd64 \
	    -R ${RTAI_HEADER_BASE}.x86-686-pae" \
	)
    for t in $MACHINEKIT_DISABLED_THREADS; do
	# Prune disabled thread styles
	MACHINEKIT_CONFARGS[$t]=''
    done
    test "${MACHINEKIT_CONFARGS[xenomai-kernel]}" != "-X .${HEADER_EXT}" || \
	error "Unable to determine Xenomai kernel version"
    test "${MACHINEKIT_CONFARGS[rtai-kernel]}" != "-R .${HEADER_EXT}" || \
	error "Unable to determine RTAI kernel version"

    # Do it (don't use 'run_user' since we're already in the chroot as 'user')
    run debian/configure ${MACHINEKIT_CONFARGS[*]} -t $TCL_VER
}
