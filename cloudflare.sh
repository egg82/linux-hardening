#!/bin/bash

source ./root_check.sh
source ./settings.sh
source ./utils.sh

echo
echo "[INFO] Starting Cloudflare configuration.."

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
echo "[INFO] Downloading Cloudflare IPs.."
if [ "$(eval "${PKG_CHECK_INST_CMD//\{item\}/curl}")" -ne 0 ]
then
  curl -s https://www.cloudflare.com/ips-v4 -o /tmp/cf_ips
  curl -s https://www.cloudflare.com/ips-v6 >> /tmp/cf_ips
elif [ "$(eval "${PKG_CHECK_INST_CMD//\{item\}/wget}")" -ne 0 ]
then
  wget https://www.cloudflare.com/ips-v4 -O /tmp/cf_ips
  wget https://www.cloudflare.com/ips-v6 -O ->> /tmp/cf_ips
else
  install_if_nxe "curl"
  curl -s https://www.cloudflare.com/ips-v4 -o /tmp/cf_ips
  curl -s https://www.cloudflare.com/ips-v6 >> /tmp/cf_ips
fi

echo
if [ "$FIREWALL" == "ufw" ]
then
  read -p "TCP Ports to open to Cloudflare (eg. 22,53,80,443): " -r PORTS
  for i in ${PORTS//,/ }
  do
    cat /tmp/cf_ips | while IFS= read -r CFIP
    do
      eval "ufw allow proto tcp from $CFIP to any port $i comment \"Cloudflare\" >/dev/null 2>&1"
    done
    echo "[INFO] Added $i"
  done
  read -p "UDP Ports to open to Cloudflare (eg. 22,53,80,443): " -r PORTS
  for i in ${PORTS//,/ }
  do
    cat /tmp/cf_ips | while IFS= read -r CFIP
    do
      eval "ufw allow proto udp from $CFIP to any port $i comment \"Cloudflare\" >/dev/null 2>&1"
    done
    echo "[INFO] Added $i"
  done
  echo "[INFO] Reloading firewall.."
  eval "ufw --force reload >/dev/null 2>&1"
elif [ "$FIREWALL" == "firewalld" ]
then
  echo "[WARN] Not implemented yet."
elif [ "$FIREWALL" == "iptables" ]
then
  if [ "$OS_TYPE" == "debian" ]
  then
    echo "[WARN] Not implemented yet."
  elif [ "$OS_TYPE" == "redhat" ]
  then
    echo "[WARN] Not implemented yet."
  fi
fi

echo
echo "[INFO] Installing cron job.."

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
eval "(crontab -l ; echo \"0 2 * * * $DIR/${BASH_SOURCE[0]} >/dev/null 2>&1\")| crontab -"

echo
echo "[INFO] Cloudflare configuration complete!"