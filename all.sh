#!/bin/bash

source ./root_check.sh
source ./settings.sh

echo
echo "[INFO] OS: $OS_TYPE"
echo "[INFO] Installer: $INSTALLER"

source ./users.sh
source ./firewall.sh
source ./tools.sh