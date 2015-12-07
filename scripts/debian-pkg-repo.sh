deb_repo_dir() {
    if ${DISTRO_SEPARATE_REPO_DIR[$DISTRO]}; then
	echo ${REPO_BASE_DIR}/${DISTRO}
    else
	echo ${REPO_BASE_DIR}
    fi
}

deb_repo_init() {
    test -z "$SIGNING_KEY" || return 0
    debug "      Apt repo dir: $(deb_repo_dir)"
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

    REPREPRO="run_user reprepro -VV -b $(deb_repo_dir) \
        --confdir +b/conf-${DISTRO} --dbdir +b/db-${DISTRO} \
	--gnupghome $GNUPGHOME"
}

deb_repo_setup() {
    msg "Initializing Debian Apt package repository"
    if test ! -s $(deb_repo_dir)/conf-${DISTRO}/distributions; then
	deb_repo_init

	debug "    Rendering reprepro configuration from ppa-distributions.tmpl"
	run_user mkdir -p $(deb_repo_dir)/conf-${DISTRO}
	run_user bash -c "'sed < $SHARE_DIR/ppa-distributions.tmpl \\
	    > $(deb_repo_dir)/conf-${DISTRO}/distributions \\
	    -e \"s/@DISTRO@/${DISTRO}/g\" \\
	    -e \"s/@DISTRO_CODENAME@/${DISTRO_CODENAME[$DISTRO]}/g\" \\
	    -e \"s/@DISTRO_ARCHES@/${DISTRO_ARCHES[$DISTRO]}/g\" \\
	    -e \"s/@SIGNING_KEY@/${SIGNING_KEY}/g\"'"
    else
	debug "      (Apt repo config already initialized; doing nothing)"
    fi

    if test ! -s $(deb_repo_dir)/dists/${DISTRO}/Release; then
	debug "    Initializing repository files"
	${REPREPRO} export ${DISTRO}
    else
	debug "      (Apt repo already initialized; doing nothing)"
    fi
}

deb_repo_build() {
    announce "$DISTRO:$PACKAGE  Updating Debian Apt package repository"
    deb_repo_init	# repo config
    deb_repo_setup	# set up repo, if needed
    distro_check_package $DISTRO $PACKAGE

    # add source pkg
    msg "    Removing all packages for '$PACKAGE'"
    ${REPREPRO} \
	removesrc ${DISTRO} ${PACKAGE_NAME[$PACKAGE]}

    local DSC_FILE=$(source_package_dsc_glob)
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

    for CHANGES in $(build_dir)/*~1${DISTRO}*.changes; do
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
