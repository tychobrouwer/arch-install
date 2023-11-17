#!/bin/bash

# Set parallel downloads pacman
sudo sed -i '/ParallelDownloads/c\ParallelDownloads = 20' /etc/pacman.conf

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
sudo pacman -Sy --needed git waybar lm_sensors otf-font-awesome ttc-iosevka-ss15 ttf-jetbrains-mono zsh kvantum openssh ttf-liberation lib32-systemd steam neofetch papirus-icon-theme gimp qbittorrent less curl wget python-pip playerctl xdotool wireguard-tools jq inkscape --noconfirm

# Install paru
if ! command -v paru &> /dev/null
then
  git clone https://aur.archlinux.org/paru.git /tmp/paru
  cd /tmp/paru || exit
  makepkg -si
  rm -rf /tmp/paru
fi

# Install paru packages
paru -Sy --needed thorium-browser-bin visual-studio-code-bin mailspring nordvpn-bin spotify jellyfin-media-player kopia-ui-bin arduino-ide-bin --noconfirm --skipreview

# Get variables
reposdirname=$(jq -r '.reposdirname' "./config.json")
reposdir="$HOME/$reposdirname"
config_file="$reposdir/arch-install/config.json"

gitname=$(jq -r '.gitname' "$config_file")
gitemail=$(jq -r '.gitemail' "$config_file")

# Install oh-my-zsh
ZSH="$reposdir/oh-my-zsh" sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

if [ echo "$SHELL" != "$(which zsh)" ]
then
  chsh "$USER" -s "$(which zsh)"
fi

# Enable waybar
# sudo sensors-detect
cat << EOF > "$HOME/.config/autostart/waybar.desktop"
[Desktop Entry]
Type=Application
Name=Waybar
Exec=waybar
EOF

sudo wget https://raw.githubusercontent.com/Alexays/Waybar/master/resources/custom_modules/mediaplayer.py -O /etc/xdg/waybar/mediaplayer.py
sudo chmod +x /etc/xdg/waybar/mediaplayer.py

# Spotify autostart minimized script
cat << EOF > "$HOME/.config/autostart/spotify.sh"
#!/bin/bash
spotify &
while [[ ! \$(xdotool search --onlyvisible --name spotify) ]]; do :; done
xdotool search --onlyvisible --name spotify windowquit
EOF

sudo chmod +x "$HOME/.config/autostart/spotify.sh"

cat << EOF > "$HOME/.config/autostart/spotify.desktop"
[Desktop Entry]
Categories=Audio;Music;Player;AudioVideo;
Exec=$HOME/.config/autostart/spotify.sh
GenericName=Music Player
Icon=spotify-client
MimeType=x-scheme-handler/spotify;
Name=Spotify
StartupWMClass=spotify
Terminal=false
TryExec=spotify
Type=Application
EOF

# Enable kde plasma themes
git clone https://github.com/TychoBrouwer/kde-theme.git "$reposdir/kde-theme"
cd "$reposdir/kde-theme"
sudo ./install.sh

# Enable Dolphin folder color
git clone https://github.com/PapirusDevelopmentTeam/papirus-folders.git "$reposdir/papirus-folders"
cd "$reposdir/papirus-folders"
./install.sh

# Set Dolphin state (mainly for visible panels)
cat << EOF > "$HOME/.local/share/dolphin/dolphinstaterc"
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

sudo cp -sf "$dotfilesdir/waybar" "/etc/xdg/waybar/config"
sudo cp -sf "$dotfilesdir/waybar.css" "/etc/xdg/waybar/style.css"
cp -sf "$dotfilesdir/.zshrc" "$HOME/.zshrc"
cp -sf "$dotfilesdir/dolphinrc" "$HOME/.config/dolphinrc"
mkdir -p "$HOME/.local/share/dolphin/view_properties/global"
cp -sf "$dotfilesdir/.directory-dolphin" "$HOME/.local/share/dolphin/view_properties/global/.directory"
cp -sf "$dotfilesdir/kscreenlockerrc" "$HOME/.config/kscreenlockerrc"
cp -sf "$dotfilesdir/pip.conf" "$HOME/.config/pip/pip.conf"

# Enable and start sshd
if [ ! -f "$HOME/.ssh/id_ed25519" ]
then
  ssh-keygen -q -t ed25519 -a 100 -f "$HOME/.ssh/id_ed25519" -N ''
fi

sudo systemctl enable sshd.service
sudo systemctl start sshd.service

# Set kwinrc settings
kwriteconfig5 --file "$HOME/.config/kwinrc" --group Desktops --key Number 2
kwriteconfig5 --file "$HOME/.config/ktimezonedrc" --group TimeZones --key LocalZone Europe/Amsterdam

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
  "/usr/share/applications/org.kde.plasma.emojier.desktop"
  "/usr/share/applications/org.kde.kinfocenter.desktop"
  "/usr/share/applications/org.kde.kuserfeedback-console.desktop"
  "/usr/share/applications/thorium-shell.desktop"
  "/usr/share/applications/cmake-gui.desktop"
)

