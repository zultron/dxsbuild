# dbuild local configuration example
#
# Copy this file to `local-config.sh` and customize for your site
#
# The below examples are intended for many use cases; see files in
# `base-config.sh`, `packages`, `distro` and `repo` in the `scripts`
# directory for more variables to customize.

# Set your user name and email here. Used as the 'Maintainer' field in
# package changelogs.
#
#MAINTAINER="John Doe"
#EMAIL="jdoe@example.com"

# User ID to use in Docker containers.  Defaults to `id -u`.
#DOCKER_UID=1000

# Override distro settings
#
# Custom mirror
#DISTRO_MIRROR[jessie]="http://http.debian.net/debian"
#DISTRO_MIRROR[jessie-bpo]="${DISTRO_MIRROR[jessie]}"
#
# Restrict list of arches
#DISTRO_ARCHES[jessie]="armhf"
#
# Add repo to distro
#DISTRO_REPOS[jessie]+=" dovetail-automata"

# Run parallel jobs during build (sets `-j n`)
#PARALLEL_JOBS=4

# Use aufs on tmpfs in sbuild
#SBUILD_USE_AUFS="true"

# Use http/https proxy for package downloads. Especially useful for
# caching packages between removing and rebuilding schroots.
#
#HTTP_PROXY=http://192.168.0.42:3128

# Whether to create separate directories for each distro in the local
# apt repository, or to merge the `dists` and `pool` directories;
# default 'false'
#DISTRO_SEPARATE_REPO_DIR="true"

# Enable/disable color output in sbuild: 1 or 0.  Color can be
# annoying in dumb terminals that don't interpret escape characters.
#SBUILD_LOG_COLOUR="0"

# Enable distcc
#DISTCC_ENABLE="true"
#DISTCC_HOSTS="localhost 127.0.0.1"
#DISTCC_LOG_LEVEL="info"
# Setting this can cause autoconf -fPIC tests to fail, since they scrape
# compiler output
#DISTCC_VERBOSE="1"
