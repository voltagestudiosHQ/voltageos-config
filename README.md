# voltage!os

An operating system for everyone.

> The os for ( everyone v )

## About

voltage!os is an open-source operating system project focused on simplicity and user freedom.

## Status

Early development.

## Contributing

Contributions and feedback are welcome.

## Easy VM

On a native Arch Linux or Arch Linux ARM build host with ArchISO and QEMU installed, run:

```sh
./easyvm.sh
```

The script defaults to the host architecture; pass `x86_64` or `aarch64` to select it explicitly. It builds the ISO, creates a dynamic 20 GB VHD, and stores both under `/tmp/voltageos-easyvm/`. Connect a VNC client to `127.0.0.1:5900`. The ARM build requires the ArchISO setup used by the build workflow and an AArch64 UEFI firmware.
