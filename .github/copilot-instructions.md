# voltage!os Repository Instructions

## Repository purpose

This repository configures rolling Arch Linux live/installer ISOs. It is primarily shell,
Python, Arch package lists, and system configuration data rather than application source.
The active build profile uses ArchISO; `kiwi/` is not used by the GitHub Actions build.

## Build, validation, and linting

There is no conventional unit-test framework or local package manifest. The GitHub Actions
workflow is the source of truth for validation and builds:

- `.github/workflows/build.yml` performs lightweight repository validation, builds both
  `x86_64` and `aarch64` ISOs, records package versions, and creates a GitHub release.
- The workflow normally runs at 3:00 AM Pacific on a schedule and can be run manually
  from GitHub Actions.

Run the repository checks locally from the repository root (these are Bash/Python checks
that do not require an Arch host):

```bash
bash -n archiso/airootfs/root/customize_airootfs.sh
bash -n archiso/aarch64/profile-overrides.sh
python3 -c 'import ast; ast.parse(open("archiso/aarch64/patch_grub.py").read())'
git diff --check
```

Run one validation check by itself, for example:

```bash
grep -Fq 'ID_LIKE=arch' os-release
grep -Fq 'firefox' archiso/packages
bash -n archiso/airootfs/root/customize_airootfs.sh
```

The full ISO build requires a privileged environment and Arch Linux tools. The CI recipe
is the authoritative build procedure:

- `x86_64`: run from an Arch Linux container or host with `archiso` installed, copy
  `/usr/share/archiso/configs/releng`, overlay `archiso/airootfs/`, append
  `archiso/packages`, and run `mkarchiso`.
- `aarch64`: use an Arch Linux ARM environment, set up the files under
  `archiso/aarch64/`, patch `/usr/bin/mkarchiso` with
  `python archiso/aarch64/patch_grub.py`, then prepare and run the same ArchISO profile.

Do not treat `fedora-minimal.ks`, `dnf.conf`, or `kiwi/config.xml` as active build inputs.

## Architecture

The build constructs a fresh ArchISO `releng` profile rather than maintaining a complete
ArchISO profile in this repository:

1. Copy `/usr/share/archiso/configs/releng` to `build/profile`.
2. Overlay `archiso/airootfs/` into `build/profile/airootfs/`.
3. Copy `os-release` to `build/profile/airootfs/etc/os-release`.
4. Append architecture package and profile data.
5. Run `mkarchiso -v -w build/work -o build/out build/profile`.

The shared live-root overlay contains final system paths under
`archiso/airootfs/`. It supplies SDDM autologin, sudo policy, the Calamares desktop entry,
and first-boot/user setup through `customize_airootfs.sh`.

Architecture differences are isolated under `archiso/aarch64/`:

- `packages` and `pacman.conf` provide the ARM package/repository profile.
- `profile-overrides.sh` extends the ArchISO profile definition with ARM architecture,
  GRUB UEFI boot mode, compression, and kernel parameters.
- `grub.cfg`, `linux-aarch64.preset`, `archiso.conf`, and `mirrorlist` provide ARM boot
  configuration and kernel/initramfs setup.
- `patch_grub.py` patches an external `/usr/bin/mkarchiso` GRUB module list to retain only
  modules present for `arm64-efi` and is intentionally idempotent.

The CI matrix builds `x86_64` and `aarch64` independently. Release assets include both
ISOs plus generated `voltageos-*-packages.txt` files.

## Repository conventions

- Keep package names in the architecture-specific package lists. Shared Arch packages belong
  in `archiso/packages`; ARM-only packages belong in `archiso/aarch64/packages`.
- Put files destined for the built image at their absolute image path below
  `archiso/airootfs/`.
- Preserve `set -euo pipefail` in Bash setup and CI scripts.
- Keep executable mode on `archiso/airootfs/root/customize_airootfs.sh`; the build profile
  explicitly sets it to `0:0:755`.
- The configured live user is `john.doe` with UID `2012`. Changes to the autologin,
  `useradd`, or validation checks must keep those values consistent.
- Arch identity is `ID=voltageos`, `ID_LIKE=arch`, and rolling metadata comes from
  `os-release`; the ISO label and version are rewritten by the build workflow.
- Aarch64 profile changes should preserve the `"arm"` SquashFS BCJ option and
  `clk_ignore_unused pd_ignore_unused arm64.nopauth` kernel parameters unless the build
  requirements explicitly change.
- Plymouth assets are split between `plymouth/` for the direct theme and
  `kiwi/root/usr/share/plymouth/themes/voltageos/` for the inactive legacy tree.
- When changing build validation, update the equivalent grep/test step in
  `.github/workflows/build.yml` and the implementation/configuration in the same change.
