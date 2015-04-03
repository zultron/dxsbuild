debug "    Sourcing debian-pkg-repo.sh"

deb_repo_init() {
    REPO_DIR_ABS=$(readlink -f $REPO_DIR)
    debug "      Apt repo dir: $REPO_DIR_ABS"
    GNUPGHOME=$CONFIG_DIR/gpg
    debug "      GPG key dir: $GNUPGHOME"
    if ! test -f $GNUPGHOME/trustdb.gpg; then
	debug "    Setting up GPG package signing keys"
	mkdir -p $GNUPGHOME; chmod 700 $GNUPGHOME
	GNUPGHOME=$GNUPGHOME gpg --import \
	    /var/lib/sbuild/apt-keys/sbuild-key.sec
    fi
    SIGNING_KEY=$(GNUPGHOME=$GNUPGHOME gpg --fingerprint 'Sbuild Signer' | \
	awk '/Key fingerprint/ { print $12 $13; }')
    debug "      GPG package signing key fingerprint:  $SIGNING_KEY"

    REPREPRO="reprepro -VV -b ${REPO_DIR_ABS} \
        --confdir +b/conf-${CODENAME} --dbdir +b/db-${CODENAME} \
	--outdir +b/${CODENAME} \
	--gnupghome $GNUPGHOME"
}

deb_repo_setup() {
    if test ! -f ${REPO_DIR}/conf-${CODENAME}/distributions; then
	msg "Initializing Debian Apt package repository"
	deb_repo_init

	debug "    Rendering reprepro configuration from ppa-distributions.tmpl"
	mkdir -p ${REPO_DIR_ABS}/conf-${CODENAME}
	sed < $SCRIPTS_DIR/ppa-distributions.tmpl \
	    > ${REPO_DIR_ABS}/conf-${CODENAME}/distributions \
	    -e "s/@CODENAME@/${CODENAME}/g" \
	    -e "s/@SIGNING_KEY@/${SIGNING_KEY}/g"

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


###########################################
# Build local apt repo

docker_image_local_repo() {
    # Configure local apt repo and add any extra packages

    if test -z "${EXTRA_BUILD_PACKAGES}"; then
	debug "No extra build packages specified; not building local repo"
	return
    fi

    msg "Installing extra build dependencies"

    # Build repo
    (
	cd $REPO_DIR
	for i in *.deb; do
	    dpkg-deb -W --showformat='${Package}\n' $i >> overrides
	done
	dpkg-scanpackages . overrides | gzip > Packages.gz
    )

    # Configure Apt
    echo 'deb file://$DOCKER_SRC_DIR/repo /' \
	> /etc/apt/sources.list.d/local.list
    repo $DOCKER_SRC_DIR/repo
}
