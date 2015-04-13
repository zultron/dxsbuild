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

# Override distro settings
#
# Custom mirror
#DISTRO_MIRROR[jessie]="http://http.debian.net/debian"
#
# Restrict list of arches
#DISTRO_ARCHES[jessie]="armhf"
#
# Add repo to distro
#DISTRO_REPOS[jessie]+=" dovetail-automata"

# Use http/https proxy for package downloads. Especially useful for
# caching packages between removing and rebuilding schroots.
#
#HTTP_PROXY=http://192.168.0.42:3128
