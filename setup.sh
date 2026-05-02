
#!/usr/bin/env bash
# Eduard's Omarchy Setup Script
# Run this on a fresh EndeavourOS install to get everything set up.
set -e

# ── Broadcom WiFi fix ─────────────────────────────────────────────────────────
# broadcom-wl e deja instalat offline de EndeavourOS.
# Problema: omarchy activeaza iwd care nu merge cu broadcom-wl.
# Fix: blacklist module conflictuale + fortat wpa_supplicant ca backend.
fix_broadcom() {
  echo "==> Broadcom WiFi: fixing iwd conflict..."

  # Blacklist module care intra in conflict cu wl
  sudo tee /etc/modprobe.d/broadcom-blacklist.conf > /dev/null << 'EOF'
blacklist b43
blacklist b43legacy
blacklist bcma
blacklist ssb
blacklist brcmsmac
blacklist brcmfmac
EOF

  # Fortat NetworkManager sa foloseasca wpa_supplicant, nu iwd
  sudo mkdir -p /etc/NetworkManager/conf.d
  sudo tee /etc/NetworkManager/conf.d/wifi-backend.conf > /dev/null << 'EOF'
[device]
wifi.backend=wpa_supplicant
EOF

  # Dezactivat iwd, activat wpa_supplicant
  sudo systemctl disable --now iwd 2>/dev/null || true
  sudo systemctl enable --now wpa_supplicant 2>/dev/null || true
  sudo systemctl restart NetworkManager 2>/dev/null || true

  # Regenerat initramfs
  sudo mkinitcpio -P

  echo "  Broadcom fix aplicat. WiFi merge dupa reboot."
}

HAS_BROADCOM=false
lspci | grep -qi "broadcom.*network\|broadcom.*wireless\|BCM43\|802.11ac\|802.11" && HAS_BROADCOM=true


echo "==> Installing packages..."
sudo pacman -S --needed --noconfirm \
  quickshell \
  awww \
  swayosd \
  imagemagick \
  ffmpeg \
  python3

echo "==> Installing omarchy..."
curl -fsSL https://omarchy.com/install | bash

echo "==> Waiting for omarchy to finish..."
sleep 2

# Fix broadcom DUPA omarchy (omarchy poate activa iwd)
if $HAS_BROADCOM; then
  fix_broadcom
fi

# ── Hyprland autostart ────────────────────────────────────────────────────────
echo "==> Writing autostart.conf..."
cat > ~/.config/hypr/autostart.conf << 'EOF'
# Extra autostart processes
exec-once = awww-daemon
exec-once = uwsm-app -- swayosd-server
exec-once = awww img ~/.config/omarchy/current/background --transition-type none
exec-once = cp ~/.config/omarchy/current/background /tmp/lock_bg.png
exec-once = hypr-edge-workspace
exec-once = wl-paste --type text --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store
exec-once = screentime-daemon
exec-once = python3 ~/.config/hypr/scripts/quickshell/focustime/focus_daemon.py
exec-once = quickshell -p ~/.config/hypr/scripts/quickshell/Main.qml
EOF

# ── Keybindings ───────────────────────────────────────────────────────────────
echo "==> Writing bindings.conf..."
cat > ~/.config/hypr/bindings.conf << 'EOF'
# Application bindings
bindd = SUPER, RETURN, Terminal, exec, uwsm-app -- xdg-terminal-exec --dir="$(omarchy-cmd-terminal-cwd)"
bindd = SUPER ALT, RETURN, Tmux, exec, uwsm-app -- xdg-terminal-exec --dir="$(omarchy-cmd-terminal-cwd)" bash -c "tmux attach || tmux new -s Work"
bindd = SUPER SHIFT, RETURN, Browser, exec, omarchy-launch-browser
bindd = SUPER SHIFT, F, File manager, exec, uwsm-app -- nautilus --new-window
bindd = SUPER ALT SHIFT, F, File manager (cwd), exec, uwsm-app -- nautilus --new-window "$(omarchy-cmd-terminal-cwd)"
bindd = SUPER SHIFT, B, Browser, exec, omarchy-launch-browser
bindd = SUPER SHIFT ALT, B, Browser (private), exec, omarchy-launch-browser --private
bindd = SUPER SHIFT, M, Music, exec, omarchy-launch-or-focus spotify
bindd = SUPER SHIFT, N, Editor, exec, omarchy-launch-editor
bindd = SUPER SHIFT, D, Docker, exec, omarchy-launch-tui lazydocker
bindd = SUPER SHIFT, G, Signal, exec, omarchy-launch-or-focus ^signal$ "uwsm-app -- signal-desktop"
bindd = SUPER SHIFT, O, Obsidian, exec, omarchy-launch-or-focus ^obsidian$ "uwsm-app -- obsidian -disable-gpu --enable-wayland-ime"
bindd = SUPER SHIFT, W, Typora, exec, uwsm-app -- typora --enable-wayland-ime
bindd = SUPER SHIFT, SLASH, Passwords, exec, uwsm-app -- 1password

