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
RUN python -m venv /opt/novnc-venv \
    && /opt/novnc-venv/bin/pip install --no-cache-dir websockify==0.13.0 \
    && git clone --depth 1 --branch v1.7.0 \
      https://github.com/novnc/noVNC.git /opt/novnc \
    && ln -s /opt/novnc/utils/novnc_proxy /usr/local/bin/novnc_proxy

ENV PATH="/opt/novnc-venv/bin:${PATH}"

RUN useradd --create-home --shell /bin/bash --groups wheel vscode \
    && printf '%s\n' 'vscode ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/vscode \
    && chmod 0440 /etc/sudoers.d/vscode
