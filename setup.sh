#!/bin/bash

source "$(dirname "$0")/z_setup_scripts/_helpers.sh"
source "$(dirname "$0")/z_setup_scripts/_config.sh"

# Update the system ==========================================================
update_arch() {
  print_info "Updating Arch Linux ..."

  sudo pacman -Syu --noconfirm ||
    handle_error "Failed to update Arch Linux."
  print_success "Arch Linux updated successfully."

  print_info "Cleaning up old packages ..."
  orphans=$(pacman -Qdtq)
  if [[ -n "$orphans" ]]; then
    sudo pacman -Rns --noconfirm $orphans ||
      handle_error "Failed to clean up old packages."
    print_success "Old packages cleaned up successfully."
  else
    print_success "No orphaned packages to remove."
  fi

  print_info "Cleaning up package cache ..."
  sudo pacman -Sc --noconfirm ||
    handle_error "Failed to clean up package cache."
  print_success "Package cache cleaned up successfully."

  print_info "Cleaning up old package databases ..."
  sudo pacman -Scc --noconfirm ||
    handle_error "Failed to clean up old package databases."
  print_success "Old package databases cleaned up successfully."

  print_info "Cleaning up old package logs ..."
  sudo journalctl --vacuum-time=7d ||
    handle_error "Failed to clean up old package logs."
}
# ============================================================================

# Install git ================================================================
install_git() {
  print_info "Installing git ..."
  if ! sudo pacman -S --noconfirm --needed git git-lfs; then
    handle_error "Failed to install git."
  else
    print_success "git installed successfully."
  fi
  git lfs install || handle_error "Failed to install git-lfs."
  git config --global user.name "TheCodeTherapy" ||
    handle_error "Failed to set git user name."
  git config --global user.email "me@mgz.me" ||
    handle_error "Failed to set git user email."
}
# ============================================================================

# Enable pacman autocomplete =================================================
enable_pacman_autocomplete() {
  if ! pacman -Q bash-completion &>/dev/null; then
    print_info "Installing bash-completion ..."
    sudo pacman -S --noconfirm bash-completion ||
      handle_error "Failed to install bash-completion."
    print_success "bash-completion installed successfully."
  else
    print_success "bash-completion is already installed."
  fi

  if ! grep -q 'bash-completion' "$HOME/.bashrc"; then
    print_info "Enabling bash-completion ..."
    echo '[[ -r /usr/share/bash-completion/bash_completion ]] && . /usr/share/bash-completion/bash_completion' >>"$HOME/.bashrc" ||
      handle_error "Failed to enable bash-completion."
    print_success "bash-completion enabled successfully."
  else
    print_success "bash-completion is already enabled."
  fi
}
# ============================================================================

# Install yay ================================================================
install_yay() {
  print_info "Installing yay ..."

  sudo pacman -S --needed base-devel ||
    handle_error "Failed to install base-devel."

  cd "$HOME" || handle_error "Failed to change directory to home."

  if [ -d yay ]; then
    print_info "yay already exists, skipping clone."

    cd yay || handle_error "Failed to change directory to yay."
    git pull || handle_error "Failed to pull latest changes."
  else
    print_info "Cloning yay repository ..."

    git clone https://aur.archlinux.org/yay.git ||
      handle_error "Failed to clone yay repository."
    cd yay || handle_error "Failed to change directory to yay."
  fi

  makepkg -si --noconfirm --needed ||
    handle_error "Failed to build and install yay."

  cd "$HOME" || handle_error "Failed to change directory to home."

  if [ -d yay ]; then
    print_info "Removing yay directory ..."
    rm -rf yay || handle_error "Failed to remove yay directory."
  fi

  print_success "yay installation complete."
}
# ============================================================================

# Install yay packages =======================================================
install_yay_packages() {
  local packages=(
    visual-studio-code-bin brave-bin google-chrome qt6ct-kde
    hid-fanatecff-dkms oversteer raysession
  )

  print_info "Installing yay packages ..."
  for package in "${packages[@]}"; do
    install_with_yay "$package"
  done
  print_info "Yay packages installation complete."

  print_info "Cleaning up yay cache ..."
  yay -Sc --noconfirm ||
    handle_error "Failed to clean up yay cache."
  
  print_info "Cleaning up yay old package databases ..."
  yay -Scc --noconfirm ||
    handle_error "Failed to clean up yay old package databases."

  print_info "Cleaning up yay orphaned packages ..."
  orphans=$(yay -Qdtq)
  if [[ -n "$orphans" ]]; then
    yay -Rns $orphans --noconfirm ||
      handle_error "Failed to clean up yay orphaned packages."
    print_success "Yay orphaned packages cleaned up successfully."
  else
    print_success "No yay orphaned packages to remove."
  fi

  print_success "Yay cache cleaned up successfully."
}
# ============================================================================