bindd = SUPER SHIFT, A, ChatGPT, exec, omarchy-launch-webapp "https://chatgpt.com"
bindd = SUPER SHIFT ALT, A, Grok, exec, omarchy-launch-webapp "https://grok.com"
bindd = SUPER SHIFT, C, Calendar, exec, omarchy-launch-webapp "https://app.hey.com/calendar/weeks/"
bindd = SUPER SHIFT, E, Email, exec, omarchy-launch-webapp "https://app.hey.com"
bindd = SUPER SHIFT, Y, YouTube, exec, omarchy-launch-webapp "https://youtube.com/"
bindd = SUPER SHIFT ALT, G, WhatsApp, exec, omarchy-launch-or-focus-webapp WhatsApp "https://web.whatsapp.com/"
bindd = SUPER SHIFT CTRL, G, Google Messages, exec, omarchy-launch-or-focus-webapp "Google Messages" "https://messages.google.com/web/conversations"
bindd = SUPER SHIFT, P, Google Photos, exec, omarchy-launch-or-focus-webapp "Google Photos" "https://photos.google.com/"
bindd = SUPER SHIFT, X, X, exec, omarchy-launch-webapp "https://x.com/"
bindd = SUPER SHIFT ALT, X, X Post, exec, omarchy-launch-webapp "https://x.com/compose/post"

# Screentime
bindd = SUPER ALT, S, Screentime, exec, screentime

# Clipboard
bindd = CTRL ALT, V, Clipboard history, exec, omarchy-launch-walker -m clipboard

# Quickshell widgets
bindd = SUPER ALT, W, Calendar & Weather, exec, bash ~/.config/hypr/scripts/qs_manager.sh toggle calendar
bindd = SUPER ALT, N, Network & Bluetooth, exec, bash ~/.config/hypr/scripts/qs_manager.sh toggle network
bindd = SUPER ALT, B, Battery, exec, bash ~/.config/hypr/scripts/qs_manager.sh toggle battery
bindd = SUPER ALT, V, Volume, exec, bash ~/.config/hypr/scripts/qs_manager.sh toggle volume
bindd = SUPER ALT, F, Focus Time, exec, bash ~/.config/hypr/scripts/qs_manager.sh toggle focustime
bindd = SUPER ALT, O, Monitors, exec, bash ~/.config/hypr/scripts/qs_manager.sh toggle monitors
bindd = SUPER ALT, C, Clipboard, exec, bash ~/.config/hypr/scripts/qs_manager.sh toggle clipboard
bindd = SUPER ALT, L, Lock Screen, exec, quickshell -p ~/.config/hypr/scripts/quickshell/Lock.qml
bindd = SUPER ALT, P, Wallpaper Picker, exec, bash ~/.config/hypr/scripts/qs_manager.sh toggle wallpaper

# Minimize/restore
bindd = SUPER, M, Minimize window, exec, hypr-minimize-toggle
bindd = SUPER ALT, M, Restore last minimized, exec, hypr-restore-all
EOF

# ── Waybar CSS ────────────────────────────────────────────────────────────────
echo "==> Writing waybar style.css..."
cat > ~/.config/waybar/style.css << 'EOF'
@import "../omarchy/current/theme/waybar.css";

