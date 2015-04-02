# Docker sbuild image name
DOCKER_IMAGE=docker-sbuild

# Base directory of this tree in Docker container
BASE_DIR=/srv

# Sbuild `chroots` directory
SBUILD_CHROOT_DIR=$BASE_DIR/chroots

# Package directory
SBUILD_PKG_DIR=$BASE_DIR/packages

# Repo with various packages
GITHUB_REPO=https://github.com/zultron

# Top-level directory for builds
BUILD_BASE_DIR=$BASE_DIR/build/$PACKAGE

# Where to put files in the Docker container
DOCKER_SRC_DIR=/usr/src/docker-build

# Where source packages live
SOURCE_PKG_DIR=$BUILD_BASE_DIR

# Where debianization git sources live
DEBZN_GIT_DIR=$BUILD_BASE_DIR/debzn-git

# Build directory for a distro codename
BUILD_DIR=$BUILD_BASE_DIR/$CODENAME

# Where sources are built
BUILD_SRC_DIR=$BUILD_DIR/tree

# Where the Apt package repo is built
REPO_DIR=repo

# Where the Docker context is built
DOCKER_DIR=$BUILD_BASE_DIR/docker

# Docker run command
DOCKER_CMD="docker run -i -t -v `pwd`:$DOCKER_SRC_DIR $DOCKER_SUPERUSER"

# Debug flag for passing to docker and scripts
DEBUG_FLAG="`! $DEBUG || echo -d`"
DOCKER_BUILD_DEBUG_FLAG="`! $DEBUG || echo --force-rm=false`"

# Debianization tarball
DEBZN_TARBALL=$PACKAGE.debian.tar.gz

# Key server
GPG_KEY_SERVER=hkp://keys.gnupg.net

# Generated config directory
CONFIG_DIR=$BASE_DIR/configs

# Scripts and configs directories
SCRIPTS_DIR=scripts
DISTRO_CONFIG_DIR=$SCRIPTS_DIR/distro
PACKAGE_CONFIG_DIR=$SCRIPTS_DIR/package


# TCL default version; override in distro config
TCL_VER=8.6
