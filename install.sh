#!/bin/bash

echo "-------------------------------------------------"
echo "------------------- ARCH SETUP ------------------"
echo "-------------------------------------------------"

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

sudo sed -i 's/base udev/systemd/' /etc/mkinitcpio.conf
sudo sed -i 's/fsck//' /etc/mkinitcpio.conf

sudo systemctl mask systemd-fsck-root.service

echo "-------------------------------------------------"
echo "-----------------INSTALL PACKAGES----------------"
echo "-------------------------------------------------"

# Install packages
sudo pacman -Suy --needed git waybar lm_sensors otf-font-awesome ttc-iosevka-ss15 ttf-jetbrains-mono zsh kvantum openssh ttf-liberation lib32-systemd steam neofetch papirus-icon-theme gimp qbittorrent less curl wget python-pip playerctl xdotool wireguard-tools systemd-resolvconf jq inkscape xorg-xwayland ydotool base-devel --noconfirm

# Install paru
if ! command -v paru &> /dev/null
then
  git clone https://aur.archlinux.org/paru.git /tmp/paru
  cd /tmp/paru || exit
  makepkg -si
  rm -rf /tmp/paru
fi

# Install paru packages
paru -Suy --needed thorium-browser-bin visual-studio-code-bin mailspring nordvpn-bin spotify jellyfin-media-player kopia-ui-bin arduino-ide-bin downgrade --noconfirm --skipreview

# Get variables
reposdirname=$(jq -r '.reposdirname' "./config.json")
reposdir="$HOME/$reposdirname"
config_file="$reposdir/arch-install/config.json"

mkdir -p "$reposdir"
mkdir -p "$HOME/.scripts"
mkdir -p "$HOME/.config/autostart"

gitname=$(jq -r '.gitname' "$config_file")
gitemail=$(jq -r '.gitemail' "$config_file")

# Kopia autostart minimized script
cat << EOF > "$HOME/.scripts/kopia-minimized.sh"
#!/bin/bash
while [[ ! \$(xdotool search --onlyvisible --name kopia) ]]; do :; done
xdotool search --onlyvisible --name kopia windowquit
EOF

sudo chmod +x "$HOME/.scripts/kopia-minimized.sh"

# Create kopia startup script
cat << EOF > "$HOME/.config/autostart/kopia-ui.desktop"
[Desktop Entry]
Type=Application
Version=1.0
Name=kopia-ui
Comment=koipia-uistartup script
Exec=/bin/bash -c "/opt/KopiaUI/kopia-ui && $HOME/.scripts/kopia-minimized.sh"
ExecStartPost=
StartupNotify=false
Terminal=false
EOF

# Install oh-my-zsh
echo "-------------------------------------------------"
echo "-----------------CONFIGURE ZSH-------------------"
echo "-------------------------------------------------"

ZSH="$reposdir/oh-my-zsh" sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

if [ echo "$SHELL" != $(which zsh) ]
then
  chsh "$USER" -s "$(which zsh)"
fi

# Enable waybar
echo "-------------------------------------------------"
echo "----------------CONFIGURE WAYBAR-----------------"
echo "-------------------------------------------------"

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
cat << EOF > "$HOME/.scripts/waybar-spotify.sh"
#!/bin/bash
spotify &
while [[ ! \$(xdotool search --onlyvisible --name spotify) ]]; do :; done
xdotool search --onlyvisible --name spotify windowquit
EOF

sudo cp -f "$reposdir/arch-install/scripts/virt-desktop-checker.sh" "/etc/xdg/waybar/virt-desktop-checker.sh"

sudo chmod +x "$HOME/.scripts/waybar-spotify.sh"
sudo chmod +x "/etc/xdg/waybar/virt-desktop-checker.sh"

cat << EOF > "$HOME/.config/autostart/spotify.desktop"
[Desktop Entry]
Categories=Audio;Music;Player;AudioVideo;
Exec=$HOME/.scripts/waybar-spotify.sh
GenericName=Music Player
Icon=spotify-client
MimeType=x-scheme-handler/spotify;
Name=Spotify
StartupWMClass=spotify
Terminal=false
TryExec=spotify
Type=Application
EOF

echo "-------------------------------------------------"
echo "-------------------APPLY THEME-------------------"
echo "-------------------------------------------------"

# Enable kde plasma themes
if [ ! -d "$reposdir/kde-theme" ]
then
  git clone https://github.com/TychoBrouwer/kde-theme.git "$reposdir/kde-theme"
  cd "$reposdir/kde-theme"
else
  cd "$reposdir/kde-theme"
  git pull
  git rebase
fi
sudo ./install.sh

# Enable Dolphin folder color
if [ ! -d "$reposdir/papirus-folders" ]
then
  git clone https://github.com/PapirusDevelopmentTeam/papirus-folders.git "$reposdir/papirus-folders"
  cd "$reposdir/papirus-folders"
