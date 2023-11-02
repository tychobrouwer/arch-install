# Install Arch Linux

## Boot the live environment

Update `archlinux-keyring` and `archinstall` packages:

```sh
pacman -Sy archlinux-keyring archinstall
```

Edit `/etc/pacman.conf` and add the following line:

```sh title="/etc/pacman.conf"
ParallelDownloads = 10
```

Run the archinstall script:

```sh title="archinstall"
archinstall
```

## Set up the system

Set the following options:

```sh
Archinstalll language: English
Mirrors: Netherlands
Locales:
  Keyboard layout: us
  Locale language: en_US
  Locale encodeing: UTF-8
Disk configuration:
```

![Disk configuration](btfs-partitions.png)

```sh
Disk encryption: No
Bootloader: systemd-boot
Swap: True
Hostname: arch
Root password: ******
User account:
  username: tychob
  password: ******
  sudo: True
Profile:
  Type: Desktop - Hyperland - polkit
  Graphics drivers: Nvidia (proprietary)
  Greeter: sddm
Audio: Pipewire
Kernels: linux-zen
Additional packages: git
Network configuration:
  Network interface: NetworkManager
Timezone: Europe/Amsterdam
Automatic time sync (NTP): True
Optional repositories: multilib
```

## Reboot

Reboot the system into the new installation:

## Add pacman hook for systemd-boot

Create `/etc/pacman.d/hooks/systemd-boot.hook` with the following content:

```sh title="/etc/pacman.d/hooks/systemd-boot.hook"
[Trigger]
Type = Package
Operation = Upgrade
Target = systemd

[Action]
Description = Gracefully upgrading systemd-boot...
When = PostTransaction
Exec = /usr/bin/systemctl restart systemd-boot-update.service
```

## Basic configuration

Install packages

```sh
sudo pacman -Syu git neofeth
```

## Install SDDM theme

```sh
sudo git clone https://github.com/rototrash/tokyo-night-sddm.git /usr/share/sddm/themes/tokyo-night-sddm
```

Edit the `/etc/sddm.conf` file and set the following options:

```sh title="/etc/sddm.conf"
[Theme]
Current=tokyo-night-sddm
```

## Configure dot files

Configure dot files:

```sh
git clone https://github.com/TychoBrouwer/arch-install.git $HOME/Repositories/

sudo cp -sf $HOME/Repositories/arch-install/dotfiles/waybar /etc/xdg/waybar/config
sudo cp -sf $HOME/Repositories/arch-install/dotfiles/waybar.css /etc/xdg/waybar/style.css
cp -sf $HOME/Repositories/arch-install/dotfiles/.zshrc $HOME/.zshrc
```

## Install waybar

Install `otf-font-awesome` font and `waybar`:

```sh
sudo pacman -Sy waybar lm_sensors otf-font-awesome ttc-iosevka-ss15
sensors-detect
```

Add waybar to the startup applications:

```sh
mkdir -p $HOME/.config/autostart

cat << EOF > $HOME/.config/autostart/waybar.desktop
[Desktop Entry]
Exec=/bin/waybar
Name=Waybar
Type=Application
X-KDE-AutostartScript=true
EOF
```

## Install zsh and oh-my-zsh

Install `zsh` and `oh-my-zsh`:

```sh title="Install zsh and oh-my-zsh"
sudo pacman -Sy zsh
ZSH="$HOME/Repositories/oh-my-zsh" sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
chsh $USER -s $(which zsh)
```
