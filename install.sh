#!/bin/bash

# Get variables
current_dir=$(pwd)
config_file="$current_dir/config.json"
reposdirname=$(jq -r '.reposdirname' "$config_file")
reposdir="$HOME/$reposdirname"

mkdir -p "$reposdir"
mkdir -p "$HOME/.scripts"
mkdir -p "$HOME/.config/autostart"

gitname=$(jq -r '.gitname' "$config_file")
gitemail=$(jq -r '.gitemail' "$config_file")

# Set git config
git config --global user.name "$gitname"
git config --global user.email "$gitemail"

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
sudo pacman -Suy --needed git waybar lm_sensors otf-font-awesome ttc-iosevka-ss15 ttf-jetbrains-mono zsh kvantum openssh lib32-systemd steam neofetch gimp qbittorrent less curl wget python-pip playerctl xdotool wireguard-tools jq inkscape xorg-xwayland ydotool base-devel partitionmanager firefox timeshift systemd-resolvconf kde-gtk-config ntfs-3g duf --noconfirm

# Install paru
if ! command -v paru &> /dev/null
then
  git clone https://aur.archlinux.org/paru.git /tmp/paru
  cd /tmp/paru || exit
  makepkg -si

  cd "$HOME"
  rm -rf /tmp/paru
fi

# Install paru packages
paru -Suy --needed thorium-browser-bin visual-studio-code-bin mailspring nordvpn-bin spotify-launcher jellyfin-media-player kopia-ui-bin arduino-ide-bin whatsie gtk3-nocsd-git google-chrome minecraft-launcher teams-for-linux-bin ttf-ms-win10-cdn isoimagewriter --noconfirm --skipreview

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

sudo sed -i 's/elif artist is not None and title is not None:/elif artist is not None and title is not None and artist != "":/g' /etc/xdg/waybar/mediaplayer.py

# Spotify autostart minimized script
cat << EOF > "$HOME/.scripts/waybar-spotify.sh"
#!/bin/bash
spotify-launcher -- --uri="spotify:playlist:37i9dQZF1E35Ag8qP76jT0" &
while [[ ! \$(xdotool search --onlyvisible --name spotify) ]]; do :; done
xdotool search --onlyvisible --name spotify windowminimize
sleep 1
xdotool search --onlyvisible --name spotify windowminimize
EOF

sudo cp -f "$reposdir/arch-install/scripts/virt-desktop-checker.sh" "/etc/xdg/waybar/virt-desktop-checker.sh"

systemctl --user enable ydotool.service
systemctl --user start ydotool.service

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

# Set Dolphin state (mainly for visible panels)
cat << EOF > "$HOME/.local/share/dolphin/dolphinstaterc"
[SettingsDialog]
1280x800 screen: Height=521
1280x800 screen: Width=634

[State]
1280x800 screen: Window-Maximized=true
State=AAAA/wAAAAD9AAAAAwAAAAAAAAC0AAAClfwCAAAAAvsAAAAWAGYAbwBsAGQAZQByAHMARABvAGMAawAAAAAyAAABPgAAAFQA////+wAAABQAcABsAGEAYwBlAHMARABvAGMAawEAAAAyAAAClQAAAF4A////AAAAAQAAALQAAAKV/AIAAAAB+wAAABAAaQBuAGYAbwBEAG8AYwBrAAAAADIAAAKVAAAAhgD///8AAAADAAAFAAAAAMz8AQAAAAH7AAAAGAB0AGUAcgBtAGkAbgBhAGwARABvAGMAawAAAAAAAAAFAAAAAAIA////AAAESAAAApUAAAAEAAAABAAAAAgAAAAI/AAAAAEAAAACAAAAAQAAABYAbQBhAGkAbgBUAG8AbwBsAEIAYQByAQAAAAD/////AAAAAAAAAAA=
EOF

# Set sddm settings
mkdir -p /etc/sddm.conf.d
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

ssh-add "$HOME/.ssh/id_ed25519"

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

