#!/bin/bash

source ./settings.sh
source ./utils.sh

echo
echo "[INFO] Starting toolset configuration.."

echo
echo "[INFO] Installing handy tools/utilities.."
install_if_nxe_safe "htop"
install_if_nxe_safe "iotop"
install_if_nxe_safe "iftop"
install_if_nxe_safe "ncdu"
install_if_nxe_safe "pydf"
install_if_nxe_safe "curl"
install_if_nxe_safe "wget"
install_if_nxe_safe "tldr"
install_if_nxe_safe "nano"
install_if_nxe_safe "git"

echo
read -p "Would you like to update the system? (y/N): " -r CHOICE
if [[ $CHOICE =~ ^[Yy] ]]
then
  eval "$UPDATE_CMD"
fi

echo
echo "[INFO] Toolset configuration complete!"