for desktop_file in "${application_desktop_files[@]}"
do
  [ ! -f "$desktop_file" ] && continue
  
  sudo bash -c "grep -q NoDisplay= $desktop_file && sed -i 's/NoDisplay=/NoDisplay=true/' $desktop_file || echo 'NoDisplay=true' >> $desktop_file"
done

sudo bash -c "cat << EOF > $HOME/.local/share/applications//spotify.desktop
[Desktop Entry]
Type=Application
Name=Spotify
GenericName=Music Player
Icon=spotify-client
TryExec=spotify
Exec=spotify
Terminal=false
MimeType=x-scheme-handler/spotify;
Categories=Audio;Music;Player;AudioVideo;
StartupWMClass=spotify
EOF"

# Configure Wireguard VPN connections
wg_n=$( jq -r ".wireguard.[].server" "$config_file" | wc -l )

i=0;
while [ $i -lt $wg_n ]
do
  _jq() {
    echo $(jq -r ".wireguard.[$i]${1}" "$config_file")
  }

  wireguard_description=$(_jq '.description')
  wireguard_private_key=$(_jq '.private_key')
  wireguard_public_key=$(_jq '.public_key')
  wireguard_address=$(_jq '.address')
  wireguard_server=$(_jq '.server')
  wireguard_port=$(_jq '.port')
  wireguard_gateway=$(_jq '.gateway')
  wireguard_allowed_ips=$(_jq '.allowed_ips')

  sudo bash -c "cat << EOF > /etc/wireguard/wg$i.conf
[Interface]
PrivateKey = $wireguard_private_key

[Peer]
PublicKey = $wireguard_public_key
AllowedIPs = $wireguard_allowed_ips
Endpoint = $wireguard_server:$wireguard_port
PersistentKeepalive = 21
EOF"

  sudo bash -c "cat << EOF > /etc/systemd/network/$((99-$i))-wg$i.netdev
[NetDev]
Name = wg$i
Kind = wireguard
Description = $wireguard_description

[WireGuard]
PrivateKey = $wireguard_private_key

[WireGuardPeer]
PublicKey = $wireguard_public_key
AllowedIPs = $wireguard_allowed_ips
Endpoint = $wireguard_server:$wireguard_port
PersistentKeepalive = 21
EOF"

  sudo bash -c "cat << EOF > /etc/systemd/network/$((99-$i))-wg$i.network
[Match]
Name = wg$i

[Network]
Address = $wireguard_address

[Route]
Gateway = $wireguard_gateway
EOF"

  sudo chown root:systemd-network /etc/systemd/network/$((99-$i))-wg$i.netdev
  sudo chmod 0640 /etc/systemd/network/$((99-$i))-wg$i.netdev
done

sudo systemctl restart systemd-networkd.service

# TLP setup

is_thinkpad=$( jq -r ".is_thinkpad" "$config_file" )
if $is_thinkpad == true
then
  sudo pacman -Sy --needed tlp --noconfirm

  sudo bash -c "cat << EOF > /etc/tlp.conf
START_CHARGE_THRESH_BAT0=75
STOP_CHARGE_THRESH_BAT0=80
EOF"

  sudo systemctl enable tlp.service
  sudo systemctl start tlp.service
  sudo systemctl mask systemd-rfkill.service
  sudo systemctl mask systemd-rfkill.socket
fi

# Install nvidia drivers

is_nvidia=$(lspci | grep -i nvidia | wc -l)

if [ $is_nvidia -gt 0 ]
then
  sudo pacman -Sy --needed linux-zen-headers nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings --noconfirm

  sudo sed -i 's/MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm /g' /etc/mkinitcpio.conf
  sudo sed -i 's/kms //g' /etc/mkinitcpio.conf
  sudo mkinitcpio -P

  sudo sed -i '/options/ s/$/ nvidia-drm.modeset=1/' /boot/loader/entries/*_linux-zen.conf

  sudo bash -c "cat EOF > /etc/pacman.d/hooks/nvidia.hook
[Trigger]
Operation=Install
Operation=Upgrade
Operation=Remove
Type=Package
Target=nvidia-dkms
Target=linux-zen

[Action]
Description=Update NVIDIA module in initcpio
Depends=mkinitcpio
When=PostTransaction
NeedsTargets
Exec=/bin/sh -c 'while read -r trg; do case $trg in linux*) exit 0; esac; done; /usr/bin/mkinitcpio -P'
EOF"
fi

# Install Bumblebee

# if [ $is_nvidia -gt 0 ] && [ $is_thinkpad == true ]
# then
#   sudo pacman -Sy --needed bumblebee --noconfirm

#   sudo sed -i 's/Driver=/Driver=nvidia/g' /etc/bumblebee/bumblebee.conf
#   sudo sed -i 's/#PMMethod=/PMMethod=bbswitch/g' /etc/bumblebee/bumblebee.conf

#   sudo gpasswd -a "$USER" bumblebee

#   sudo systemctl enable bumblebeed.service
#   sudo systemctl start bumblebeed.service
# fi