else
  cd "$reposdir/papirus-folders"
  git pull
  git rebase
fi
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
echo "-------------------------------------------------"
echo "-----------------CONFIGURE DOTFILES--------------"
echo "-------------------------------------------------"

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
echo "-------------------------------------------------"
echo "------------------CONFIGURE SSH------------------"
echo "-------------------------------------------------"
if [ ! -f "$HOME/.ssh/id_ed25519" ]
then
  ssh-keygen -q -t ed25519 -a 100 -f "$HOME/.ssh/id_ed25519" -N ''
fi

sudo systemctl enable sshd.service
sudo systemctl start sshd.service

# Apply customizations
echo "-------------------------------------------------"
echo "---------------APPLY CUSTOMIZATIONS--------------"
echo "-------------------------------------------------"

# Set kwinrc settings
kwriteconfig5 --file "$HOME/.config/kwinrc" --group Desktops --key Number 3
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

# Configure Wireguard
echo "-------------------------------------------------"
echo "-----------------CONFIGURE WIREGUARD-------------"
echo "-------------------------------------------------"

wg_n=$( jq -r ".wireguard.[].server" "$config_file" | wc -l )

i=0;
while [ $i -lt $wg_n ]
do
  _jq() {
    echo $(jq -r ".wireguard.[$i]${1}" "$config_file")
  }

  wireguard_private_key=$(_jq '.private_key')
  wireguard_public_key=$(_jq '.public_key')
  wireguard_address=$(_jq '.address')
  wireguard_server=$(_jq '.server')
  wireguard_port=$(_jq '.port')
  wireguard_allowed_ips=$(_jq '.allowed_ips')
  wireguard_dns=$(_jq '.dns')

  sudo bash -c "cat << EOF > /etc/wireguard/wg$i.conf
[Interface]
PrivateKey=$wireguard_private_key
Address=$wireguard_address
DNS=$wireguard_dns

[Peer]
PublicKey=$wireguard_public_key
AllowedIPs=$wireguard_allowed_ips
Endpoint=$wireguard_server:$wireguard_port
PersistentKeepalive=21
EOF"

  ((i=i+1))
done

sudo systemctl enable systemd-resolved.service
sudo systemctl start systemd-resolved.service
sudo systemctl enable wg-quick@wg0.service
sudo systemctl start wg-quick@wg0.service

# TLP setup
echo "-------------------------------------------------"
echo "-------------------CONFIGURE TLP-----------------"
echo "-------------------------------------------------"

is_thinkpad=$( jq -r ".is_thinkpad" "$config_file" )
if [ $is_thinkpad == true ]
then
  sudo pacman -Sy --needed tlp --noconfirm

  echo "Setting theshold for battery charge (start/stop): 75/80" 
  sudo bash -c "cat << EOF > /etc/tlp.conf
START_CHARGE_THRESH_BAT0=75
STOP_CHARGE_THRESH_BAT0=80
EOF"

  sudo systemctl enable tlp.service
  sudo systemctl start tlp.service
  sudo systemctl mask systemd-rfkill.service
  sudo systemctl mask systemd-rfkill.socket

  echo "-------------------------------------------------"
  echo "----------------CONFIGURE HOWDY------------------"
  echo "-------------------------------------------------"

  sudo paru -Sy --needed howdy-beta-git --noconfirm
  sudo sed -i 's/device_path =.*/c\device_path = \/dev\/v4l\/by-id\/usb-Chicony_Electronics_Co._Ltd._Integrated_Camera_0001-video-index0/g' /lib/security/howdy/config.ini
  sudo sed -i 's/capture_failed =.*/c\capture_failed = false/g' /lib/security/howdy/config.ini
  sudo sed -i 's/capture_successful =.*/c\capture_successful = false/g' /lib/security/howdy/config.ini

  wget https://github.com/EmixamPP/linux-enable-ir-emitter/releases/download/5.2.4/linux-enable-ir-emitter-5.2.4.systemd.x86-64.tar.gz -O /tmp/linux-enable-ir-emitter.tar.gz
  sudo tar -C / --no-same-owner -h -xzf /tmp/linux-enable-ir-emitter.tar.gz
  rm /tmp/linux-enable-ir-emitter.tar.gz
fi

# Install nvidia drivers

is_nvidia=$(lspci | grep -i nvidia | wc -l)

if [ $is_nvidia -gt 0 ]
then
  echo "-------------------------------------------------"
  echo "-----------------INSTALL NVIDIA------------------"
  echo "-------------------------------------------------"

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
Exec=/bin/sh -c 'while read -r trg; do case \$trg in linux*) exit 0; esac; done; /usr/bin/mkinitcpio -P'
EOF"
else
  sudo mkinitcpio -P
fi

# Install linux-lts kernel as fallback

echo "-------------------------------------------------"
echo "-----------------INSTALL LINUX-LTS---------------"
echo "-------------------------------------------------"

