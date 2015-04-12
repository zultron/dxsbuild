REPO="rcn"
BASEURL="http://repos.rcn-ee.net"

# Mirror URL
REPO_MIRROR[$REPO]="$BASEURL/debian"

# Supported arches
REPO_ARCHES[$REPO]="armhf"

# GPG key
REPO_KEY[$REPO]="$BASEURL/debian/conf/repos.rcn-ee.net.gpg.key"

# Base distribution flag
REPO_IS_BASE[$REPO]="true"
