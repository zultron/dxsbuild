# dbuild local configuration example
#
# Copy this file to `local-config.sh` and customize for your site
#
# The below examples are intended for many use cases; see
# `scripts/base-config.sh`, `scripts/packages/*.sh` and
# `scripts/distro/*.sh` for more variables to customize

# http/https proxy for package downloads
#HTTP_PROXY=http://192.168.0.42:3128

# Whether to always allocate a tty in Docker (true/false)
#
# A bug in Docker pre-1.1.1 prevents command exit status from the
# `docker run` command when a tty is allocated. Set to `false` if you
# need exit status from Docker.
#DOCKER_ALWAYS_ALLOCATE_TTY=true