* {
  background-color: transparent;
  color: @foreground;
  border: none;
  border-radius: 0;
  min-height: 0;
  font-family: 'JetBrainsMono Nerd Font';
  font-size: 12px;
}

window#waybar {
  background-color: @waybar_bg;
  border: none;
  border-radius: 14px;
  box-shadow: none;
}

.modules-left { margin-left: 6px; }
.modules-right { margin-right: 6px; }

#custom-omarchy {
  font-size: 15px;
  padding: 0 10px;
  margin: 3px 4px 3px 2px;
  border-radius: 10px;
  background-color: rgba(255,255,255,0.07);
  transition: background-color 0.2s ease;
}
#custom-omarchy:hover { background-color: rgba(255,255,255,0.14); }

#workspaces button {
  all: initial;
  color: rgba(255,255,255,0.3);
  font-size: 12px;
  padding: 0 7px;
  margin: 4px 1px;
  min-width: 8px;
  border-radius: 8px;
  transition: all 0.15s ease;
}
#workspaces button.active {
  color: #ffffff;
  background-color: rgba(255,255,255,0.15);
  font-weight: bold;
}
#workspaces button.urgent { color: @accent_orange; }
#workspaces button.empty { opacity: 0.2; }
#workspaces button:hover {
  color: rgba(255,255,255,0.75);
  background-color: rgba(255,255,255,0.07);
}

#taskbar { margin: 0 2px; }
#taskbar button, #taskbar button * {
  background-color: transparent;
  background-image: none;
  box-shadow: none;
}
#taskbar button {
  padding: 3px 6px 3px 10px;
  margin: 0 1px;
  min-width: 20px;
  border: none;
  border-bottom: 2px solid transparent;
  border-radius: 0;
  font-size: 0;
  transition: all 0.15s ease;
}
#taskbar button:hover {
  background-color: rgba(255,255,255,0.06);
  border-bottom-color: rgba(255,255,255,0.3);
}
#taskbar button.active {
  background-color: rgba(255,255,255,0.1);
  border-bottom-color: @accent_orange;
}

#clock {
  color: @foreground;
  font-weight: bold;
  letter-spacing: 0.5px;
  padding: 0 14px;
  margin: 4px 4px 4px 8px;
  border-radius: 10px;
  background-color: rgba(255,255,255,0.08);
}

#cpu, #memory {
  padding: 0 9px;
  margin: 4px 1px;
  border-radius: 10px;
  color: @foreground;
  opacity: 0.8;
  background-color: rgba(255,255,255,0.04);
  transition: all 0.2s ease;
}
#cpu:hover, #memory:hover {
  color: @foreground;
  opacity: 1;
  background-color: rgba(255,255,255,0.09);
}
#memory.warning { color: #e0b040; }
#memory.critical { color: @accent_critical; }

#battery, #network, #pulseaudio, #bluetooth {
  padding: 0 9px;
  margin: 4px 1px;
  border-radius: 10px;
  background-color: rgba(255,255,255,0.04);
  transition: all 0.2s ease;
}
#battery:hover, #network:hover, #pulseaudio:hover, #bluetooth:hover {
  background-color: rgba(255,255,255,0.09);
}
#battery { color: @foreground; opacity: 0.8; margin-right: 3px; }
#battery.warning { color: #e0b040; background-color: rgba(224,176,64,0.08); opacity: 1; }
#battery.critical {
  color: @accent_critical;
  background-color: rgba(230,92,92,0.12);
  animation: blink 1.2s ease infinite;
  opacity: 1;
}
#network { color: @foreground; opacity: 0.8; }
#pulseaudio { color: @foreground; opacity: 0.8; }
#pulseaudio.muted { color: @foreground; opacity: 0.35; }
#bluetooth { color: @foreground; opacity: 0.8; }

#custom-update {
  font-size: 10px;
  color: @accent_orange;
  padding: 0 8px;
  margin: 4px 2px;
  border-radius: 10px;
  background-color: rgba(230,92,92,0.1);
}

#custom-screenrecording-indicator,
#custom-idle-indicator,
#custom-notification-silencing-indicator {
  min-width: 10px;
  margin: 4px 1px;
  font-size: 10px;
  padding: 0 3px;
  color: rgba(255,255,255,0.3);
}
#custom-screenrecording-indicator.active,
#custom-idle-indicator.active,
#custom-notification-silencing-indicator.active { color: @accent_critical; }

