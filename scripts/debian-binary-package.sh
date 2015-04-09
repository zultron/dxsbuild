debug "    Sourcing debian-binary-package.sh"
#
# These routines handle building the package.

binary_package_build() {
    msg "Building binary package '$PACKAGE'"
    source_package_init
    sbuild_build_package
}

