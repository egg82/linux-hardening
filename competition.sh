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
pkill -15 $PPID
sleep 2
pkill -9 $PPID
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

# TODO: Test this
echo
echo "[INFO] Installing portspoof.."
git clone https://github.com/drk1wi/portspoof.git /root/portspoof
CWD=$(pwd)
cd /root/portspoof || return
./configure && make && make install >/dev/null 2>&1
cp system_files/improved/etc/init.d/portspoof /etc/init.d/portspoof
cp system_files/improved/etc/default/portspoof /etc/default/portspoof
eval "cd $CWD"
FILE=/etc/init.d/portspoof
echo
read -p "Portspoof listen port (eg. 4444): " -r LISTEN_PORT
grep -q '^(#\s*)?PS_LISTENPORT' $FILE && sed -i 's/^(#\s*)?PS_LISTENPORT.*/PS_LISTENPORT='"$LISTEN_PORT"'/' $FILE || echo 'PS_LISTENPORT='"$LISTEN_PORT"'' >> $FILE
grep -q '^(#\s*)?PS_USER' $FILE && sed -i 's/^(#\s*)?PS_USER.*/PS_USER=root/' $FILE || echo 'PS_USER=root' >> $FILE
grep -q '^(#\s*)?PS_ARGUMENTS' $FILE && sed -i 's/^(#\s*)?PS_ARGUMENTS.*/PS_ARGUMENTS=\"-p '"$LISTEN_PORT"' -s /root/portspoof/tools/portspoof_signatures\"/' $FILE || echo 'PS_ARGUMENTS=\"-p '"$LISTEN_PORT"' -s /root/portspoof/tools/portspoof_signatures\"' >> $FILE
read -p "Ports to redirect to portspoof (eg. 1:21,23:79,81:65535): " -r PORTS
grep -q '^(#\s*)?PS_UNFILTEREDPORTS' $FILE && sed -i 's/^(#\s*)?PS_UNFILTEREDPORTS.*/PS_UNFILTEREDPORTS=\"'"$PORTS"'\"/' $FILE || echo 'PS_UNFILTEREDPORTS=\"'"$PORTS"'\"' >> $FILE
if [ "$OS_TYPE" == "debian" ]
then
  update-rc.d portspoof defaults
  /etc/init.d/portspoof start
elif [ "$OS_TYPE" == "redhat" ]
then
  chkconfig portspoof on
  /etc/init.d/portspoof start
fi

echo
echo "[INFO] Disabling compilers.."
chmod 000 /usr/bin/byacc
chmod 000 /usr/bin/yacc
chmod 000 /usr/bin/bcc
chmod 000 /usr/bin/kgcc
chmod 000 /usr/bin/cc
chmod 000 /usr/bin/gcc
chmod 000 /usr/bin/*c++
chmod 000 /usr/bin/*g++

echo
echo "[INFO] Competition configuration complete!"