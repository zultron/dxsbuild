# Getting started

Build the Docker container image:

    ./build.sh -i

Set up the chroot:

    # Machine arch chroot (good for cross-compiling ARM)
    ./build.sh -r jessie
	# Foreign arch chroot (needed for build amd64, host i386)
	./build.sh -ra i386 jessie

Build a package:

    # Machine arch build
	./build.sh -b jessie xenomai
    # Cross-build for ARM
    ./build.sh -ba armhf jessie xenomai

Update apt repo:

    # Add xenomai packages to apt pkg repo
    ./build.sh -R jessie xenomai
	# List jessie packages
    ./build.sh -L jessie

Run a shell in the Docker container:

    ./build.sh -c

Get a shell in the sbuild chroot:

    # Machine arch chroot
	./build.sh -s jessie
	# Foreign arch chroot
	./build.sh -sa i386 jessie


# Sources

[Wookey's configuration]

[Wookey's configuration]:
https://wiki.linaro.org/Platform/DevPlatform/CrossCompile/UsingMultiArch


# TODO

- Add suffix to pkg release
- Fix xenomai pkg release
- Run build as normal user, or give normal user file ownership
- Detect things like version and release from source package
- Put sbuild logs somewhere