#custom-voxtype { min-width: 10px; padding: 0 8px; margin: 4px 2px; border-radius: 10px; }
#custom-voxtype.recording { color: @accent_critical; background-color: rgba(230,92,92,0.12); }

#custom-expand-icon { color: rgba(255,255,255,0.28); margin-right: 4px; transition: color 0.2s ease; }
#custom-expand-icon:hover { color: rgba(255,255,255,0.65); }

#tray { margin-right: 8px; }
#tray > .needs-attention { -gtk-icon-effect: highlight; background-color: rgba(230,92,92,0.15); border-radius: 10px; }

.hidden { opacity: 0; min-width: 0; padding: 0; margin: 0; }

@keyframes blink {
  0%   { opacity: 1; }
  50%  { opacity: 0.4; }
  100% { opacity: 1; }
}

#backlight {
  padding: 0 9px;
  margin: 4px 1px;
  border-radius: 10px;
  color: @foreground;
  opacity: 0.8;
  background-color: rgba(255,255,255,0.04);
  transition: all 0.2s ease;
}
#backlight:hover {
  color: @foreground;
  opacity: 1;
  background-color: rgba(255,255,255,0.09);
}
EOF

# ── Theme hook ────────────────────────────────────────────────────────────────
echo "==> Writing theme-set hook..."
mkdir -p ~/.config/omarchy/hooks
cat > ~/.config/omarchy/hooks/theme-set << 'EOF'
#!/bin/bash
THEME="$1"

~/.config/hypr/scripts/quickshell/update_qs_colors.sh "$THEME" &
~/.config/hypr/scripts/quickshell/update_waybar_colors.sh "$THEME" &
~/.config/hypr/scripts/quickshell/update_trae_theme.sh "$THEME" &
~/.config/hypr/scripts/quickshell/update_vscode_theme.sh "$THEME" &
~/.config/hypr/scripts/quickshell/update_cava_colors.sh "$THEME" &
wait

pkill -SIGUSR2 waybar 2>/dev/null
killall -USR1 quickshell 2>/dev/null
EOF
chmod +x ~/.config/omarchy/hooks/theme-set

# ── Theme scripts ─────────────────────────────────────────────────────────────
echo "==> Writing theme color scripts..."
mkdir -p ~/.config/hypr/scripts/quickshell

cat > ~/.config/hypr/scripts/quickshell/update_qs_colors.sh << 'SCRIPT'
#!/bin/bash
THEME="${1:-$(cat ~/.config/omarchy/current/theme.name)}"
QS_COLORS="$HOME/.config/hypr/scripts/quickshell/qs_colors.json"

