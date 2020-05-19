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

timeout 1 bash -c 'cat < /dev/null > /dev/tcp/127.0.0.1/80' >/dev/null 2>&1
RESULT=$?
if [ $RESULT -ne 0 ]
then
  echo
  echo "[INFO] Installing spidertrap on port 80.."
  git clone https://bitbucket.org/ethanr/spidertrap.git /root/spidertrap
  chmod +x /root/spidertrap/spidertrap.py
  FILE=/root/spidertrap/spidertrap.py
  grep -qoP '^(#\s*)?PORT' $FILE && sed -i -E 's/^(#\s*)?PORT.*/PORT = 80/' $FILE || echo 'PORT = 80' >> $FILE
  rm -f /etc/systemd/system/spidertrap.service
  cat <<EOT >> /etc/systemd/system/spidertrap.service
[Unit]
Description=Spidertrap
After=network.target

[Service]
Type=simple
Restart=on-failure
User=root
Group=root
ExecStart=/root/spidertrap/spidertrap.py
KillSignal=SIGTERM

[Install]
WantedBy=multi-user.target
EOT
  systemctl daemon-reload
  systemctl enable spidertrap.service
  systemctl start spidertrap.service
fi

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
grep -qoP '^(#\s*)?PS_LISTENPORT' $FILE && sed -i -E 's/^(#\s*)?PS_LISTENPORT.*/PS_LISTENPORT='"$LISTEN_PORT"'/' $FILE || echo 'PS_LISTENPORT='"$LISTEN_PORT"'' >> $FILE
grep -qoP '^(#\s*)?PS_USER' $FILE && sed -i -E 's/^(#\s*)?PS_USER.*/PS_USER=root/' $FILE || echo 'PS_USER=root' >> $FILE
grep -qoP '^(#\s*)?PS_ARGUMENTS' $FILE && sed -i -E 's/^(#\s*)?PS_ARGUMENTS.*/PS_ARGUMENTS=\"-p '"$LISTEN_PORT"' -s /root/portspoof/tools/portspoof_signatures\"/' $FILE || echo 'PS_ARGUMENTS=\"-p '"$LISTEN_PORT"' -s /root/portspoof/tools/portspoof_signatures\"' >> $FILE
read -p "Ports to redirect to portspoof (eg. 1:21,23:79,81:65535): " -r PORTS
grep -qoP '^(#\s*)?PS_UNFILTEREDPORTS' $FILE && sed -i -E 's/^(#\s*)?PS_UNFILTEREDPORTS.*/PS_UNFILTEREDPORTS=\"'"$PORTS"'\"/' $FILE || echo 'PS_UNFILTEREDPORTS=\"'"$PORTS"'\"' >> $FILE
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
chmod 000 /usr/bin/byacc 2>/dev/null
chmod 000 /usr/bin/yacc 2>/dev/null
chmod 000 /usr/bin/bcc 2>/dev/null
chmod 000 /usr/bin/kgcc 2>/dev/null
chmod 000 /usr/bin/cc 2>/dev/null
chmod 000 /usr/bin/gcc 2>/dev/null
chmod 000 /usr/bin/*c++ 2>/dev/null
chmod 000 /usr/bin/*g++ 2>/dev/null

echo
echo "[INFO] Competition configuration complete!"