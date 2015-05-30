DISTRO="jessie-bleeding"

# Use jessie chroot
DISTRO_NAME[$DISTRO]="jessie"

# List of packages to build for this distribution
#
# Updated RT kernel packages
DISTRO_PACKAGES[$DISTRO]="xenomai-3 rtai-4.1 linux-3.16"

# Apt package repositories to configure for this distribution
DISTRO_REPOS[$DISTRO]="debian emdebian"
