text
url --mirrorlist="https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-44&arch=$basearch"
repo --name=fedora-updates --mirrorlist="https://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f44&arch=$basearch"
repo --name=vivaldi --baseurl="https://repo.vivaldi.com/archive/rpm/$basearch" --install

lang en_US.UTF-8
keyboard us
timezone UTC --utc
rootpw --lock
firstboot --enable

network --bootproto=dhcp --device=link --activate
firewall --enabled --service=ssh
selinux --enforcing
services --enabled=NetworkManager,sshd,firewalld
bootloader --location=mbr

zerombr
clearpart --all --initlabel
autopart --type=lvm --nohome

%packages --excludedocs
@core
bash-completion
chrony
curl
dnf5
dolphin
git-core
kde-cli-tools
kde-gtk-config
konsole
kwin
NetworkManager-wifi
openssh-clients
openssh-server
pipewire
plymouth
plymouth-plugin-script
plymouth-theme-bgrt
plasma-desktop
plasma-nm
plasma-pa
plasma-welcome
plasma-workspace
sddm
sudo
thunderbird
vivaldi-stable
vim-minimal
wireplumber
xorg-x11-server-Xorg
xdg-user-dirs
-kmail
-kontact
%end

%post
install -d -m 0755 /usr/share/plymouth/themes/voltageos

cat > /usr/share/plymouth/themes/voltageos/voltageos.plymouth <<'THEME'
[Plymouth Theme]
Name=voltage!os
Description=voltage!os codename lagtrain boot theme
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/voltageos
ScriptFile=/usr/share/plymouth/themes/voltageos/voltageos.script
THEME

cat > /usr/share/plymouth/themes/voltageos/voltageos.script <<'SCRIPT'
Window.SetBackgroundTopColor(0.063, 0.035, 0.059);
Window.SetBackgroundBottomColor(0.008, 0.004, 0.008);
screen_width = Window.GetWidth();
screen_height = Window.GetHeight();
panel_y = screen_height * 0.42;
logo = Label("voltage!os");
logo.SetPosition(screen_width / 2, panel_y, 20);
logo.SetAlignment(0.5, 0.5);
logo.SetColor(1.0, 0.84, 0.88);
codename = Label("codename lagtrain");
codename.SetPosition(screen_width / 2, panel_y + screen_height * 0.055, 20);
codename.SetAlignment(0.5, 0.5);
codename.SetColor(0.79, 0.43, 0.52);
status = Label("Starting system");
status.SetPosition(screen_width / 2, panel_y + screen_height * 0.11, 20);
status.SetAlignment(0.5, 0.5);
status.SetColor(1.0, 0.23, 0.37);
fun message_callback(message) {
	status.SetText(message);
}
Plymouth.SetMessageFunction(message_callback);
SCRIPT

plymouth-set-default-theme voltageos -R

cat > /etc/voltage-os-release <<'RELEASE'
NAME="voltage!os"
CODENAME=lagtrain
BASE="Fedora"
RELEASE

systemctl set-default graphical.target
systemctl enable sddm.service
systemctl enable chronyd.service
%end