# Install base packages ======================================================
install_base_packages() {
  local packages=(
    base-devel git git-lfs llvm autoconf automake cmake ninja gettext make
    meson clang gcc nasm dkms curl wget ca-certificates gnupg most neovim
    lsb-release gawk zsh tmux most tree tar jq unzip ffmpeg bc fzf ripgrep
    zsh zsh-completions zsh-syntax-highlighting zsh-autosuggestions neofetch
    ghostty alacritty xdg-desktop-portal-hyprland xdg-desktop-portal kvantum
    kvantum-qt5 kvantum-theme-materia adw-gtk-theme qt5ct qt5-wayland fd gtk3
    pkgconf qt6-wayland breeze breeze-icons openal ttf-hack waybar python
    python-pip ipython libtool python-pynvim bzip2 zlib plocate wl-clipboard
    sdl sdl2 fluidsynth timidity++ mesa glu glew mpg123 noto-fonts-emoji btop
    libjpeg-turbo libgme libsndfile libvpx flatpak cloudflared github-cli
    docker docker-compose nvidia-container-toolkit ffmpeg yt-dlp firefox
    discord v4l2loopback-dkms obs-studio ardour swww
  )

  for package in "${packages[@]}"; do
    install_with_pacman "$package"
  done
}
# ============================================================================

# Install Wine (Wayland + PipeWire) ==========================================
install_wine() {
  print_info "Installing Wine (Wayland + PipeWire)..."

  if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    handle_error "Multilib not enabled. Edit /etc/pacman.conf and uncomment [multilib]."
  fi

  local packages=(
    wine wine-mono wine-gecko winetricks libpulse lib32-libpulse
    lib32-alsa-lib lib32-openal lib32-mesa lib32-vulkan-icd-loader
    lib32-libx11 lib32-libxcomposite lib32-libxrandr lib32-libxinerama
    lib32-libxcursor lib32-libxi lib32-libxfixes lib32-libxrender
    lib32-libxdamage lib32-freetype2 lib32-libjpeg-turbo lib32-gnutls
    lib32-libldap lib32-libxml2 lib32-giflib lib32-libpng lib32-sdl2
    lib32-ncurses lib32-zlib
  )

  local optional_packages=(
    lib32-alsa-plugins lib32-libcups lib32-fluidsynth lib32-gst-plugins-base
    lib32-gst-plugins-good lib32-v4l-utils lib32-pipewire lib32-libdecor
    lib32-pipewire-jack
  )

  print_info "Installing required and optional Wine dependencies..."
  if ! sudo pacman -S --needed --noconfirm "${packages[@]}" "${optional_packages[@]}"; then
    handle_error "Failed to install Wine or its dependencies."
  fi

  print_info "Restarting systemd-binfmt for .exe support..."
  sudo systemctl restart systemd-binfmt || handle_error "Failed to restart systemd-binfmt"

  print_success "Wine installation complete."
}
# ============================================================================

# Update fonts cache =========================================================
update_fonts_cache() {
  print_info "Updating fonts cache ..."
  fc-cache -f || handle_error "Failed to update font cache."
}
# ============================================================================

