FROM archlinux:base-devel

RUN pacman -Syu --needed --noconfirm \
      archiso \
      edk2-aarch64 \
      edk2-ovmf \
      git \
      openssh \
      python \
      qemu-full \
      sudo

RUN useradd --create-home --shell /bin/bash --groups wheel vscode \
    && printf '%s\n' 'vscode ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/vscode \
    && chmod 0440 /etc/sudoers.d/vscode
