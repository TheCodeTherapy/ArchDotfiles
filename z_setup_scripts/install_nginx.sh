#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_helpers.sh"
source "$SCRIPT_DIR/_config.sh"

CERT_DIR="/etc/nginx/ssl"
CERT_FILE="$CERT_DIR/localhost.pem"
KEY_FILE="$CERT_DIR/localhost-key.pem"

install_nginx() {
  if command -v nginx >/dev/null 2>&1; then
    print_info "Nginx is already installed ..."
  else
    print_info "Installing Nginx ..."
    sudo pacman -Sy --noconfirm nginx || handle_error "Failed to install Nginx"
    sudo mkdir -p /etc/nginx
    sudo cp /etc/mime.types /etc/nginx/mime.types
    print_success "Nginx installed successfully."
  fi

  if ! command -v mkcert >/dev/null 2>&1; then
    print_info "Installing mkcert and nss for Firefox trust ..."
    sudo pacman -Sy --noconfirm mkcert nss || handle_error "Failed to install mkcert"
    print_success "mkcert installed successfully."
  fi

  print_info "Installing local CA to system trust store ..."
  mkcert -install || handle_error "Failed to install mkcert local CA"

  if [[ -f "$CERT_FILE" && -f "$KEY_FILE" ]]; then
    print_info "Trusted mkcert certificate for localhost already exists."
  else
    print_info "Creating trusted certificate with mkcert for localhost ..."
    sudo mkdir -p "$CERT_DIR" || handle_error "Failed to create $CERT_DIR"
    TMP_CERT_DIR="$(mktemp -d)"
    mkcert -cert-file "$TMP_CERT_DIR/localhost.pem" -key-file "$TMP_CERT_DIR/localhost-key.pem" \
      localhost 127.0.0.1 ::1 || handle_error "mkcert failed to generate localhost cert"

    sudo mv "$TMP_CERT_DIR/localhost.pem" "$CERT_FILE" || handle_error "Failed to move cert"
    sudo mv "$TMP_CERT_DIR/localhost-key.pem" "$KEY_FILE" || handle_error "Failed to move key"

    rm -rf "$TMP_CERT_DIR"
    print_success "Trusted certificate created successfully with mkcert."
  fi

  # Arch doesn't use sites-available/sites-enabled by default
  if [[ -f /etc/nginx/nginx.conf ]]; then
    sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak ||
      handle_error "Failed to backup nginx.conf"
  fi

  # Assuming you have an Arch-compatible nginx.conf in $DOTDOT/etc/nginx.conf
  sudo cp "$DOTDOT/etc/nginx.conf" /etc/nginx/nginx.conf ||
    handle_error "Failed to copy nginx.conf"

  sudo nginx -t || handle_error "Failed to test nginx configuration"
  sudo systemctl enable nginx || handle_error "Failed to enable nginx service"
  sudo systemctl start nginx || handle_error "Failed to start nginx service"

  print_success "Nginx setup completed with mkcert TLS."
}

install_nginx
