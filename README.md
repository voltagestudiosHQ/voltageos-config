# ![voltage!os™ logo](/plymouth/logo.png)

An operating system for everyone.

> The os for ( everyone v )

## About

voltage!os is an open-source operating system project focused on simplicity and user freedom.

## Status

Early development.

## Contributing

Contributions and feedback are welcome.

## Easy VM

On a native Arch Linux or Arch Linux ARM build host with ArchISO, QEMU, and noVNC/websockify installed, run:

```sh
./easyvm.sh
```

The script defaults to the host architecture; pass `x86_64` or `aarch64` to select it explicitly. It builds the ISO, creates a dynamic 20 GB VHD, and stores both under `/tmp/voltageos-easyvm/`. Open the noVNC URL printed by the script (port `6080`) in a browser. The ARM build requires the ArchISO setup used by the build workflow and an AArch64 UEFI firmware.

## Docker test container

Build the repository's Arch development image and open a shell in it with:

```sh
./test-docker.sh
```

Pass `--gui` to open a lightweight desktop through noVNC at `http://localhost:6080/vnc.html?autoconnect=true&resize=scale`. Pass `--presist` (or `--persist`) to mount the ignored `./presisted/` directory as the container user's home directory so its files survive between runs. The script attempts to open the noVNC URL with `xdg-open` when GUI mode is enabled.