case "$THEME" in
  gruvbox)
    cat > "$QS_COLORS" << 'EOF'
{"base":"#302d28","mantle":"#282828","crust":"#1d1b18","text":"#ebdbb2","subtext0":"#d5c4a1","subtext1":"#bdae93","surface0":"#3c3735","surface1":"#504945","surface2":"#665c54","overlay0":"#7a7267","overlay1":"#8f8680","overlay2":"#a39a8f","blue":"#83a598","sapphire":"#7fa2c9","peach":"#fe8019","green":"#b8bb26","red":"#cc241d","mauve":"#d3869b","pink":"#d3869b","yellow":"#fabd2f","maroon":"#a61f12","teal":"#689d6a"}
EOF
    ;;
  everforest)
    cat > "$QS_COLORS" << 'EOF'
{"base":"#31383d","mantle":"#2d353b","crust":"#272e33","text":"#d3c6aa","subtext0":"#b9a98e","subtext1":"#9f9078","surface0":"#3d4449","surface1":"#4a5157","surface2":"#575e65","overlay0":"#636b72","overlay1":"#717880","overlay2":"#7f868e","blue":"#7fbbb3","sapphire":"#83c092","peach":"#dbbc7f","green":"#a7c080","red":"#e67e80","mauve":"#d699b6","pink":"#d699b6","yellow":"#dbbc7f","maroon":"#e67e80","teal":"#83c092"}
EOF
    ;;
  ethereal)
    cat > "$QS_COLORS" << 'EOF'
{"base":"#060B1E","mantle":"#0a1020","crust":"#030612","text":"#ffcead","subtext0":"#e8b898","subtext1":"#d1a382","surface0":"#0f1830","surface1":"#182040","surface2":"#212850","overlay0":"#2a3060","overlay1":"#363c70","overlay2":"#424880","blue":"#7d82d9","sapphire":"#a3bfd1","peach":"#F99957","green":"#92a593","red":"#ED5B5A","mauve":"#c89dc1","pink":"#ead7e7","yellow":"#E9BB4F","maroon":"#faaaa9","teal":"#a3bfd1"}
EOF
    ;;
  city-783)
    cat > "$QS_COLORS" << 'EOF'
{"base":"#181a1f","mantle":"#0f1115","crust":"#0a0c10","text":"#b9bec6","subtext0":"#99a0a8","subtext1":"#7a8290","surface0":"#242a32","surface1":"#2e3540","surface2":"#38404c","overlay0":"#424a56","overlay1":"#4c5460","overlay2":"#565e6a","blue":"#8f949c","sapphire":"#9da4ac","peach":"#ad2222","green":"#d12b2b","red":"#b31414","mauve":"#c3c8d0","pink":"#ad2222","yellow":"#9e1a1a","maroon":"#7a0f0f","teal":"#8f949c"}
EOF
    ;;
  harbordark)
    cat > "$QS_COLORS" << 'EOF'
{"base":"#1B1B1B","mantle":"#141414","crust":"#0d0d0d","text":"#efebdc","subtext0":"#d5cfc4","subtext1":"#bbb5aa","surface0":"#272727","surface1":"#353535","surface2":"#434343","overlay0":"#515151","overlay1":"#5f5f5f","overlay2":"#6d6d6d","blue":"#77838a","sapphire":"#8a96a0","peach":"#e75a50","green":"#d12b2b","red":"#F44336","mauve":"#e58980","pink":"#e75a50","yellow":"#a99b7a","maroon":"#c41c3e","teal":"#6d6d6d"}
EOF
    ;;
  hinterlands)
    cat > "$QS_COLORS" << 'EOF'
{"base":"#222222","mantle":"#1a1a1a","crust":"#101010","text":"#ffffff","subtext0":"#d0d0d0","subtext1":"#a0a0a0","surface0":"#2e2e2e","surface1":"#3c3c3c","surface2":"#4a4a4a","overlay0":"#585858","overlay1":"#666666","overlay2":"#747474","blue":"#868686","sapphire":"#949494","peach":"#a0a0a0","green":"#8b8b8b","red":"#7c7c7c","mauve":"#b9b9b9","pink":"#a0a0a0","yellow":"#686868","maroon":"#525252","teal":"#747474"}
EOF
    ;;
  ash|black_arch|black-white|dark-white-minimal)
    cat > "$QS_COLORS" << 'EOF'
{"base":"#141414","mantle":"#0f0f0f","crust":"#0a0a0a","text":"#f5f5f5","subtext0":"#c0c0c0","subtext1":"#909090","surface0":"#2a2a2a","surface1":"#383838","surface2":"#484848","overlay0":"#606060","overlay1":"#787878","overlay2":"#989898","blue":"#ffffff","sapphire":"#e8e8e8","peach":"#f0f0f0","green":"#d0d0d0","red":"#e06060","mauve":"#ffffff","pink":"#f0f0f0","yellow":"#e8e8e8","maroon":"#c04040","teal":"#e0e0e0"}
EOF
    ;;
  *) echo "Unknown theme: $THEME" >&2; exit 1 ;;
esac
echo "Updated quickshell colors for theme: $THEME"
SCRIPT
chmod +x ~/.config/hypr/scripts/quickshell/update_qs_colors.sh

cat > ~/.config/hypr/scripts/quickshell/update_waybar_colors.sh << 'SCRIPT'
#!/bin/bash
THEME="${1:-$(cat ~/.config/omarchy/current/theme.name)}"
WAYBAR_CSS="$HOME/.config/omarchy/current/theme/waybar.css"

