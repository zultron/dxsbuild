debug "    Sourcing distro.sh"

# Distros
declare DISTROS
declare -A DISTRO_PACKAGES
declare -A DISTRO_ARCHES
declare -A DISTRO_REPOS
declare -A DISTRO_CODENAME
for arch in $ARCHES; do
    eval "declare -A DISTRO_ARCHES_$arch"
done

# Repos
declare REPOS
declare -A REPO_MIRROR
declare -A REPO_ARCHES
declare -A REPO_KEY
declare -A REPO_COMPONENTS
declare -A REPO_IS_BASE

distro_read_config() {
    local DISTRO=$1
    DISTROS+=" $DISTRO"

    # set up defaults
    DISTRO_PACKAGES[$DISTRO]=
    DISTRO_ARCHES[$DISTRO]="$ARCHES"
    DISTRO_REPOS[$DISTRO]=
    DISTRO_CODENAME[$DISTRO]=$DISTRO

    . $DISTRO_CONFIG_DIR/$DISTRO.sh
}

distro_read_all_configs() {
    debug "    Sourcing distro configurations:"
    for config in $DISTRO_CONFIG_DIR/*.sh; do
	local distro=$(basename $config .sh)
	debug "      $distro"
	distro_read_config $distro
    done
}

repo_read_config() {
    local REPO=$1
    REPOS+=" $REPO"

    # set up defaults
    REPO_MIRROR[$REPO]=
    REPO_ARCHES[$REPO]="$ARCHES"
    REPO_KEY[$REPO]=
    REPO_COMPONENTS[$REPO]="main"
    REPO_IS_BASE[$REPO]="false"

    . $REPO_CONFIG_DIR/$REPO.sh
}

repo_read_all_configs() {
    debug "    Sourcing repo configurations:"
    for config in $REPO_CONFIG_DIR/*.sh; do
	local repo=$(basename $config .sh)
	debug "      $repo"
	repo_read_config $repo
    done
}

distro_base_mirror() {
    local DISTRO=$1
    local ARCH=$2
    echo ${REPO_MIRROR[$(distro_base_repo $DISTRO $ARCH)]}
}

distro_base_components() {
    local DISTRO=$1
    local ARCH=$2
    echo ${REPO_COMPONENTS[$(distro_base_repo $DISTRO $ARCH)]}
}

repo_has_arch() {
    local REPO=$1
    local ARCH=$2
    local ARCHES=" ${REPO_ARCHES[$REPO]} "
    local RES
    test "$ARCHES" != "${ARCHES/ $ARCH /}" && RES=0 || RES=1
    return $RES
}

distro_check_package() {
    # Be sure package is valid for distro
    local DISTRO=$1
    local PACKAGE=$2
    local DISTRO_PKG_OK=false

    for p in ${DISTRO_PACKAGES[$DISTRO]}; do
	if test $p = $PACKAGE; then
	    DISTRO_PKG_OK=true
	    break
	fi
    done
    $DISTRO_PKG_OK || error "Package $PACKAGE excluded from distro $DISTRO"
    debug "      Package $PACKAGE included in distro $DISTRO:  OK"
}

distro_base_repo() {
    local DISTRO=$1
    local ARCH=$2
    local repo
    for repo in ${DISTRO_REPOS[$DISTRO]}; do
	if repo_has_arch $repo $ARCH && ${REPO_IS_BASE[$repo]}; then
	    echo $repo
	    return
	fi
    done
    return 1
}

repo_add_apt_key() {
    REPO=$1
    KEY=${REPO_KEY[$REPO]}
    test -n "$KEY" || return 0

    KEYRING=$CHROOT_DIR/etc/apt/trusted.gpg.d/sbuild-extra.gpg
    debug "    Adding apt key '$KEY'"
    case $KEY in
	http://*|https://*)
	    # Install key from URL
	    run bash -c "wget -O - -q $KEY | apt-key --keyring $KEYRING add -"
	    ;;
	*/sbuild-key.pub)
	    # Install sbuild key from sbuild-key.pub
	    run apt-key --keyring $KEYRING add $KEY
	    ;;
	[0-9A-F][0-9A-F][0-9A-F][0-9A-F]*)
	    # Install key from key server
	    run apt-key --keyring $KEYRING \
		adv --keyserver $GPG_KEY_SERVER --recv-key $KEY
	    ;;
	*)
	    error "Unrecognized key '$KEY'"
	    ;;
    esac
    run_debug apt-key --keyring $KEYRING list
}

repo_add_apt_source() {
    local REPO=$1
    local URL=${REPO_MIRROR[$REPO]}
    local ARCHES=$(echo ${REPO_ARCHES[$REPO]} | sed 's/ /,/g')
    local CODENAME=${DISTRO_CODENAME[$DISTRO]}
    local COMPONENTS=${REPO_COMPONENTS[$REPO]}

    if test $REPO = local; then
	CODENAME=$DISTRO
    else
	CODENAME=${DISTRO_CODENAME[$DISTRO]}
    fi
    run bash -c "echo deb [arch=$ARCHES] $URL $CODENAME	$COMPONENTS \\
	>> $CHROOT_DIR/etc/apt/sources.list.d/$REPO.list"
}

repo_configure() {
    local REPO=$1
    debug "    Configuring repo $REPO"
    repo_add_apt_source $REPO
    repo_add_apt_key $REPO
}

distro_clear_apt() {
    if test -f $CHROOT_DIR/etc/apt/sources.list; then
	debug "    Cleaning old apt sources lists"
	run bash -c "> $CHROOT_DIR/etc/apt/sources.list"
	run rm -f $CHROOT_DIR/etc/apt/sources.list.d/*
    fi
}

distro_configure_apt() {
    local DISTRO=$1
    distro_clear_apt

    debug "    Configuring distro $DISTRO"
    for repo in ${DISTRO_REPOS[$DISTRO]} local; do
	repo_configure $repo
    done
}

distro_set_apt_proxy() {
    # Set apt proxy
    if test -n "$HTTP_PROXY"; then
	debug "    Setting http proxy:  $HTTP_PROXY"
	run bash -c "echo Acquire::http::Proxy \\\"$HTTP_PROXY\\\"\\; > \
	    $CHROOT_DIR/etc/apt/apt.conf.d/05proxy"
	run_debug cat $CHROOT_DIR/etc/apt/apt.conf.d/05proxy

	export http_proxy="$HTTP_PROXY"
	export https_proxy="$HTTP_PROXY"
    fi
}

distro_debug() {
    for d in $DISTROS; do
	debug "distro $d:"
	debug "	codename ${DISTRO_CODENAME[$d]}"
	debug "	arches ${DISTRO_ARCHES[$d]}"
	debug "	repos ${DISTRO_REPOS[$d]}"
	for a in ${DISTRO_ARCHES[$d]}; do
	    debug "	arch $a:"
	    debug "	  base repo:  $(distro_base_repo $d $a)"
	    debug "	  base mirror:  $(distro_base_mirror $d $a)"
	    debug "	  base components:  $(distro_base_components $d $a)"
	    repos=
	    for r in ${DISTRO_REPOS[$d]}; do
		if repo_has_arch $r $a; then
		    repos+=" $r"
		fi
	    done
	    debug "	  repos:	$repos"
	done
    done
    for r in $REPOS; do
	debug "repo $r:"
	debug "	mirror ${REPO_MIRROR[$r]}"
	debug "	components ${REPO_COMPONENTS[$r]}"
	debug "	arches ${REPO_ARCHES[$r]}"
	debug "	key ${REPO_KEY[$r]:-(none)}"
    done
}