is_thinkpad=$( jq -r ".is_thinkpad" "$config_file" )
if [ $is_thinkpad == true ]
then
  echo "-------------------------------------------------"
  echo "-------------------CONFIGURE TLP-----------------"
  echo "-------------------------------------------------"

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

  paru -Sy --needed howdy-beta-git --noconfirm
  sudo cp -f "$dotfilesdir"/howdy.ini" "/etc/howdy/config.ini"

  wget https://github.com/EmixamPP/linux-enable-ir-emitter/releases/download/5.2.4/linux-enable-ir-emitter-5.2.4.systemd.x86-64.tar.gz -O /tmp/linux-enable-ir-emitter.tar.gz
  sudo tar -C / --no-same-owner -h -xzf /tmp/linux-enable-ir-emitter.tar.gz
  rm /tmp/linux-enable-ir-emitter.tar.gz

  # MANUALLY RUN
  # linux-enable-ir-emitter configure
  # linux-enable-ir-emitter run
  # linux-enable-ir-emitter boot

  # ADDED TO /etc/pam.d/sudo AND /etc/pam.d/kde AT THE TOP
  # auth sufficient pam_unix.so try_first_pass likeauth nullok
  # auth sufficient /lib/security/pam_howdy.so

fi

is_nvidia=$(lspci | grep -i nvidia | wc -l)

if [ $is_nvidia -gt 0 ]
then
  echo "-------------------------------------------------"
  echo "-----------------INSTALL NVIDIA------------------"
  echo "-------------------------------------------------"

  sudo pacman -Sy --needed linux-zen-headers nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings nvtop --noconfirm

  sudo sed -i 's/MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm /g' /etc/mkinitcpio.conf
  sudo sed -i 's/kms //g' /etc/mkinitcpio.conf

  sudo sed -i '/options/ s/$/ nvidia-drm.modeset=1/' /boot/loader/entries/*linux-zen.conf

  sudo bash -c "cat << EOF > /etc/pacman.d/hooks/nvidia.hook
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
fi

# Update initramfs
echo "-------------------------------------------------"
echo "-----------------UPDATE INITRAMFS----------------"
echo "-------------------------------------------------"

sudo mkinitcpio -P

# Setup smb client shares

echo "-------------------------------------------------"
echo "-----------------CONFIGURE SMB-------------------"
echo "-------------------------------------------------"

smb_n=$( jq -r ".smb.[].source" "$config_file" | wc -l )

i=0;
while [ $i -lt $smb_n ]
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

  mkdir -p "$smb_destination"

  sudo bash -c "cat << EOF > /etc/cifspasswd$i
username=$smb_username
password=$smb_password
EOF"

  sudo chmod 600 /etc/cifspasswd$i

  sudo bash -c "cat << EOF > /etc/systemd/system/$smb_name.mount
[Unit]
Description=$smb_description
RequiresMountsFor=/mnt
Requires=network-online.target wg-quick@wg0.service
After=network-online.target wg-quick@wg0.service

[Mount]
What=$smb_source
Where=$smb_destination
Type=cifs
Options=uid=me,gid=me,_netdev,nofail,credentials=/etc/cifspasswd$i
TimeoutSec=10
LazyUnmount=yes

[Install]
WantedBy=multi-user.target
EOF"

  sudo bash -c "cat << EOF > /etc/systemd/system/$smb_name.automount
[Unit]
Description=$smb_description

[Automount]
Where=$smb_destination
TimeoutIdleSec=60

[Install]
WantedBy=multi-user.target
EOF"

  sudo systemctl enable $smb_name.automount
  sudo systemctl start $smb_name.automount

  ((i=i+1))
done

#Install wine with lutris

install_wine=$( jq -r ".install_wine" "$config_file" )
if [ $install_wine == true ]
then
  echo "-------------------------------------------------"
  echo "-----------------INSTALL WINE--------------------"
  echo "-------------------------------------------------"

  sudo pacman -Sy --needed wine wine-mono wine-gecko winetricks lutris samba gnutls lib32-gnutls --noconfirm

  mkdir -p "${WINEPREFIX:-~/.wine}/drive_c/windows/Fonts"
  cd ${WINEPREFIX:-~/.wine}/drive_c/windows/Fonts && for i in /usr/share/fonts/**/*.{ttf,otf}; do ln -s "$i" >/dev/null 2>&1; done

  sudo bash -c "cat << EOF > /tmp/fontsmoothing.reg
REGEDIT4

[HKEY_CURRENT_USER\Control Panel\Desktop]
"FontSmoothing"="2"
"FontSmoothingOrientation"=dword:00000001
"FontSmoothingType"=dword:00000002
"FontSmoothingGamma"=dword:00000578
EOF"

  WINE=${WINE:-wine} WINEPREFIX=${WINEPREFIX:-$HOME/.wine} $WINE regedit /tmp/fontsmoothing.reg 2> /dev/null

  cd "$HOME"
  sudo rm -rf /tmp/fontsmoothing.reg

  paru -Sy wine-installer --noconfirm