case "$THEME" in
  gruvbox)
    printf '@define-color foreground #c7b28e;\n@define-color background #282828;\n@define-color waybar_bg #302d28;\n@define-color accent_orange #fe8019;\n@define-color accent_green #b8bb26;\n@define-color accent_critical #cc241d;\n' > "$WAYBAR_CSS" ;;
  everforest)
    printf '@define-color foreground #7fba8e;\n@define-color background #2d353b;\n@define-color waybar_bg #31383d;\n@define-color accent_orange #7fba8e;\n@define-color accent_green #a7c080;\n@define-color accent_critical #e67e80;\n' > "$WAYBAR_CSS" ;;
  ethereal)
    printf '@define-color foreground #ffcead;\n@define-color background #060B1E;\n@define-color waybar_bg #0f1830;\n@define-color accent_orange #F99957;\n@define-color accent_green #92a593;\n@define-color accent_critical #ED5B5A;\n' > "$WAYBAR_CSS" ;;
  city-783)
    printf '@define-color foreground #b9bec6;\n@define-color background #181a1f;\n@define-color waybar_bg #242a32;\n@define-color accent_orange #ad2222;\n@define-color accent_green #d12b2b;\n@define-color accent_critical #b31414;\n' > "$WAYBAR_CSS" ;;
  harbordark)
    printf '@define-color foreground #efebdc;\n@define-color background #1B1B1B;\n@define-color waybar_bg #272727;\n@define-color accent_orange #e75a50;\n@define-color accent_green #d12b2b;\n@define-color accent_critical #F44336;\n' > "$WAYBAR_CSS" ;;
  hinterlands)
    printf '@define-color foreground #ffffff;\n@define-color background #222222;\n@define-color waybar_bg #2e2e2e;\n@define-color accent_orange #a0a0a0;\n@define-color accent_green #8b8b8b;\n@define-color accent_critical #7c7c7c;\n' > "$WAYBAR_CSS" ;;
  ash|black_arch|black-white|dark-white-minimal)
    printf '@define-color foreground #ffffff;\n@define-color background #000000;\n@define-color waybar_bg #0a0a0a;\n@define-color accent_orange #e65c5c;\n@define-color accent_green #9ece6a;\n@define-color accent_critical #e65c5c;\n' > "$WAYBAR_CSS" ;;
  *) echo "Unknown theme: $THEME" >&2; exit 1 ;;
esac
echo "Updated waybar colors for theme: $THEME"
SCRIPT
chmod +x ~/.config/hypr/scripts/quickshell/update_waybar_colors.sh

cat > ~/.config/hypr/scripts/quickshell/update_cava_colors.sh << 'SCRIPT'
#!/bin/bash
THEME="${1:-$(cat ~/.config/omarchy/current/theme.name)}"
CAVA_CONFIG="$HOME/.config/cava/config"
[ -f "$CAVA_CONFIG" ] || exit 0

case "$THEME" in
  gruvbox)             FG="#fe8019"; BG="#282828" ;;
  everforest)          FG="#a7c080"; BG="#2d353b" ;;
  ethereal)            FG="#7d82d9"; BG="#060B1E" ;;
  city-783)            FG="#ad2222"; BG="#181a1f" ;;
  harbordark)          FG="#e75a50"; BG="#1B1B1B" ;;
  hinterlands)         FG="#a0a0a0"; BG="#222222" ;;
  ash|black_arch|black-white|dark-white-minimal) FG="#e65c5c"; BG="#000000" ;;
  *) exit 0 ;;
esac

sed -i \
  -e "s|^[; ]*foreground = .*|foreground = '${FG}'|" \
  -e "s|^[; ]*background = .*|background = '${BG}'|" \
  "$CAVA_CONFIG"

grep -q "^foreground" "$CAVA_CONFIG" || sed -i "/^\[color\]/a foreground = '${FG}'" "$CAVA_CONFIG"
grep -q "^background" "$CAVA_CONFIG" || sed -i "/^\[color\]/a background = '${BG}'" "$CAVA_CONFIG"

pkill -USR2 cava 2>/dev/null || true
SCRIPT
chmod +x ~/.config/hypr/scripts/quickshell/update_cava_colors.sh

