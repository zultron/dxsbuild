# FIXME
docker run --privileged -i -e IN_DOCKER=true -t -v /d/mock/dxsbuild:/srv \
       docker-sbuild

# *dxsbuild*: Docker cross-sbuild scripts

These scripts build Debian packages in a Docker container (Ubuntu
Trusty) with sbuild. Foreign-architecture binary packages are
cross-built when possible, and fall back to `qemu` when necessary.

*Supported distros:*

- Debian Jessie
- Ubuntu Trusty
- Raspbian Jessie (`qemu` only)

*Supported architectures:*

- `amd64` (usually the machine arch)
- `i386` (native builds as `linux32` personality)
- `armhf` (`amd64`-cross-`armhf` or `qemu`)

## Work flow

These scripts are originally written to maintain the [Dovetail Automata
LLC distribution][1] of [Machinekit][2]. Since Jessie and Trusty, Machinekit
only requires a handful of packages not present in upstream distros.
However, building and maintaining the distribution is quite complex,
since packages are interdependent and packages require a special
configuration step in the chroot before `dpkg-source -b`.

Below, the most common work flows are described.

[1]: http://deb.dovetail-automata.com
[2]: http://machinekit.io

### Setting up

- Install Docker
- Check out this source
- Copy `local-config-example.sh` to `local-config.sh` and edit at least
  `MAINTAINER`, `EMAIL` and `DOCKER_UID`.
- Get command line usage

    ./dxsbuild

- Set up and edit a local configuration as needed

    cp local-config-example.sh local-config.sh
    $EDITOR local-config.sh

- Build the Docker container image

    ./dxsbuild -i

- Set up chroots; for cross-building `armhf`, set up an `amd64` chroot

    # amd64 (default) chroot
    ./dxsbuild -r jessie
    # armhf chroot
    ./dxsbuild -ra armhf jessie

### Build a package

Packages are built for a particular distribution and architecture.
Built packages are placed in the `/build/PACKAGE` directory, and the
Apt package repository is in `/repo`.

- Build a source package.

    bin/dxs-build -s jessie xenomai

- Build binary packages.

    # amd64 and armhf binary packages; 16 parallel jobs
    bin/dxs-build -b -j 16 jessie xenomai
    bin/dxs-build -ba armhf -j 16 jessie xenomai

- Add source and binary packages to Apt package repository.

    bin/dxs-build -r jessie xenomai

- Do all in one step
  
    bin/dxs-build -sbrj 16 jessie xenomai

## Use cases

### Rebuild a single package

When maintaining a distribution, a single package may need updates. By
default, `dxsbuild` expects dependencies within the distribution to be
built locally in the `repo` Apt package repository. This unnecessary
extra building is undesirable for a single package.

To configure `dxsbuild` to build against dependencies in the released
distribution, edit `local-config.sh` and add the Apt repository to the
distribution.

    # Add Dovetail Automata Machinekit Jessie repo
    DISTRO_REPOS[jessie]+=" dovetail-automata"

Then build as usual.  Apt will search for package dependencies in the
added repository.

### Build distribution from scratch

When building for the first time for a new distro, all packages must
be built from scratch.  There is no need to configure extra
repositories as above.

## Configuration

All configuration is in the `/scripts/base-config.sh`,
`/scripts/package/*.sh`, `/scripts/distro/*.sh` and
`/scripts/repo/*.sh` files. Before customizing that configuration for
your local site, consider overriding configuration in
`local-config.sh` first.

To add a new package, repo or distro, see the corresponding
`template.sh` file for a list and description of each parameter.

## Debugging

Turn on **debug output** with the `-d` argument.  Turn on script tracing
and other very verbose output with `-dd`.

Start a **Docker shell**:

    ./dxsbuild -c

Start an **schroot shell**:

    # Machine arch chroot
    ./dxsbuild -s jessie
    # Foreign arch chroot
    ./dxsbuild -sa i386 jessie

## Debuggering with `gdb` in `qemu`

The `qemu` environment won't allow direct use of `gdb`. Instead, in
the `qemu` chroot environment, run the program using ` qemu-arm-static
-g PORT` and attach `gdb` from the Docker container.

    ./dxsbuild -c
    ./dxsbuild -sda armhf jessie \
        qemu-arm-static -g 1234 /usr/bin/msgfmt &
    arm-none-eabi-gdb \
        -directory chroots/jessie-amd64/build/gettext-kJWpdX/gettext-0.18.3.1 \
        -ex 'set sysroot chroots/jessie-armhf' \
        -ex 'target remote localhost:1234' \
        chroots/jessie-armhf/usr/bin/msgfmt

## Maintenance

After running a zillion builds, Docker may fill up the root filesystem
with old images.  Use the following to clean them out:

    # Clean up all containers
    docker rm $(docker ps -a -q)
    # Clean up all images not associated with a container
    docker rmi $(docker images | awk '/^<none>/ { print $3 }')

## `binfmt_misc`

On Debian, simply install the `binfmt-support` package to enable
transparent qemu emulation in foreign-arch schroots.

On systems where this must be done manually, if
`/proc/sys/fs/binfmt_misc` doesn't exist, load the `binfmt_misc`
module, and then:

    echo ':qemu-arm:M::\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x28\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-arm-static:' \
        > /proc/sys/fs/binfmt_misc/register
