SHELL := /usr/bin/bash
.ONESHELL:
.DELETE_ON_ERROR:

ARCH ?=
ifeq ($(ARCH),)
ARCH := $(shell uname -m)
endif
ifeq ($(ARCH),amd64)
ARCH := x86_64
endif
ifeq ($(ARCH),arm64)
ARCH := aarch64
endif

BUILD_DIR := build
PROFILE_DIR := $(BUILD_DIR)/profile
WORK_DIR := $(BUILD_DIR)/work
OUT_DIR := $(BUILD_DIR)/out

.PHONY: all help check validate whitespace clean prepare prepare-x86_64 prepare-aarch64 \
	build build-x86_64 build-aarch64 package-versions packages

all: validate build

help:
	@printf '%s\n' \
		'Available targets:' \
		'  make check                  Run repository validation and whitespace checks' \
		'  make validate               Run repository configuration checks' \
		'  make whitespace             Run git diff whitespace checks' \
		'  make prepare                Prepare the native ArchISO profile' \
		'  make build                  Build an ISO for the native architecture' \
		'  make build-x86_64           Build an x86_64 ISO' \
		'  make build-aarch64          Build an aarch64 ISO' \
		'  make package-versions       Record installed packages from build/work' \
		'  make clean                  Remove generated build output'

check: validate whitespace

validate:
	set -euo pipefail
	grep -Fq 'ID_LIKE=arch' os-release
	grep -Fq 'VERSION="Rolling"' os-release
	grep -Fq 'firefox' archiso/packages
	grep -Fq 'thunderbird' archiso/packages
	grep -Fq 'plasma-desktop' archiso/packages
	grep -Fq 'calamares' archiso/packages
	grep -Fq 'Name=Install voltage!os' archiso/airootfs/usr/share/applications/install-voltageos.desktop
	grep -Fq 'Icon=/usr/share/calamares/branding/voltageos/logo.png' archiso/airootfs/usr/share/applications/install-voltageos.desktop
	grep -Fq 'branding: voltageos' archiso/airootfs/root/customize_airootfs.sh
	grep -Fq 'productLogo:     "logo.png"' archiso/airootfs/etc/calamares/branding/voltageos/branding.desc
	cmp -s plymouth/logo.png archiso/airootfs/etc/calamares/branding/voltageos/logo.png
	grep -Fq 'linux-aarch64' archiso/aarch64/packages
	grep -Fq "bootmodes=('uefi.grub')" archiso/aarch64/profile-overrides.sh
	grep -Fq 'User=john.doe' archiso/airootfs/etc/sddm.conf.d/10-voltage.conf
	grep -Fq 'useradd --uid 2012 --comment "John Doe"' archiso/airootfs/root/customize_airootfs.sh
	test -x archiso/airootfs/root/customize_airootfs.sh
	test -f archiso/aarch64/linux-aarch64.preset
	test -f archiso/aarch64/pacman.conf
	bash -n archiso/airootfs/root/customize_airootfs.sh
	bash -n archiso/aarch64/profile-overrides.sh
	python3 -c 'import ast; ast.parse(open("archiso/aarch64/patch_grub.py").read())'
	test ! -e fedora-minimal.ks
	test ! -e dnf.conf
	test ! -e kiwi/config.xml

whitespace:
	git diff --check

prepare: prepare-$(ARCH)

prepare-x86_64:
	set -euo pipefail
	test -f /usr/share/archiso/configs/releng/profiledef.sh
	rm -rf "$(PROFILE_DIR)" "$(WORK_DIR)" "$(OUT_DIR)"
	mkdir -p "$(BUILD_DIR)"
	cp -a /usr/share/archiso/configs/releng "$(PROFILE_DIR)"
	cp -a archiso/airootfs/. "$(PROFILE_DIR)/airootfs/"
	install -Dm644 os-release "$(PROFILE_DIR)/airootfs/etc/os-release"
	cat archiso/packages >> "$(PROFILE_DIR)/packages.x86_64"
	@$(MAKE) --no-print-directory configure-profile

