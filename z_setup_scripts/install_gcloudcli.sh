#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_helpers.sh"
source "$SCRIPT_DIR/_config.sh"

install_gcloud() {
  if gcloud --version >/dev/null 2>&1; then
    print_info "GCloud is already installed ..."
  else
    print_info "Installing GCloud ..."

    cd "$DOTDIR" || handle_error "Failed to change directory to $DOTDIR"

    mkdir -p gcloud_cli ||
      handle_error "Failed to create temporary installation directory"
    cd gcloud_cli ||
      handle_error "Failed to change directory to temporary installation directory"

    rm -rf * ||
      handle_error "Failed to remove old installation files"

    curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86_64.tar.gz ||
      handle_error "Failed to download GCloud"

    tar -xf google-cloud-cli-linux-x86_64.tar.gz ||
      handle_error "Failed to extract GCloud"

    ./google-cloud-sdk/install.sh

    print_success "GCloud installed successfully."
  fi
}

install_gcloud
