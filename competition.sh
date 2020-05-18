#!/bin/bash

source ./root_check.sh
source ./settings.sh

echo
echo "[INFO] Starting competition configuration.."

echo
echo "[INFO] Changing whoami.."
ORIGINAL=$(which whoami)
DIR=$(dirname "$ORIGINAL")
mv "$ORIGINAL" "$DIR/wai"
cat <<EOT >> "$ORIGINAL"
#!/bin/bash
kill -15 $PPID
sleep 2
kill -9 $PPID
EOT
chmod +x "$ORIGINAL"

echo
echo "[INFO] Changing firewall rules.."
IPTABLES=0
if [ "$(eval "${PKG_CHECK_INST_CMD//\{item\}/iptables-services}")" -ne 0 ] || [ "$(eval "${PKG_CHECK_INST_CMD//\{item\}/iptables}")" -ne 0 ]
then
  IPTABLES=1
fi

if [ $IPTABLES -ne 0 ]
then
  # IPTables rules for dropping hanging connections lasting longer than X (in our case, 30 seconds)
  if [ "$OS_TYPE" == "debian" ]
  then
    echo "[WARN] Not implemented yet."
  elif [ "$OS_TYPE" == "redhat" ]
  then
    # TODO: Test this
    iptables -A OUTPUT -p tcp --dport 80 -m state --state RELATED,ESTABLISHED -m limit --limit 30/second -j DROP --permanent
    iptables -A OUTPUT -p tcp --dport 443 -m state --state RELATED,ESTABLISHED -m limit --limit 30/second -j DROP --permanent
    systemctl save iptables.service
    systemctl restart iptables.service
  fi
fi

echo
echo "[INFO] Removing write attr for passwd/shadow.."
chattr -i /etc/passwd
chattr -i /etc/shadow

echo
echo "[INFO] Competition configuration complete!"