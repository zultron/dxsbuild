debug "    Sourcing debian-pkg-repo.sh"

deb_repo_init() {
    REPO_DIR_ABS=$(readlink -f $REPO_DIR)
    debug "      Apt repo dir: $REPO_DIR_ABS"
    debug "      GPG key dir: $GNUPGHOME"
    if ! test -f $GNUPGHOME/trustdb.gpg; then
	debug "    Setting up GPG package signing keys"
	run_user mkdir -p $GNUPGHOME; run_user chmod 700 $GNUPGHOME
	run_user GNUPGHOME=$GNUPGHOME gpg --import \
	    /var/lib/sbuild/apt-keys/sbuild-key.sec
    fi
    SIGNING_KEY=$(GNUPGHOME=$GNUPGHOME gpg --fingerprint 'Sbuild Signer' | \
	awk '/Key fingerprint/ { print $12 $13; }')
    debug "      GPG package signing key fingerprint:  $SIGNING_KEY"

    REPREPRO="run_user reprepro -VV -b ${REPO_DIR_ABS} \
        --confdir +b/conf-${CODENAME} --dbdir +b/db-${CODENAME} \
	--outdir +b/${CODENAME} \
	--gnupghome $GNUPGHOME"
}

deb_repo_setup() {
    if test ! -f ${REPO_DIR}/conf-${CODENAME}/distributions; then
	msg "Initializing Debian Apt package repository"
	deb_repo_init

	debug "    Rendering reprepro configuration from ppa-distributions.tmpl"
	run_user mkdir -p ${REPO_DIR_ABS}/conf-${CODENAME}
	run_user bash -c "sed < $SCRIPTS_DIR/ppa-distributions.tmpl \
	    > ${REPO_DIR_ABS}/conf-${CODENAME}/distributions \
	    -e s/@CODENAME@/${CODENAME}/g \
	    -e s/@SIGNING_KEY@/${SIGNING_KEY}/g"

	debug "    Initializing repository files"
	${REPREPRO} export ${CODENAME}
    fi
}

deb_repo_build() {
    msg "Updating Debian Apt package repository"
    deb_repo_init	# repo config
    deb_repo_setup	# set up repo, if needed
    binary_package_init	# source pkg config

    # add source pkg
    msg "    Removing all packages for '$PACKAGE'"
    ${REPREPRO} \
	removesrc ${CODENAME} ${PACKAGE}

    debug "    Adding source package '$DSC_FILE'"
    ${REPREPRO} -C main \
	includedsc ${CODENAME} \
	$BUILD_DIR/${DSC_FILE}

    # remove src pkg
	    # ${REPREPRO} -T dsc \
	    # 	remove ${CODENAME} $($(1)_SOURCE_NAME)

    # remove bin pkg
	    # ${REPREPRO} -T deb \
	    # 	$$(if $$(filter-out $$(ARCH),$$(BUILD_INDEP_ARCH)),-A $$(ARCH)) \
	    # 	remove ${CODENAME} $$(call REPREPRO_PKGS,$(1),$$(ARCH))

    for CHANGES in $BUILD_DIR/*.changes; do
	debug "    Adding changes file '$CHANGES'"
	${REPREPRO} -C main \
	    include ${CODENAME} \
	    $CHANGES
    done
}

deb_repo_list() {
    deb_repo_init

    ${REPREPRO} \
	list ${CODENAME}
}
