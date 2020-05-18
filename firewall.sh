#!/bin/bash

source ./root_check.sh
source ./settings.sh
source ./utils.sh

echo
echo "[INFO] Starting firewall configuration.."

FIREWALL="none"

if [ "$(eval "${PKG_CHECK_INST_CMD//\{item\}/ufw}")" -ne 0 ]
then
  FIREWALL="ufw"
elif [ "$(eval "${PKG_CHECK_INST_CMD//\{item\}/firewalld}")" -ne 0 ]
then
  FIREWALL="firewalld"
elif [ "$(eval "${PKG_CHECK_INST_CMD//\{item\}/iptables-services}")" -ne 0 ]
then
  FIREWALL="iptables"
elif [ "$(eval "${PKG_CHECK_INST_CMD//\{item\}/iptables}")" -ne 0 ]
then
  FIREWALL="iptables"
fi

if [ "$FIREWALL" == "none" ]
then
  echo
  echo "[WARN] No firewall is installed. Installing one now."
  if [ "$OS_TYPE" == "debian" ] && [ "$(eval "${PKG_CHECK_AVAIL_CMD//\{item\}/ufw}")" -ne 0 ]
  then
    install_if_nxe "ufw"
    FIREWALL="ufw"
  elif [ "$OS_TYPE" == "debian" ] && [ "$(eval "${PKG_CHECK_AVAIL_CMD//\{item\}/iptables}")" -ne 0 ]
  then
    install_if_nxe "iptables"
    install_if_nxe "iptables-persistent"
    FIREWALL="iptables"
  elif [ "$OS_TYPE" == "redhat" ] && [ "$(eval "${PKG_CHECK_AVAIL_CMD//\{item\}/firewalld}")" -ne 0 ]
  then
    install_if_nxe "firewalld"
    FIREWALL="firewalld"
  elif [ "$OS_TYPE" == "redhat" ] && [ "$(eval "${PKG_CHECK_AVAIL_CMD//\{item\}/iptables-services}")" -ne 0 ]
  then
    install_if_nxe "iptables-services"
    FIREWALL="iptables"
  else
    >&2 echo "[ERROR] Could not find a firewall to install."
    exit 1
  fi
fi

echo
echo "[INFO] Detected/installed firewall: $FIREWALL"

echo
echo "[INFO] Ensuring appropriate tools are installed.."
install_if_nxe "net-tools"

echo
echo "[INFO] Disabling firewall and setting defaults.."
if [ "$FIREWALL" == "ufw" ]
then
  eval "ufw disable >/dev/null 2>&1"
  eval "ufw --force reset >/dev/null 2>&1"
  eval "ufw default deny incoming >/dev/null 2>&1"
  eval "ufw default deny outgoing >/dev/null 2>&1"
  eval "ufw allow out 53 comment \"DNS TCP/UDP\" >/dev/null 2>&1"
  eval "ufw allow out 123/udp comment \"NTP UDP\" >/dev/null 2>&1"
  eval "ufw allow out 80/tcp comment \"HTTP TCP\" >/dev/null 2>&1"
  eval "ufw allow out 443/tcp comment \"HTTPS TCP\" >/dev/null 2>&1"
  eval "ufw allow out 9418/tcp comment \"Git TCP\" >/dev/null 2>&1"
elif [ "$FIREWALL" == "firewalld" ]
then
  echo "[WARN] Not implemented yet."
elif [ "$FIREWALL" == "iptables" ]
then
  echo "[WARN] Not implemented yet."
fi

echo
echo "Listening ports:"
netstat -peanut | grep LISTEN

echo
if [ "$FIREWALL" == "ufw" ]
then
  read -p "Ports to open (eg. 22/tcp,53,80/tcp,443/tcp): " -r PORTS
  for i in ${PORTS//,/ }
  do
    eval "ufw allow in $i >/dev/null 2>&1"
    echo "[INFO] Added $i"
  done
elif [ "$FIREWALL" == "firewalld" ]
then
  echo "[WARN] Not implemented yet."
elif [ "$FIREWALL" == "iptables" ]
then
  echo "[WARN] Not implemented yet."
fi

echo
if [ "$FIREWALL" == "ufw" ]
then
  echo "[INFO] Enabling firewall.."
  eval "ufw --force enable >/dev/null 2>&1"
elif [ "$FIREWALL" == "firewalld" ]
then
  echo "[WARN] Not implemented yet."
elif [ "$FIREWALL" == "iptables" ]
then
  echo "[WARN] Not implemented yet."
fi

echo
echo "[INFO] Firewall configuration complete!"