#!/usr/bin/env bash
set -euo pipefail

die() {
  printf 'easyvm: %s\n' "$*" >&2
  exit 1
}

usage() {
  printf 'Usage: %s [x86_64|aarch64]\n' "$0"
}

case "${1:-}" in
  -h|--help)
    usage
    exit 0
    ;;
  ""|x86_64|aarch64)
    target_arch="${1:-}"
    ;;
  *)
    usage >&2
    die "unsupported architecture: $1"
    ;;
esac

if [[ -z "$target_arch" ]]; then
  case "$(uname -m)" in
    x86_64) target_arch=x86_64 ;;
    aarch64|arm64) target_arch=aarch64 ;;
    *) die "cannot infer a supported architecture from $(uname -m)" ;;
  esac
fi

host_arch="$(uname -m)"
case "$target_arch:$host_arch" in
  x86_64:x86_64|aarch64:aarch64|aarch64:arm64) ;;
  *) die "build $target_arch on a native $target_arch host (current host: $host_arch)" ;;
esac

for command_name in mkarchiso qemu-img; do
  command -v "$command_name" >/dev/null 2>&1 || die "required command not found: $command_name"
done

case "$target_arch" in
  x86_64) qemu_command=qemu-system-x86_64 ;;
  aarch64) qemu_command=qemu-system-aarch64 ;;
esac
command -v "$qemu_command" >/dev/null 2>&1 || die "required command not found: $qemu_command"

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
run_root="/tmp/voltageos-easyvm"
mkdir -p "$run_root"
run_dir="$(mktemp -d "$run_root/$target_arch.XXXXXX")"
profile_dir="$run_dir/profile"
work_dir="$run_dir/work"
output_dir="$run_dir/out"
disk_path="$run_dir/voltageos.vhd"
mkdir -p "$work_dir" "$output_dir"

qemu-img create -f vpc -o subformat=dynamic "$disk_path" 20G

cp -a /usr/share/archiso/configs/releng "$profile_dir"
cp -a "$repo_root/archiso/airootfs/." "$profile_dir/airootfs/"
install -Dm644 "$repo_root/os-release" "$profile_dir/airootfs/etc/os-release"

if [[ "$target_arch" == x86_64 ]]; then
  cat "$repo_root/archiso/packages" >> "$profile_dir/packages.x86_64"
else
  cp "$repo_root/archiso/aarch64/packages" "$profile_dir/packages.aarch64"
  cp "$repo_root/archiso/aarch64/pacman.conf" "$profile_dir/pacman.conf"
  cp "$repo_root/archiso/aarch64/mirrorlist" \
    "$profile_dir/airootfs/etc/pacman.d/mirrorlist"
  cp "$repo_root/archiso/aarch64/archiso.conf" \
    "$profile_dir/airootfs/etc/mkinitcpio.conf.d/archiso.conf"
  mkdir -p "$profile_dir/airootfs/usr/share/voltageos"
  cp "$repo_root/archiso/aarch64/linux-aarch64.preset" \
    "$profile_dir/airootfs/usr/share/voltageos/"
  cp "$repo_root/archiso/aarch64/grub.cfg" "$profile_dir/grub/grub.cfg"
  cat "$repo_root/archiso/aarch64/profile-overrides.sh" >> "$profile_dir/profiledef.sh"
fi

printf '%s\n' 'file_permissions["/root/customize_airootfs.sh"]="0:0:755"' \
  >> "$profile_dir/profiledef.sh"
sed -i \
  -e 's/^iso_name=.*/iso_name="voltageos"/' \
  -e 's/^iso_label=.*/iso_label="VOLTAGE_ROLLING"/' \
  -e 's/^iso_publisher=.*/iso_publisher="Voltage Studios"/' \
  -e 's/^iso_application=.*/iso_application="voltage!os Arch Linux Rolling live image"/' \
  -e 's/^iso_version=.*/iso_version="Rolling"/' \
  "$profile_dir/profiledef.sh"

mkarchiso_path="$(readlink -f "$(command -v mkarchiso)")"
if [[ "$target_arch" == aarch64 ]]; then
  mkarchiso_path="$run_dir/mkarchiso"
  cp "$(readlink -f "$(command -v mkarchiso)")" "$mkarchiso_path"
  chmod +x "$mkarchiso_path"
  command -v python3 >/dev/null 2>&1 || die "required command not found: python3"
  python3 "$repo_root/archiso/aarch64/patch_grub.py" "$mkarchiso_path"
fi

if [[ "$EUID" -eq 0 ]]; then
  "$mkarchiso_path" -v -w "$work_dir" -o "$output_dir" "$profile_dir"
else
  command -v sudo >/dev/null 2>&1 || die "mkarchiso needs root; install sudo or run as root"
  sudo "$mkarchiso_path" -v -w "$work_dir" -o "$output_dir" "$profile_dir"
fi

mapfile -t iso_files < <(find "$output_dir" -maxdepth 1 -type f -name '*.iso' -print)
[[ "${#iso_files[@]}" -eq 1 ]] || die "expected one ISO in $output_dir, found ${#iso_files[@]}"
iso_path="${iso_files[0]}"

qemu_args=(
  -m 4G
  -smp 2
  -display none
  -monitor none
  -vnc 127.0.0.1:0
  -cdrom "$iso_path"
  -drive "file=$disk_path,format=vpc,if=virtio"
  -nic user,model=virtio-net-pci
  -boot order=d
)
if [[ "$target_arch" == aarch64 ]]; then
  firmware=""
  for candidate in \
    /usr/share/edk2/aarch64/QEMU_EFI.fd \
    /usr/share/qemu-efi-aarch64/QEMU_EFI.fd
  do
    if [[ -f "$candidate" ]]; then
      firmware="$candidate"
      break
    fi
  done
  [[ -n "$firmware" ]] || die "install an AArch64 UEFI firmware (QEMU_EFI.fd) to boot the ISO"
  qemu_args=(-machine virt -cpu max -bios "$firmware" "${qemu_args[@]}")
fi

printf 'ISO: %s\nDisk: %s\nVNC: 127.0.0.1:5900\n' "$iso_path" "$disk_path"
exec "$qemu_command" "${qemu_args[@]}"
