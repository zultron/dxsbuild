
# Default arch list
ARCHES="amd64 i386 armhf"

####################################
# Sbuild/schroot configuration

# Use aufs on tmpfs in sbuild
SBUILD_USE_AUFS="false"

# Enable/disable color output in sbuild: 1 or 0.  Color can be
# annoying in dumb terminals that don't interpret escape characters.
SBUILD_LOG_COLOUR="1"

####################################
# Docker configuration

# Docker sbuild image name
DOCKER_IMAGE=docker-sbuild

# Whether to always allocate a tty in Docker
#
# A bug in Docker pre-1.1.1 prevents command exit status from the
# `docker run` command when a tty is allocated. Set to `false` if you
# need exit status from Docker.
DOCKER_ALWAYS_ALLOCATE_TTY=true

####################################
# Docker container directory configuration

# Base directory of this tree in Docker container
BASE_DIR=/srv

# Sbuild `chroots` directory
SBUILD_CHROOT_DIR=$BASE_DIR/chroots

# Top-level directory for builds
BUILD_BASE_DIR=$BASE_DIR/build/$PACKAGE

# Where source packages live
SOURCE_PKG_DIR=$BUILD_BASE_DIR

# Where source and debianization git trees live
DEBZN_GIT_DIR=$BUILD_BASE_DIR/debzn-git
SOURCE_GIT_DIR=$BUILD_BASE_DIR/source-git

# Build directory for a distro codename
BUILD_DIR=$BUILD_BASE_DIR

# Where sources are built
BUILD_SRC_DIR=$BUILD_DIR/tree-$DISTRO

# Where the Docker context is built
DOCKER_DIR=$BUILD_BASE_DIR/docker

# Generated config directory
CONFIG_DIR=$BASE_DIR/configs

# ccache directory
CCACHE_DIR=$CONFIG_DIR/ccache

####################################
# Relative directories

# Where the Apt package repo is built
REPO_BASE_DIR=repo

# Scripts and configs directories
SCRIPTS_DIR=scripts
DISTRO_CONFIG_DIR=$SCRIPTS_DIR/distro
REPO_CONFIG_DIR=$SCRIPTS_DIR/repo
PACKAGE_CONFIG_DIR=$SCRIPTS_DIR/package

# Build log directory:  store with Apt repository
LOG_DIR=$REPO_BASE_DIR/log

####################################
# GPG key config

# Key server
GPG_KEY_SERVER=hkp://keys.gnupg.net

# Key directory
GNUPGHOME=$CONFIG_DIR/gpg

####################################

# Debianization tarball
DEBZN_TARBALL=$PACKAGE.debian.tar.gz

# Suffix for package version
PACKAGE_VERSION_SUFFIX=~1dxs

# Build script name
DXSBUILD=$(basename $0)

####################################
# distcc
DISTCC_ENABLE="false"
DISTCC_HOSTS="localhost 127.0.0.1"
DISTCC_VERBOSE=""
DISTCC_LOG_LEVEL="warning"

####################################

# Whether to create separate directories for each distro in the local
# apt repository, or to merge the `dists` and `pool` directories
DISTRO_SEPARATE_REPO_DIR="false"

