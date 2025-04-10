#!/bin/bash

# Define configuration variables
ME="/home/$(whoami)"
export ME
export DOTDIR="${ME}/ArchDotfiles"
export DOTDOT="${DOTDIR}/dotfiles"

export BINDIR="${DOTDIR}/bin"
export SCRIPTS="${DOTDIR}/scripts"
export SETUPSCRIPTS="${DOTDIR}/z_setup_scripts"

export NVMDIR="${ME}/.nvm"
export DOTLOCAL="${ME}/.local"
export CFG="$ME/.config"
export GAMES="$ME/games"

export HOSTSBACKUP=/etc/hosts.bak
export HOSTSDENYBACKUP=/etc/hostsdeny.bak
export HOSTSSECURED="${DOTDIR}/hostssecured"

# Create necessary directories
mkdir -p "$ME/storage/NAS/"
mkdir -p "${DOTLOCAL}"
mkdir -p "${ME}/.local/share/applications"
