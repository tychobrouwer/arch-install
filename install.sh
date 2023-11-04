#!/bin/bash

# Set parallel downloads pacman
sudo sed -i '/ParallelDownloads/c\ParallelDownloads = 10' /etc/pacman.conf

# Create pacman hook for systemd-boot
sudo mkdir -p /etc/pacman.d/hooks
sudo bash -c "cat <<EOF > /etc/pacman.d/hooks/95-systemd-boot.hook
[Trigger]
Type = Package
Operation = Upgrade
Target = systemd

[Action]
Description = Gracefully upgrading systemd-boot...
When = PostTransaction
Exec = /usr/bin/systemctl restart systemd-boot-update.service
EOF"

# Set locales and time format
sudo sed -i '/#en_US UTF-8/c\en_US UTF-8' /etc/locale.gen
sudo sed -i '/#en_GB UTF-8/c\en_GB UTF-8' /etc/locale.gen
sudo locale-gen
sudo localectl set-locale LANG=en_US.UTF-8
sudo localectl set-locale LC_TIME=en_GB.UTF-8

# Install packages
sudo pacman -Sy --needed git waybar lm_sensors otf-font-awesome ttc-iosevka-ss15 ttf-jetbrains-mono zsh kvantum openssh ttf-liberation steam neofeth papirus-icon-theme gimp qbittorrent less curl wget --noconfirm

# Install paru
git clone https://aur.archlinux.org/paru.git /tmp/paru
cd /tmp/paru || exit
makepkg -si
rm -rf /tmp/paru

# Install paru packages
paru -Sy --needed thorium-browser-bin visual-studio-code-bin mailspring nordvpn-bin --noconfirm --skipreview

# Get variables
read -pr 'Username: ' uservar
read -pr 'Hostname: ' hostnamevar
read -pr 'Repositories directory name: ' reposdirvar

echo
echo 'Enter git name and email ->'
read -pr 'Git name: ' gitname
read -pr 'Git email: ' gitemail

homedir="/home/$uservar"
reposdir="$homedir/$reposdirvar"

# Install oh-my-zsh
ZSH="$reposdir/oh-my-zsh" sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
chsh "$uservar" -s "$(which zsh)"

# Enable waybar
sudo sensors-detect
mkdir -p "$homedir/.config/autostart"
cat << EOF > "$homedir/.config/autostart/waybar.desktop"
[Desktop Entry]
Exec=/bin/waybar
Name=Waybar
Type=Application
X-KDE-AutostartScript=true
EOF

# Enable kde plasma themes
git clone https://github.com/TychoBrouwer/kde-theme.git "$reposdir/kde-theme"
"$reposdir/kde-theme/install.sh"

# Enable Dolphin folder color
git clone https://github.com/PapirusDevelopmentTeam/papirus-folders.git "$reposdir/papirus-folders"
"$reposdir/papirus-folders/install.sh"
papirus-folders -C yaru --theme Papirus-Dark

# Set sddm settings
sudo bash -c "cat << EOF > /etc/sddm.conf.d/kde_settings.conf
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
Font=Noto Sans,10,-1,5,50,0,0,0,0,0

[Users]
MaximumUid=60513
MinimumUid=1000
EOF"

# Configure dotfiles
dotfilesdir="$reposdir/arch-install/dotfiles"
git clone https://github.com/TychoBrouwer/arch-install.git "$reposdir/arch-install"

sudo cp -sf "$dotfilesdir/waybar" "/etc/xdg/waybar/config"
sudo cp -sf "$dotfilesdir/waybar.css" "/etc/xdg/waybar/style.css"
cp -sf "$dotfilesdir/.zshrc" "$homedir/.zshrc"
cp -sf "$dotfilesdir/dolphinrc" "$homedir/.config/dolphinrc"
cp -sf "$dotfilesdir/.directory-dolphin" "$homedir/.local/share/dolphin/view_properties/global/.directory"

# Enable and start sshd
ssh-keygen -q -t ed25519 -a 100 -f "$homedir/.ssh/id_ed25519" -N ''
sudo systemctl enable sshd.service
sudo systemctl start sshd.service

# Configure git
git config --global user.name "$gitname"
git config --global user.email "$gitemail"
git config --global core.ignorecase false

# Set hostname
sudo hostnamectl set-hostname "$hostnamevar"

# Set kwinrc settings
kwriteconfig5 --file "$homedir/.config/kwinrc" --group Desktops --key Number 2
kwriteconfig5 --file "$homedir/.config/ktimezonedrc" --group TimeZones --key LocalZone Europe/Amsterdam

# Set nodisplay for applications from launcher
application_desktop_files=(
  "/usr/share/applications/avahi-discover.desktop"
  "/usr/share/applications/bssh.desktop"
  "/usr/share/applications/bvnc.desktop"
  "/usr/share/applications/assistent.desktop"
  "/usr/share/applications/designer.desktop"
  "/usr/share/applications/linquist.desktop"
  "/usr/share/applications/qdbusviewer.desktop"
  "/usr/share/applications/qv4l2.desktop"
  "/usr/share/applications/qvidcap.desktop"
  "/usr/share/applications/org.kde.plasma-welcome.desktop"
  "/usr/share/applications/org.kde.kinfocenter.desktop"
  "/usr/share/applications/org.kde.kuserfeedback-console.desktop"
  "/usr/share/applications/thorium-shell.desktop"
)

for desktop_file in "${application_desktop_files[@]}"
do
  [ ! -f "$desktop_file" ] && continue
  
  sudo bash -c "grep -q NoDisplay= $desktop_file && sed -i 's/NoDisplay=/NoDisplay=true/' $desktop_file || echo 'NoDisplay=true' >> $desktop_file"
done
