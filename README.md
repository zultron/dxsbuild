# Getting started

Build the Docker container image:

    ./dbuild -i

Set up the chroot:

    # Machine arch chroot (good for cross-compiling ARM)
    ./dbuild -r jessie
    # Foreign arch chroot (needed for build amd64, host i386)
    ./dbuild -ra i386 jessie

Build a package:

    # Source package build
    ./dbuild -S jessie xenomai
    # Machine arch build with parallel jobs
    ./dbuild -b -j 16 jessie xenomai
    # Cross-build for ARM
    ./dbuild -ba armhf jessie xenomai

Update apt repo:

    # Add xenomai packages to apt pkg repo
    ./dbuild -R jessie xenomai
    # List jessie packages
    ./dbuild -L jessie

Run a shell in the Docker container:

    ./dbuild -c

Get a shell in the sbuild chroot:

    # Machine arch chroot
    ./dbuild -s jessie
    # Foreign arch chroot
    ./dbuild -sa i386 jessie
