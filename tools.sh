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
install_if_nxe_safe "build-essential"
install_if_nxe_safe "automake"
install_if_nxe_safe "Development Tools"
install_if_nxe_safe "python2"
install_if_nxe_safe "python3"
install_if_nxe_safe "coreutils"
install_if_nxe_safe "timeout"

echo
read -p "Would you like to update the system? (y/N): " -r CHOICE
if [[ $CHOICE =~ ^[Yy] ]]
then
  eval "$UPDATE_CMD"
fi

echo
echo "[INFO] Toolset configuration complete!"