# Link dotfiles ==============================================================
link_dotfiles() {
  local target_home="$HOME"
  local target_config="$HOME/.config"
  local target_local_share="$HOME/.local/share"

  mkdir -p "$target_config/Code/User"
  mkdir -p "$target_config/VSCodium/User"
  mkdir -p "$target_config/hypr"
  mkdir -p "$target_config/kitty"
  mkdir -p "$target_config/gtk-3.0"
  mkdir -p "$target_config/gtk-4.0"
  
  declare -A files_to_link=(
    ["${DOTDOT}/bash/bashrc"]="$target_home/.bashrc"
    ["${DOTDOT}/bash/inputrc"]="$target_home/.inputrc"
    ["${DOTDOT}/profile/profile"]="$target_home/.profile"
    ["${DOTDOT}/zsh/zshrc"]="$target_home/.zshrc"
    ["${DOTDOT}/zsh/zshenv"]="$target_home/.zshenv"
    ["${DOTDOT}/zsh/p10k.zsh"]="$target_home/.p10k.zsh"
    ["${DOTDOT}/tmux/tmux.conf"]="$target_home/.tmux.conf"
    ["${DOTDOT}/fonts"]="$target_home/.fonts"
    ["${DOTDOT}/vst3"]="$target_home/.vst3"
    ["${DOTDOT}/hypr/hyprland.conf"]="$target_config/hypr/hyprland.conf"
    ["${DOTDOT}/kitty/kitty.conf"]="$target_config/kitty/kitty.conf"
    ["${DOTDOT}/vscode/settings.json"]="$target_config/Code/User/settings.json"
    ["${DOTDOT}/vscodium/settings.json"]="$target_config/VSCodium/User/settings.json"
    ["${DOTDOT}/pipewire"]="$target_config/pipewire"
    ["${DOTDOT}/wireplumber"]="$target_config/wireplumber"
    ["${DOTDOT}/gtk-3.0/settings.ini"]="$target_config/gtk-3.0/settings.ini"
    ["${DOTDOT}/gtk-4.0/settings.ini"]="$target_config/gtk-4.0/settings.ini"
    ["${DOTDOT}/environment.d"]="$target_config/environment.d"
    ["${DOTDOT}/qt5ct"]="$target_config/qt5ct"
    ["${DOTDOT}/qt6ct"]="$target_config/qt6ct"
    ["${DOTDOT}/waybar"]="$target_config/waybar"
    ["${DOTDOT}/nvim"]="$target_config/nvim"
    ["${DOTDOT}/alacritty"]="$target_config/alacritty"
    ["${DOTDOT}/ghostty"]="$target_config/ghostty"
    ["${DOTDOT}/local/share/ghostty"]="$target_local_share/ghostty"
    ["${DOTDOT}/local/share/applications"]="$target_local_share/applications"
    ["${DOTDOT}/scummvm"]="$target_config/scummvm"
    ["${DOTDOT}/mame"]="$target_home/.mame"
    ["${DOTDOT}/darkplaces"]="$target_home/.darkplaces"
    ["${DOTDOT}/neofetch"]="$target_config/neofetch"
  )

  for source_file in "${!files_to_link[@]}"; do
    local target_file="${files_to_link[$source_file]}"
    link_file "$source_file" "$target_file"
  done
}
# ============================================================================

install_recipes() {
  local recipe_dir
  recipe_dir="${DOTFILES}/z_setup_scripts"

  local recipes=(
    "$recipe_dir/install_oh-my-zsh.sh"
    "$recipe_dir/install_powerlevel10k.sh"
    "$recipe_dir/install_nvm.sh"
    "$recipe_dir/install_node.sh"
    "$recipe_dir/install_golang.sh"
    "$recipe_dir/install_rust.sh"
    "$recipe_dir/install_exa.sh"
    "$recipe_dir/install_lazygit.sh"
    "$recipe_dir/install_emscripten.sh"
    "$recipe_dir/install_nginx.sh"
    "$recipe_dir/install_tmuxpm.sh"
  )

  for recipe in "${recipes[@]}"; do
    if [ -f "$recipe" ]; then
      print_info "Running recipe: $(basename "$recipe")"
      # shellcheck source=/dev/null
      source "$recipe" || handle_error "Failed to execute recipe: $(basename "$recipe")"
    else
      print_warning "Recipe not found: $(basename "$recipe")"
    fi
  done
}

install_flatpak_packages() {
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

  if [[ -d $HOME/.var/app/com.valvesoftware.Steam ]]; then
    print_info "Steam is already installed ..."
  else
    print_info "Installing Steam ..."
    flatpak install -y flathub com.valvesoftware.Steam
    mkdir -p "$HOME/.var/app/com.valvesoftware.Steam"
  fi

  if [[ -d $HOME/.var/app/net.davidotek.pupgui2 ]]; then
    print_info "ProtonUp-Qt is already installed ..."
  else
    print_info "Installing ProtonUp-Qt ..."
    flatpak install -y flathub net.davidotek.pupgui2
    mkdir -p "$HOME/.var/app/net.davidotek.pupgui2"
  fi

  if [[ -d $HOME/.var/app/com.github.Matoking.protontricks ]]; then
    print_info "ProtonTricks is already installed ..."
  else
    print_info "Installing ProtonTricks ..."
    flatpak install -y flathub com.github.Matoking.protontricks
    mkdir -p "$HOME/.var/app/com.github.Matoking.protontricks"
  fi

  if [[ -d $HOME/.var/app/com.slack.Slack ]]; then
    print_info "Slack is already installed ..."
  else
    print_info "Installing Slack ..."
    flatpak install -y flathub com.slack.Slack
    mkdir -p "$HOME/.var/app/com.slack.Slack"
  fi
}

update_plocate_db() {
  print_info "Updating plocate database ..."
  sudo updatedb || handle_error "Failed to update the file database."
}

update_arch
install_git
install_yay

install_base_packages
install_yay_packages
install_wine
install_recipes

install_flatpak_packages

enable_pacman_autocomplete
link_dotfiles

update_fonts_cache
update_plocate_db
systemctl --user import-environment PATH
hyprctl reload
