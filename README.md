# Do it

Build the Docker container:

    ./build.sh docker_build

Run a shell in the Docker container:

    ./build.sh

Set up the chroot:

    ./build.sh chroot_setup jessie

Build a package:

    ./build.sh build_package jessie armhf xenomai_2.6.4.dsc

Get a shell in the sbuild chroot:

	./build.sh sbuild_shell jessie

# Sources

[Wookey's configuration]

[Wookey's configuration]:
https://wiki.linaro.org/Platform/DevPlatform/CrossCompile/UsingMultiArch

