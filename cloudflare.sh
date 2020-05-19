#!/bin/bash

source ./root_check.sh
source ./settings.sh
source ./utils.sh

echo
echo "[INFO] Starting Cloudflare configuration.."

if [[ -n ${1+x} ]]
then
  TCP_PORTS=$1
fi

if [[ -n ${2+x} ]]
then
  UDP_PORTS=$2
fi

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

if [ $FIREWALL == "iptables" ] && [ "$OS_TYPE" == "debian" ]
then
  install_if_nxe "iptables-persistent"
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
  if [[ -z ${TCP_PORTS+x} ]]
  then
    read -p "TCP Ports to open to Cloudflare (eg. 22,53,80,443): " -r TCP_PORTS
  fi
  for i in ${TCP_PORTS//,/ }
  do
    cat /tmp/cf_ips | while IFS= read -r CFIP
    do
      eval "ufw allow proto tcp from $CFIP to any port $i comment \"Cloudflare\" >/dev/null 2>&1"
    done
    echo "[INFO] Added $i"
  done

  if [[ -z ${UDP_PORTS+x} ]]
  then
    read -p "UDP Ports to open to Cloudflare (eg. 22,53,80,443): " -r UDP_PORTS
  fi
  for i in ${UDP_PORTS//,/ }
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

if [ ! -f /etc/cron.daily/cloudflare ]
then
  SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 || return ; pwd -P )"
  echo
  echo "[INFO] Installing cron job.."
  rm -f /etc/cron.daily/cloudflare
  cat <<EOT >> /etc/cron.daily/cloudflare
#!/bin/bash
$SCRIPTPATH $TCP_PORTS $UDP_PORTS >/dev/null 2>&1
EOT
  chmod +x /etc/cron.daily/cloudflare
fi

echo
echo "[INFO] Cloudflare configuration complete!"