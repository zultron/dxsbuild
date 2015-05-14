
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
build_base_dir() { echo $BASE_DIR/build/$PACKAGE; }

# Build directory for a distro codename
build_dir() { echo $(build_base_dir); }

# Generated config directory
CONFIG_DIR=$BASE_DIR/configs

# ccache directory
CCACHE_DIR=$CONFIG_DIR/ccache
CCACHE_DISABLE=""
#CCACHE_LOGFILE=
CCACHE_MAXSIZE="1G"

####################################
# Local apt package repository

# Where the Apt package repo is built
REPO_BASE_DIR=$BASE_DIR/repo

####################################
# Scripts and configs directories
SCRIPTS_DIR=$BASE_DIR/scripts
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

# Suffix for package version
PACKAGE_VERSION_SUFFIX=~1dxs

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

