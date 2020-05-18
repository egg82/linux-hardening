#!/bin/bash

source ./settings.sh

echo "[INFO] OS: $OS_TYPE"
echo "[INFO] Installer: $INSTALLER"

source ./users.sh
source ./firewall.sh
source ./tools.sh