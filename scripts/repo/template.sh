# Example Apt package repository configuration
#
# See sources.list(5) for legal values.

REPO="myrepo"

# Mirror URL
REPO_MIRROR[$REPO]="http://archive.raspbian.org/raspbian"

# Supported arches
#
# By default, the `$ARCHES` parameter from `base-config.sh`
#REPO_ARCHES[$REPO]="armhf"

# GPG key
#
# This may be a URL, a key fingerprint or a `.gpg` file path.
REPO_KEY[$REPO]="http://archive.raspbian.org/raspbian.public.key"

# Components
#
# Components provided by repository.  Default is 'main'.
#REPO_COMPONENTS[$REPO]="main universe"

# Base distribution flag
#
# Default "false".  If "true", then this repo can serve as the build
# schroot's base repository.
REPO_IS_BASE[$REPO]="true"
