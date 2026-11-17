arch="aarch64"
bootmodes=('uefi.grub')
pacman_conf="pacman.conf"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'arm' '-b' '1M' '-Xdict-size' '1M')
kernel_params_aarch64="clk_ignore_unused pd_ignore_unused arm64.nopauth"
