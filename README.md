# voltage!os

Rolling-release Arch Linux-based KDE Plasma live image, built for `x86_64`
and `aarch64`. It includes Firefox and Thunderbird. The x86_64 image uses Arch
Linux repositories; the aarch64 image uses Arch Linux ARM repositories.

## Live image

The images start a KDE Plasma desktop with a temporary `voltage` user. On
x86_64, use `archinstall` from a terminal to install Arch Linux, or use the
live environment to test the system. The aarch64 image boots with UEFI GRUB;
installation and boot support depend on the ARM hardware. Changes made in the
live session are not persistent.

The live user has passwordless `sudo` for installation and system
administration. Do not treat the live image as an installed system.

Build artifacts are ArchISO images produced from the official ArchISO `releng`
profile with the packages and live-session configuration in `archiso/`. The
ARM build uses Arch Linux ARM packages, a signed ArchISO package from Arch's
rolling repository, and the architecture-specific UEFI profile in
`archiso/aarch64/`. Its CI builder uses the multi-architecture
[Arch Linux ARM container](https://github.com/Menci/docker-archlinuxarm)
because Arch Linux ARM does not publish an `archiso` package.

`os-release` defines the voltage!os identity used in the live environment.
`VERSION=Rolling` identifies the rolling release; `VERSION_CODENAME=lagtrain`
is the project codename.

## Build locally

For a local x86_64 build on Arch Linux, install `archiso`, then run:

```sh
sudo pacman -Syu archiso
mkdir -p build
cp -a /usr/share/archiso/configs/releng build/profile
cat archiso/packages >> "build/profile/packages.$(uname -m)"
cp -a archiso/airootfs/. build/profile/airootfs/
install -Dm644 os-release build/profile/airootfs/etc/os-release
sed -i \
  -e 's/^iso_name=.*/iso_name="voltageos"/' \
  -e 's/^iso_label=.*/iso_label="VOLTAGE_ROLLING"/' \
  -e 's/^iso_publisher=.*/iso_publisher="Voltage Studios"/' \
  -e 's/^iso_application=.*/iso_application="voltage!os Arch Linux Rolling live image"/' \
  -e 's/^iso_version=.*/iso_version="Rolling"/' \
  build/profile/profiledef.sh
mkarchiso -v -w build/work -o build/out build/profile
```

The GitHub Actions workflow builds both supported architectures. It installs
the current ArchISO package, so the resulting image follows Arch's rolling
repositories and is not pinned to a dated base release.
