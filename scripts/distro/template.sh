# Example distribution configuration
#
DISTRO="template"

# List of packages to build for this distribution
#
# Package names come from the file names (less the `.sh` suffix) in
# the `/scripts/package` directory. Attempting to build a package not
# in this list will result in an error.
DISTRO_PACKAGES[$DISTRO]="mypkg another-pkg"

# Apt package repositories to configure for this distribution
#
# Repo names come from the file names (less the `.sh` suffix) in the
# `/scripts/repo` directory. The first listed distro that matches the
# build architecture is used as the 'base' distro.
DISTRO_REPOS[$DISTRO]="debian 3rd-party-repo"

# Codename
#
# The default codename is the distro name, from the name of this file.
# In most cases this is unnecessary.
#DISTRO_CODENAME[$DISTRO]="jessie"

# Distro architectures
#
# The default list of architectures comes from the `base-config.sh`
# script `ARCHES` parameter.  In most cases this is unnecessary.
#DISTRO_ARCHES[$DISTRO]="armhf"
