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
sudo pacman -Sy --needed git waybar lm_sensors otf-font-awesome ttc-iosevka-ss15 ttf-jetbrains-mono zsh kvantum openssh ttf-liberation steam neofetch papirus-icon-theme gimp qbittorrent less curl wget python-pip playerctl --noconfirm

# Install paru
if ! command -v paru &> /dev/null
then
  git clone https://aur.archlinux.org/paru.git /tmp/paru
  cd /tmp/paru || exit
  makepkg -si
  rm -rf /tmp/paru
fi

# Install paru packages
paru -Sy --needed thorium-browser-bin visual-studio-code-bin mailspring nordvpn-bin spotify --noconfirm --skipreview

# Get variables
read -p "Repositories directory nam: " reposdirvar

echo
echo 'Enter git name and email ->'
read -p "Git name: " gitname
read -p "Git email: " gitemail

homedir="/home/$USER"
reposdir="$homedir/$reposdirvar"

# Install oh-my-zsh
ZSH="$reposdir/oh-my-zsh" sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
chsh "$USER" -s "$(which zsh)"

# Enable waybar
# sudo sensors-detect
cat << EOF > "/etc/systemd/user/waybar.service"
[Unit]
Description=Highly customizable Wayland bar for Sway and Wlroots based compositors.
Documentation=https://github.com/Alexays/Waybar/wiki/
PartOf=graphical-session.target
After=graphical-session.target
Requisite=graphical-session.target

[Service]
ExecStart=usr/bin/waybar
ExecReload=kill -SIGUSR2 \$MAINPID
Restart=on-failure

[Install]
WantedBy=graphical-session.target
EOF

sudo wget https://raw.githubusercontent.com/Alexays/Waybar/master/resources/custom_modules/mediaplayer.py -O /etc/xdg/waybar/mediaplayer.py
sudo chmod +x /etc/xdg/waybar/mediaplayer.py

# Enable kde plasma themes
git clone https://github.com/TychoBrouwer/kde-theme.git "$reposdir/kde-theme"
cd "$reposdir/kde-theme"
sudo ./install.sh

# Enable Dolphin folder color
git clone https://github.com/PapirusDevelopmentTeam/papirus-folders.git "$reposdir/papirus-folders"
cd "$reposdir/papirus-folders"
./install.sh

# Set Dolphin state (mainly for visible panels)
cat << EOF > "$homedir/.local/share/dolphin/dolphinstaterc"
[SettingsDialog]
1280x800 screen: Height=521
1280x800 screen: Width=634

[State]
1280x800 screen: Window-Maximized=true
State=AAAA/wAAAAD9AAAAAwAAAAAAAAC0AAAClfwCAAAAAvsAAAAWAGYAbwBsAGQAZQByAHMARABvAGMAawAAAAAyAAABPgAAAFQA////+wAAABQAcABsAGEAYwBlAHMARABvAGMAawEAAAAyAAAClQAAAF4A////AAAAAQAAALQAAAKV/AIAAAAB+wAAABAAaQBuAGYAbwBEAG8AYwBrAAAAADIAAAKVAAAAhgD///8AAAADAAAFAAAAAMz8AQAAAAH7AAAAGAB0AGUAcgBtAGkAbgBhAGwARABvAGMAawAAAAAAAAAFAAAAAAIA////AAAESAAAApUAAAAEAAAABAAAAAgAAAAI/AAAAAEAAAACAAAAAQAAABYAbQBhAGkAbgBUAG8AbwBsAEIAYQByAQAAAAD/////AAAAAAAAAAA=
EOF

# Set papirus folder theme
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
mkdir -p "$homedir/.local/share/dolphin/view_properties/global"
cp -sf "$dotfilesdir/.directory-dolphin" "$homedir/.local/share/dolphin/view_properties/global/.directory"
cp -sf "$dotfilesdir/.kscreenlockerrc" "$homedir/.config/kscreenlockerrc"
cp -sf "$dotfilesdir/pip.conf" "$homedir/.config/pip/pip.conf"

# Enable and start sshd
ssh-keygen -q -t ed25519 -a 100 -f "$homedir/.ssh/id_ed25519" -N ''
sudo systemctl enable sshd.service
sudo systemctl start sshd.service

# Configure git
git config --global user.name "$gitname"
git config --global user.email "$gitemail"
git config --global core.ignorecase false

# Set kwinrc settings
kwriteconfig5 --file "$homedir/.config/kwinrc" --group Desktops --key Number 2
kwriteconfig5 --file "$homedir/.config/ktimezonedrc" --group TimeZones --key LocalZone Europe/Amsterdam

# Set nodisplay for applications from launcher
application_desktop_files=(
  "/usr/share/applications/avahi-discover.desktop"
  "/usr/share/applications/bssh.desktop"
  "/usr/share/applications/bvnc.desktop"
  "/usr/share/applications/assistant.desktop"
  "/usr/share/applications/designer.desktop"
  "/usr/share/applications/linguist.desktop"
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
