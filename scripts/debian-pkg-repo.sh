debug "    Sourcing debian-pkg-repo.sh"

deb_repo_init() {
    test -z "$SIGNING_KEY" || return 0
    REPO_DIR_ABS=$(readlink -f $REPO_DIR)
    debug "      Apt repo dir: $REPO_DIR_ABS"
    debug "      GPG key dir: $GNUPGHOME"
    if ! test -f $GNUPGHOME/trustdb.gpg; then
	debug "    Setting up GPG package signing keys"
	run_user mkdir -p $GNUPGHOME; run_user chmod 700 $GNUPGHOME
	run_user GNUPGHOME=$GNUPGHOME gpg --import \
	    $GNUPGHOME/sbuild-key.sec
    fi
    SIGNING_KEY=$(GNUPGHOME=$GNUPGHOME gpg --fingerprint \
	--no-permission-warning 'Sbuild Signer' | \
	awk '/Key fingerprint/ { print $12 $13; }')
    debug "      GPG package signing key fingerprint:  $SIGNING_KEY"

    REPREPRO="run_user reprepro -VV -b ${REPO_DIR_ABS} \
        --confdir +b/conf-${DISTRO} --dbdir +b/db-${DISTRO} \
	--gnupghome $GNUPGHOME"
}

deb_repo_setup() {
    msg "Initializing Debian Apt package repository"
    if test ! -s ${REPO_DIR}/conf-${DISTRO}/distributions; then
	deb_repo_init

	debug "    Rendering reprepro configuration from ppa-distributions.tmpl"
	run_user mkdir -p ${REPO_DIR_ABS}/conf-${DISTRO}
	run_user bash -c "'sed < $SCRIPTS_DIR/ppa-distributions.tmpl \
	    > ${REPO_DIR_ABS}/conf-${DISTRO}/distributions \
	    -e s/@DISTRO@/${DISTRO}/g \
	    -e s/@SIGNING_KEY@/${SIGNING_KEY}/g'"
    else
	debug "      (Apt repo config already initialized; doing nothing)"
    fi

    if test ! -s ${REPO_DIR}/dists/${DISTRO}/Release; then
	debug "    Initializing repository files"
	${REPREPRO} export ${DISTRO}
    else
	debug "      (Apt repo already initialized; doing nothing)"
    fi
}

deb_repo_build() {
    msg "Updating Debian Apt package repository"
    deb_repo_init	# repo config
    deb_repo_setup	# set up repo, if needed
    distro_check_package $DISTRO $PACKAGE

    # add source pkg
    msg "    Removing all packages for '$PACKAGE'"
    ${REPREPRO} \
	removesrc ${DISTRO} ${PACKAGE}

    local DSC_FILE=$BUILD_DIR/${PACKAGE}_*.dsc
    debug "    Adding source package '$DSC_FILE'"
    ${REPREPRO} -C main \
	includedsc ${DISTRO} \
	${DSC_FILE}

    # remove src pkg
	    # ${REPREPRO} -T dsc \
	    # 	remove ${DISTRO} $($(1)_SOURCE_NAME)

    # remove bin pkg
	    # ${REPREPRO} -T deb \
	    # 	$$(if $$(filter-out $$(ARCH),$$(BUILD_INDEP_ARCH)),-A $$(ARCH)) \
	    # 	remove ${DISTRO} $$(call REPREPRO_PKGS,$(1),$$(ARCH))

    for CHANGES in $BUILD_DIR/*.changes; do
	debug "    Adding changes file '$CHANGES'"
	${REPREPRO} -C main \
	    include ${DISTRO} \
	    $CHANGES
    done
}

deb_repo_list() {
    deb_repo_init

    ${REPREPRO} \
	list ${DISTRO}
}