fi

# Install ProtonGE for Steam

install_proton_ge=$( jq -r ".install_proton_ge" "$config_file" )

if [ $install_proton_ge == true ]
then
  echo "-------------------------------------------------"
  echo "----------------INSTALL PROTONGE-----------------"
  echo "-------------------------------------------------"

  mkdir -p "$HOME/.steam/root/compatibilitytools.d"

  wget https://github.com/GloriousEggroll/proton-ge-custom/releases/download/GE-Proton8-25/GE-Proton8-25.tar.gz -O /tmp/GE-Proton.tar.gz

  tar -xf /tmp/GE-Proton.tar.gz -C "$HOME/.steam/root/compatibilitytools.d"
  rm /tmp/GE-Proton.tar.gz
fi

# Apply customizations
echo "-------------------------------------------------"
echo "---------------APPLY CUSTOMIZATIONS--------------"
echo "-------------------------------------------------"

# Configure gtk apps to use gtk3-nocsd
gtk_apps=(net.lutris.Lutris.desktop)
for app in "${gtk_apps[@]}"
do
  [ ! -f "/usr/share/applications/$app" ] && continue
  
  cp /usr/share/applications/$app "$HOME/.local/share/applications/$app"
  sed -i 's/Exec=/Exec=\/usr\/bin\/gtk3-nocsd /g' "$HOME/.local/share/applications/$app"
done

# Configure MangoHud
mkdir -p "$HOME/.config/MangoHud"
cat << EOF > "$HOME/.config/MangoHud/MangoHud.conf"
fps_limit=120
font_size=26
position=top-left

cpu_stats
gpu_stats
arch
frame_timing

no_display
background_alpha=0.0
alpha=0.8
toggle_hud=KP_Subtract
toggle_logging=F2
reload_cfg=F4

gpu_color=ffffff
cpu_color=ffffff
engine_color=ffffff
frametime_color=ffffff
text_color=ffffff
EOF

# Create kopia startup script
cat << EOF > "$HOME/.config/autostart/kopia-ui.desktop"
[Desktop Entry]
Type=Application
Version=1.0
Name=kopia-ui
Comment=koipia-uistartup script
Exec=/opt/KopiaUI/kopia-ui
StartupNotify=false
Terminal=false
EOF

# Create Whatsie auto start script
cat << EOF > "$HOME/.config/autostart/whatsie.desktop"
[Desktop Entry]
Type=Application
Version=1.0
Name=whatsie
Comment=whatsie startup script
Exec=/usr/bin/whatsie %u
StartupWMClass=whatsie
StartupNotify=false
Terminal=false
EOF

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
  "/usr/share/applications/org.kde.kmenuedit.desktop"
  "/usr/share/applications/thorium-shell.desktop"
  "/usr/share/applications/cmake-gui.desktop"
  "/usr/share/applications/jconsole-java-openjdk.desktop"
  "/usr/share/applications/jshell-java-openjdk.desktop"
  "/usr/share/applications/nm-connection-editor.desktop"
  "/usr/share/applications/uxterm.desktop"
  "/usr/share/applications/nvtop.desktop"
  "/usr/share/applications/htop.desktop"
)

for desktop_file in "${application_desktop_files[@]}"
do
  [ ! -f "$desktop_file" ] && continue
  
  sudo bash -c "grep -q NoDisplay= $desktop_file && sed -i 's/NoDisplay=/NoDisplay=true/' $desktop_file || echo 'NoDisplay=true' >> $desktop_file"
done

sudo bash -c "cat << EOF > $HOME/.local/share/applications/spotify.desktop
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

# Add git folders 

echo "-------------------------------------------------"
echo "-----------------ADD GIT FOLDERS-----------------"
echo "-------------------------------------------------"

git_urls=$( jq -r ".git_urls.[]" "$config_file" )

while read -r git_url
do
  echo "$git_url"
  
  git_folder=$(basename "$git_url" .git)
  
  if [ ! -d "$reposdir/$git_folder" ]
  then
    git clone "$git_url" "$reposdir/$git_folder"
  else
    cd "$reposdir/$git_folder"
    git pull
    git rebase
  fi
done <<< "$git_urls"

# Customize application icons

echo "-------------------------------------------------"
echo "-----------------CUSTOMIZE ICONS-----------------"
echo "-------------------------------------------------"

# fix kopia tray icon

sudo cp -f "$current_dir/icons/kopia-tray.png" "/opt/KopiaUI/resources/icons/kopia-tray.png"