cat > ~/.config/hypr/scripts/quickshell/update_trae_theme.sh << 'SCRIPT'
#!/bin/bash
THEME="${1:-$(cat ~/.config/omarchy/current/theme.name)}"
TRAE_SETTINGS="$HOME/.config/Trae/User/settings.json"

case "$THEME" in
  gruvbox)    TRAE_THEME="Gruvbox Material Dark" ;;
  everforest) TRAE_THEME="Everforest Dark" ;;
  *)          TRAE_THEME="Vantablack Material Dark" ;;
esac

[ -f "$TRAE_SETTINGS" ] || exit 0
python3 -c "
import json
with open('$TRAE_SETTINGS') as f: s = json.load(f)
s['workbench.colorTheme'] = '$TRAE_THEME'
s.pop('workbench.iconTheme', None)
with open('$TRAE_SETTINGS', 'w') as f: json.dump(s, f, indent=2)
print('Updated Trae theme to: $TRAE_THEME')
"
SCRIPT
chmod +x ~/.config/hypr/scripts/quickshell/update_trae_theme.sh

# ── Patch omarchy bg scripts to use awww ─────────────────────────────────────
echo "==> Patching omarchy-theme-bg-set and omarchy-theme-bg-next to use awww..."

cat > ~/.local/share/omarchy/bin/omarchy-theme-bg-set << 'EOF'
#!/bin/bash
if [[ -z $1 ]]; then echo "Usage: omarchy-theme-bg-set <path>" >&2; exit 1; fi
CURRENT_BACKGROUND_LINK="$HOME/.config/omarchy/current/background"
ln -nsf "$1" "$CURRENT_BACKGROUND_LINK"
pkill -x swaybg 2>/dev/null || true
awww img "$CURRENT_BACKGROUND_LINK" --transition-type fade --transition-duration 1 >/dev/null 2>&1 &
EOF
chmod +x ~/.local/share/omarchy/bin/omarchy-theme-bg-set

# Patch only the swaybg lines in omarchy-theme-bg-next
sed -i \
  -e 's|pkill -x swaybg$|pkill -x swaybg 2>/dev/null \|\| true|g' \
  -e 's|setsid uwsm-app -- swaybg -i "\$CURRENT_BACKGROUND_LINK" -m fill.*|awww img "$CURRENT_BACKGROUND_LINK" --transition-type fade --transition-duration 1 >/dev/null 2>\&1 \&|g' \
  -e '/setsid uwsm-app -- swaybg --color/d' \
  ~/.local/share/omarchy/bin/omarchy-theme-bg-next

# ── Wallpapers ────────────────────────────────────────────────────────────────
echo "==> Copying omarchy wallpapers to ~/Pictures/Wallpapers..."
mkdir -p ~/Pictures/Wallpapers
find ~/.config/omarchy/themes ~/.local/share/omarchy/themes \
  -path "*/backgrounds/*" -type f ! -name "thumbnail.png" \
  -exec cp -n {} ~/Pictures/Wallpapers/ \; 2>/dev/null || true
find ~/.config/omarchy/current/theme/backgrounds -type f \
  -exec cp -n {} ~/Pictures/Wallpapers/ \; 2>/dev/null || true
echo "  Copied $(ls ~/Pictures/Wallpapers | wc -l) wallpapers."

# ── Apply current theme colors ────────────────────────────────────────────────
CURRENT_THEME=$(cat ~/.config/omarchy/current/theme.name 2>/dev/null || echo "gruvbox")
echo "==> Applying colors for theme: $CURRENT_THEME"
bash ~/.config/hypr/scripts/quickshell/update_qs_colors.sh "$CURRENT_THEME" 2>/dev/null || true
bash ~/.config/hypr/scripts/quickshell/update_waybar_colors.sh "$CURRENT_THEME" 2>/dev/null || true
bash ~/.config/hypr/scripts/quickshell/update_cava_colors.sh "$CURRENT_THEME" 2>/dev/null || true

echo ""
echo "✓ Done! Log out and back in (or reboot) to apply everything."
echo ""
echo "Supported themes with full colors:"
echo "  gruvbox, everforest, ethereal, city-783, harbordark, hinterlands, ash, black_arch"