prepare-aarch64:
	set -euo pipefail
	test -f /usr/share/archiso/configs/releng/profiledef.sh
	rm -rf "$(PROFILE_DIR)" "$(WORK_DIR)" "$(OUT_DIR)"
	mkdir -p "$(BUILD_DIR)"
	cp -a /usr/share/archiso/configs/releng "$(PROFILE_DIR)"
	cp -a archiso/airootfs/. "$(PROFILE_DIR)/airootfs/"
	install -Dm644 os-release "$(PROFILE_DIR)/airootfs/etc/os-release"
	cp archiso/aarch64/packages "$(PROFILE_DIR)/packages.aarch64"
	cp archiso/aarch64/pacman.conf "$(PROFILE_DIR)/pacman.conf"
	cp archiso/aarch64/mirrorlist "$(PROFILE_DIR)/airootfs/etc/pacman.d/mirrorlist"
	cp archiso/aarch64/archiso.conf "$(PROFILE_DIR)/airootfs/etc/mkinitcpio.conf.d/archiso.conf"
	mkdir -p "$(PROFILE_DIR)/airootfs/usr/share/voltageos"
	cp archiso/aarch64/linux-aarch64.preset "$(PROFILE_DIR)/airootfs/usr/share/voltageos/"
	cp archiso/aarch64/grub.cfg "$(PROFILE_DIR)/grub/grub.cfg"
	cat archiso/aarch64/profile-overrides.sh >> "$(PROFILE_DIR)/profiledef.sh"
	@$(MAKE) --no-print-directory configure-profile

configure-profile:
	set -euo pipefail
	printf '%s\n' 'file_permissions["/root/customize_airootfs.sh"]="0:0:755"' \
		>> "$(PROFILE_DIR)/profiledef.sh"
	sed -i \
		-e 's/^iso_name=.*/iso_name="voltageos"/' \
		-e 's/^iso_label=.*/iso_label="VOLTAGE_ROLLING"/' \
		-e 's/^iso_publisher=.*/iso_publisher="Voltage Studios"/' \
		-e 's/^iso_application=.*/iso_application="voltage!os Arch Linux Rolling live image"/' \
		-e 's/^iso_version=.*/iso_version="Rolling"/' \
		"$(PROFILE_DIR)/profiledef.sh"

build: build-$(ARCH)

build-x86_64: prepare-x86_64
	set -euo pipefail
	command -v mkarchiso >/dev/null
	mkdir -p "$(WORK_DIR)" "$(OUT_DIR)"
	mkarchiso -v -w "$(WORK_DIR)" -o "$(OUT_DIR)" "$(PROFILE_DIR)"
	@$(MAKE) --no-print-directory package-versions ARCH=x86_64

build-aarch64: prepare-aarch64
	set -euo pipefail
	command -v mkarchiso >/dev/null
	cp "$(shell readlink -f $$(command -v mkarchiso))" "$(BUILD_DIR)/mkarchiso"
	chmod +x "$(BUILD_DIR)/mkarchiso"
	python3 archiso/aarch64/patch_grub.py "$(BUILD_DIR)/mkarchiso"
	mkdir -p "$(WORK_DIR)" "$(OUT_DIR)"
	"$(BUILD_DIR)/mkarchiso" -v -w "$(WORK_DIR)" -o "$(OUT_DIR)" "$(PROFILE_DIR)"
	@$(MAKE) --no-print-directory package-versions ARCH=aarch64

package-versions packages:
	set -euo pipefail
	dbpath="$$(find "$(WORK_DIR)" -type d -path '*/var/lib/pacman/local' -print -quit)"
	test -n "$$dbpath"
	pacman -Q --dbpath "$$dbpath" | sort \
		> "$(OUT_DIR)/voltageos-$(ARCH)-packages.txt"

clean:
	rm -rf "$(BUILD_DIR)"
