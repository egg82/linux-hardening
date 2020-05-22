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
install_if_nxe_safe "automake"
if [ $OS_TYPE == "debian" ]
then
  install_if_nxe_safe "build-essential"
elif [ $OS_TYPE == "redhat" ]
then
  eval "$INSTALLER -y group install \"Development Tools\" >/dev/null 2>&1"
fi
install_if_nxe_safe "python"
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