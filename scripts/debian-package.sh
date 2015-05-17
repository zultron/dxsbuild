. $SCRIPTS_DIR/git-source.sh
. $SCRIPTS_DIR/debian-source-package.sh
. $SCRIPTS_DIR/debian-binary-package.sh

# List of all packages
declare PACKAGES

# Package sources
declare -A PACKAGE_SOURCE_URL
declare -A PACKAGE_SOURCE_GIT_BRANCH
declare -A PACKAGE_SOURCE_GIT_COMMIT
declare -A PACKAGE_SOURCE_GIT_DEPTH
declare -A PACKAGE_DEBZN_GIT_URL
declare -A PACKAGE_DEBZN_GIT_BRANCH
declare -A PACKAGE_COMP
declare -A PACKAGE_FORMAT

# Build params
declare -A PACKAGE_SBUILD_RESOLVER
declare -A PACKAGE_NATIVE_BUILD_ONLY
declare -A PACKAGE_EXCLUDE_ARCHES
declare -A PACKAGE_QEMU_NOCHECK

# Source package configuration
declare -A PACKAGE_CONFIGURE_FUNC
declare -A PACKAGE_CONFIGURE_CHROOT_DEPS
declare -A PACKAGE_CONFIGURE_CHROOT_FUNC

package_distro_suffix() { echo "~1${DISTRO/-/.}"; }
package_version_suffix() {
    test "$1" = -d && local DATE="~$(date +%s)" || local DATE=
    local SUFFIX="$(package_distro_suffix)${PACKAGE_VERSION_SUFFIX}"
    if is_git_source; then
	echo "${DATE}git$(source_git_rev)$SUFFIX"
    else
	echo "$SUFFIX"
    fi
}
package_read_config() {
    local PACKAGE=$1
    PACKAGES+=" $PACKAGE"

    # set up defaults
    PACKAGE_SOURCE_URL[$PACKAGE]=
    PACKAGE_SOURCE_GIT_BRANCH[$PACKAGE]=
    PACKAGE_SOURCE_GIT_COMMIT[$PACKAGE]=
    PACKAGE_SOURCE_GIT_DEPTH[$PACKAGE]="1"
    PACKAGE_DEBZN_GIT_URL[$PACKAGE]=
    PACKAGE_DEBZN_GIT_BRANCH[$PACKAGE]="master"
    PACKAGE_COMP[$PACKAGE]=
    PACKAGE_FORMAT[$PACKAGE]="3.0 (quilt)"
    PACKAGE_SBUILD_RESOLVER[$PACKAGE]=
    PACKAGE_NATIVE_BUILD_ONLY[$PACKAGE]="false"
    PACKAGE_EXCLUDE_ARCHES[$PACKAGE]=
    PACKAGE_QEMU_NOCHECK[$PACKAGE]="false"
    PACKAGE_CONFIGURE_FUNC[$PACKAGE]=
    PACKAGE_CONFIGURE_CHROOT_DEPS[$PACKAGE]=
    PACKAGE_CONFIGURE_CHROOT_FUNC[$PACKAGE]=

    . $PACKAGE_CONFIG_DIR/$PACKAGE.sh

    # Package compression
    if test -z "${PACKAGE_COMP[$PACKAGE]}"; then
	if test -n "${PACKAGE_SOURCE_GIT_BRANCH[$PACKAGE]}"; then
	    PACKAGE_COMP[$PACKAGE]="xz"
	else
	    case "${PACKAGE_SOURCE_URL[$PACKAGE]}" in
		""|*.git|*.xz) PACKAGE_COMP[$PACKAGE]="xz" ;;
		*.bz2) PACKAGE_COMP[$PACKAGE]="bz2" ;;
		*.gz) PACKAGE_COMP[$PACKAGE]="gz" ;;
		*) error "Package $PACKAGE:  Unknown package compression" ;;
	    esac
	fi
    fi

    # Git depth
    if test ${PACKAGE_SOURCE_GIT_DEPTH[$PACKAGE]} = "0"; then
	PACKAGE_SOURCE_GIT_DEPTH[$PACKAGE]=
    else
	local arg="--depth=${PACKAGE_SOURCE_GIT_DEPTH[$PACKAGE]}"
	PACKAGE_SOURCE_GIT_DEPTH[$PACKAGE]="$arg"
    fi
}

package_read_all_configs() {
    debug "    Sourcing package configurations:"
    for config in $PACKAGE_CONFIG_DIR/*.sh; do
	local package=$(basename $config .sh)
	test $package != 'template' || continue  # skip template
	debug "      $package"
	package_read_config $package
    done
}

package_debug() {
    for p in $PACKAGES; do
	debug "package $p:"
	debug "	source url: ${PACKAGE_SOURCE_URL[$p]}"
	debug "	source git branch: ${PACKAGE_SOURCE_GIT_BRANCH[$p]}"
	debug "	source git commit: ${PACKAGE_SOURCE_GIT_COMMIT[$p]}"
	debug "	source git depth: ${PACKAGE_SOURCE_GIT_DEPTH[$p]}"
	debug "	debianization git url: ${PACKAGE_DEBZN_GIT_URL[$p]}"
	debug "	debianization git branch: ${PACKAGE_DEBZN_GIT_BRANCH[$p]}"
	debug "	compression: ${PACKAGE_COMP[$p]}"
	debug "	format: ${PACKAGE_FORMAT[$p]}"
	debug "	sbuild resolver: ${PACKAGE_SBUILD_RESOLVER[$p]}"
	debug "	native build only: ${PACKAGE_NATIVE_BUILD_ONLY[$p]}"
	debug "	excluded architectures: ${PACKAGE_EXCLUDE_ARCHES[$p]}"
	debug "	skip tests in qemu: ${PACKAGE_QEMU_NOCHECK[$p]}"
	debug "	local configuration function: ${PACKAGE_CONFIGURE_FUNC[$p]}"
	debug "	chroot configuration deps: ${PACKAGE_CONFIGURE_CHROOT_DEPS[$p]}"
	debug "	chroot configuration function: " \
	    "${PACKAGE_CONFIGURE_CHROOT_FUNC[$p]}"
    done
}