sudo pacman -Sy --needed linux-lts linux-lts-headers --noconfirm

partition=$(lsblk -o NAME,SIZE | grep -i nvme | awk '{print $1}')

sudo cp /boot/loader/entries/*_linux-zen.conf /boot/loader/entries/linux-lts.conf
sudo cp /boot/loader/entries/*_linux-zen-fallback.conf /boot/loader/entries/linux-lts-fallback.conf

sudo sed -i 's/zen/lts/g' /boot/loader/entries/linux-lts.conf
sudo sed -i 's/zen/lts/g' /boot/loader/entries/linux-lts-fallback.conf

#Install wine with lutris

install_wine=$( jq -r ".install_wine" "$config_file" )
if [ $install_wine == true ]
then
  echo "-------------------------------------------------"
  echo "-----------------INSTALL WINE--------------------"
  echo "-------------------------------------------------"

  sudo pacman -Sy --needed wine wine-mono wine-gecko winetricks lutris samba gnutls lib32-gnutls --noconfirm

  mkdir -p "${WINEPREFIX:-~/.wine}/drive_c/windows/Fonts"
  cd ${WINEPREFIX:-~/.wine}/drive_c/windows/Fonts && for i in /usr/share/fonts/**/*.{ttf,otf}; do ln -s "$i"; done

  sudo bash -c "cat << EOF > /tmp/fontsmoothing.reg
REGEDIT4

[HKEY_CURRENT_USER\Control Panel\Desktop]
"FontSmoothing"="2"
"FontSmoothingOrientation"=dword:00000001
"FontSmoothingType"=dword:00000002
"FontSmoothingGamma"=dword:00000578
EOF"

  WINE=${WINE:-wine} WINEPREFIX=${WINEPREFIX:-$HOME/.wine} $WINE regedit /tmp/fontsmoothing.reg 2> /dev/null

  paru -Sy wine-installer --noconfirm

  mkdir -p "$HOME/.local/share/applications/wine"

  cat << EOF > "$HOME/.local/share/applications/wine/wine-browsedrive.desktop"
[Desktop Entry]
Name=Browse C: Drive
Comment=Browse your virtual C: drive
Exec=wine winebrowser c:
Terminal=false
Type=Application
Icon=folder-wine
Categories=Wine;
EOF

  cat << EOF > "$HOME/.local/share/applications/wine/wine-uninstaller.desktop"
[Desktop Entry]
Name=Uninstall Wine Software
Comment=Uninstall Windows applications for Wine
Exec=wine uninstaller
Terminal=false
Type=Application
Icon=wine-uninstaller
Categories=Wine;
EOF

  cat << EOF > "$HOME/.local/share/applications/wine/wine-winecfg.desktop"
[Desktop Entry]
Name=Configure Wine
Comment=Change application-specific and general Wine options
Exec=winecfg
Terminal=false
Icon=wine-winecfg
Type=Application
Categories=Wine;
EOF

  cat << EOF > "$HOME/.config/menus/applications-merged/wine.menu"
<!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
"http://www.freedesktop.org/standards/menu-spec/menu-1.0.dtd">
<Menu>
  <Name>Applications</Name>
  <Menu>
    <Name>wine-wine</Name>
    <Directory>wine-wine.directory</Directory>
    <Include>
      <Category>Wine</Category>
    </Include>
  </Menu>
</Menu>
EOF
fi

# Setup smb client shares

echo "-------------------------------------------------"
echo "-----------------CONFIGURE SMB-------------------"
echo "-------------------------------------------------"

smb_n=$( jq -r ".smb.[].source" "$config_file" | wc -l )

i=0;
while [ $i -lt $wg_n ]
do
  _jq() {
    echo $(jq -r ".smb.[$i]${1}" "$config_file")
  }

  smb_name=$(_jq '.name')
  smb_description=$(_jq '.description')
  smb_destination=$(_jq '.destination')
  smb_source=$(_jq '.source')
  smb_username=$(_jq '.username')
  smb_password=$(_jq '.password')

  sudo bash -c "cat << EOF > /etc/cifspasswd-$i
username=$smb_username
password=$smb_password
EOF"

  sudo chmod 600 /etc/cifspasswd-$i

  sudo bash -c "cat << EOF > /etc/systemd/system/$smb_name.mount
[Unit]
Description=$smb_description
RequiresMountsFor=/mnt
Requires=network-online.target wg-quick@wg0
After=network-online.target wg-quick@wg0

[Mount]
What=$smb_source
Where=$smb_destination
Type=cifs
Options=uid=tychob,gid=tychob,_netdev,nofail,credentials=/etc/cifspasswd-$i
TimeoutSec=10
LazyUnmount=yes

[Install]
WantedBy=multi-user.target
EOF"

  sudo systemctl enable $smb_name.mount
  sudo systemctl start $smb_name.mount

  ((i=i+1))
done


