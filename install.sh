#!/bin/bash

# Set parallel downloads pacman
sudo sed -i '/ParallelDownloads/c\ParallelDownloads = 20' /etc/pacman.conf

# Create pacman hook for systemd-boot
sudo mkdir -p /etc/pacman.d/hooks
sudo cat <<EOF > /etc/pacman.d/hooks/systemd-boot.hook
[Trigger]
Type = Package
Operation = Upgrade
Target = systemd

[Action]
Description = Gracefully upgrading systemd-boot...
When = PostTransaction
Exec = /usr/bin/systemctl restart systemd-boot-update.service
EOF

# Set locales and time format
sudo sed -i '/en_US.UTF-8/c\en_US.UTF-8' /etc/locale.gen
sudo sed -i '/en_GB.UTF-8/c\en_US.UTF-8' /etc/locale.gen
sudo locale-gen
sudo localectl set-locale LANG=en_US.UTF-8
sudo localectl set-locale LC_TIME=en_GB.UTF-8

# Install packages
sudo pacman -S --needed git waybar lm_sensors otf-font-awesome ttc-iosevka-ss15 ttf-jetbrains-mono zsh kvantum openssh ttf-liberation steam neofeth code papirus-icon-theme gimp

# Install paru
git clone https://aur.archlinux.org/paru.git /tmp/paru
cd /tmp/paru
makepkg -si
rm -rf /tmp/paru

# Install paru packages
sudo paru -S --needed thorium-browser-bin

# Get variables
read -p 'Username: ' uservar
read -p 'Hostname: ' hostnamevar
read -p 'Repositories directory name: ' reposdirvar

echo
echo 'Enter git name and email ->'
read -p 'Git name: ' gitname
read -p 'Git email: ' gitemail

$homedir = "/home/$uservar"
$reposdir = "$homedir/$reposdirvar"

# Install oh-my-zsh
ZSH="$reposdir/oh-my-zsh" sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
chsh $uservar -s $(which zsh)

# Enable waybar
sudo sensors-detect
mkdir -p $homedir/.config/autostart
cat << EOF > $homedir/.config/autostart/waybar.desktop
[Desktop Entry]
Exec=/bin/waybar
Name=Waybar
Type=Application
X-KDE-AutostartScript=true
EOF

# Enable kde plasma themes
git clone https://github.com/TychoBrouwer/kde-theme.git $reposdir/kde-theme
cd $reposdir/kde-theme
sudo ./install.sh

# Set sddm settings
sudo cat << EOF > /etc/sddm.conf.d/kde_settings.conf
[Autologin]
Relogin=false
Session=
User=

[General]
HaltCommand=/usr/bin/systemctl poweroff
RebootCommand=/usr/bin/systemctl reboot

[Theme]
Current=my-theme
CursorTheme=breeze_cursors

[Users]
MaximumUid=65000
MinimumUid=1000
EOF

# Configure dotfiles
git clone https://github.com/TychoBrouwer/arch-install.git $reposdir/arch-install
cd $reposdir/arch-install

sudo cp -sf $reposdir/arch-install/dotfiles/waybar /etc/xdg/waybar/config
sudo cp -sf $reposdir/arch-install/dotfiles/waybar.css /etc/xdg/waybar/style.css
cp -sf $reposdir/arch-install/dotfiles/.zshrc $homedir/.zshrc

# Enable and start sshd
ssh-keygen -q -t ed25519 -a 100 -f $homedir/.ssh/id_ed25519 -N ''
sudo systemctl enable sshd.service
sudo systemctl start sshd.service

# Configure git
git config --global user.name "$gitname"
git config --global user.email "$gitemail"
git config --global core.ignorecase false

# Set hostname
sudo hostnamectl set-hostname $hostnamevar

# Set kwinrc settings
kwriteconfig5 --file $homedir/.config/kwinrc --group TabBox --key LayoutName thumbnail_grid
kwriteconfig5 --file $homedir/.config/kwinrc --group Desktops --key Number 3
kwriteconfig5 --file $homedir/.config/ktimezonedrc --group TimeZones --key LocalZone Europe/Amsterdam
