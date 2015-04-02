debug "    Sourcing debian-binary-package.sh"
#
# These routines handle building the package.

binary_package_init() {
    test -n "$DSC_FILE" || \
	DSC_FILE=${PACKAGE}_${VERSION}${RELEASE:+-$RELEASE}.dsc
}

binary_package_build() {
    msg "Building binary package '$PACKAGE'"
    binary_package_init
    sbuild_build_package
}

