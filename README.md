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
    # Machine arch build
    ./dbuild -b jessie xenomai
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


# TODO

- Persist signing key in schroot config
- Refactor options:  separate Docker, sbuild, dpkg and apt functions
- Don't recreate source pkg every time
- Do package configure and other steps with aufs (on tmpfs)
  - https://wiki.debian.org/sbuild#Using_aufs_on_tmpfs_with_sbuild
  - http://christian.hofstaedtler.name/blog/2011/05/schroot-and-aufs.html
- Figure out what to do about merged pool directory
- Add suffix to pkg release
- Run build as normal user, or give normal user file ownership
- Detect things like version and release from source package
- Put sbuild logs somewhere
- Add ccache
  - https://wiki.debian.org/sbuild#Using_.22ccache.22_with_sbuild
- Add lintian, piuparts, adt-run, etc.
- Can bindmounts be done better?  https://wiki.debian.org/sbuild#Bind_mounts
- Add local config override file
