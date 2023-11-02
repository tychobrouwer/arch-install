# Install Arch Linux

## Boot the live environment

Update `archlinux-keyring` and `archinstall` packages:

```sh
sudo pacman -Sy archlinux-keyring archinstall
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

## Install KDE Plasma theme

Get the theme:

```sh
git clone https://github.com/TychoBrouwer/kde-theme.git $HOME/Repositories/kde-theme
cd $HOME/Repositories/kde-theme
sudo ./install.sh

sudo pacman -Sy kvantum
```

Edit the `/etc/sddm.conf.d/kde_settings.conf` file and set the following options:

```sh title="/etc/sddm.conf.d/kde_settings.conf"
[Theme]
Current=my-theme
CursorTheme=breeze_cursors
```

Mannually configure the background image.

## Congifure SSH

Install and enable SSH:

```sh
sudo pacman -Sy openssh
sudo systemctl enable sshd
sudo systemctl start sshd
```

Generate SSH keys:

```sh
ssh-keygen -q -t ed25519 -a 100 -f $HOME/.ssh/id_ed25519 -N ''
```

## Configure git

Configure git:

```sh
git config --global user.name "Tycho Brouwer"
git config --global user.email ""
```

## Configure paru

Install `paru`:

```sh
git clone https://aur.archlinux.org/paru.git $HOME/Repositories/paru
cd $HOME/Repositories/paru
makepkg -si
```

## Install Steam

Install `steam`:

```sh
sudo pacman -Sy ttf-liberation steam
```

## Basic configuration

Install packages

```sh
sudo pacman -Sy neofeth code
sudo paru -Sy thorium-browser-bin
```

To set time locale to 24h format, change `etc/locale.gen` and uncomment the following line:

```sh title="/etc/locale.gen"
en_GB.UTF-8 UTF-8
```

Then run:

```sh
sudo locale-gen
sudo localectl set-locale LC_TIME=en_GB.UTF-8
```
