#!/bin/bash

source ./root_check.sh
source ./settings.sh

echo
echo "[INFO] OS: $OS_TYPE"
echo "[INFO] Installer: $INSTALLER"

source ./users.sh
source ./firewall.sh
# Cloudflare after firewall, since firewall erases current config
echo
read -p "Are you behind Cloudflare? (y/N): " -r CHOICE
if [[ $CHOICE =~ ^[Yy] ]]
then
  source ./cloudflare.sh
fi
source ./services.sh
source ./tools.sh
read -p "Are you using this for a competition? (y/N): " -r CHOICE
if [[ $CHOICE =~ ^[Yy] ]]
then
  source ./competition.sh
fi