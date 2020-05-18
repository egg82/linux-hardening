#!/bin/bash

source ./settings.sh
source ./utils.sh

echo
echo "[INFO] Starting service configuration.."

if [ -f /etc/ssh/sshd_config ]
then
  echo
  echo "[INFO] Configuring OpenSSH.."
  FILE=/etc/sshd/sshd_config
  cp $FILE $FILE.bak
  echo "[INFO] Copied unmodified OpenSSH config to $FILE.bak"
  grep -q '^(#\s*)?PermitEmptyPasswords' $FILE && sed -i 's/^(#\s*)?PermitEmptyPasswords.*/PermitEmptyPasswords no/' $FILE || echo 'PermitEmptyPasswords no' >> $FILE
  grep -q '^(#\s*)?PermitUserEnvironment' $FILE && sed -i 's/^(#\s*)?PermitUserEnvironment.*/PermitUserEnvironment no/' $FILE || echo 'PermitUserEnvironment no' >> $FILE
  grep -q '^(#\s*)?PrintLastLog' $FILE && sed -i 's/^(#\s*)?PrintLastLog.*/PrintLastLog no/' $FILE || echo 'PrintLastLog no' >> $FILE
  grep -q '^(#\s*)?Protocol' $FILE && sed -i 's/^(#\s*)?Protocol.*/Protocol 2/' $FILE || echo 'Protocol 2' >> $FILE
  grep -q '^(#\s*)?IgnoreRhosts' $FILE && sed -i 's/^(#\s*)?IgnoreRhosts.*/IgnoreRhosts yes/' $FILE || echo 'IgnoreRhosts yes' >> $FILE
  grep -q '^(#\s*)?RhostsAuthentication' $FILE && sed -i 's/^(#\s*)?RhostsAuthentication.*/RhostsAuthentication no/' $FILE || echo 'RhostsAuthentication no' >> $FILE
  grep -q '^(#\s*)?RhostsRSAAuthentication' $FILE && sed -i 's/^(#\s*)?RhostsRSAAuthentication.*/RhostsRSAAuthentication no/' $FILE || echo 'RhostsRSAAuthentication no' >> $FILE
  grep -q '^(#\s*)?RSAAuthentication' $FILE && sed -i 's/^(#\s*)?RSAAuthentication.*/RSAAuthentication yes/' $FILE || echo 'RSAAuthentication yes' >> $FILE
  grep -q '^(#\s*)?HostbasedAuthentication' $FILE && sed -i 's/^(#\s*)?HostbasedAuthentication.*/HostbasedAuthentication no/' $FILE || echo 'HostbasedAuthentication no' >> $FILE
  grep -q '^(#\s*)?LoginGraceTime' $FILE && sed -i 's/^(#\s*)?LoginGraceTime.*/LoginGraceTime 120/' $FILE || echo 'LoginGraceTime 120' >> $FILE
  grep -q '^(#\s*)?MaxStartups' $FILE && sed -i 's/^(#\s*)?MaxStartups.*/MaxStartups 2/' $FILE || echo 'MaxStartups 2' >> $FILE
  read -p "Do you need TCP forwarding? (most commonly \"no\") (y/N): " -r CHOICE
  if [[ ! $CHOICE =~ ^[Yy] ]]
  then
    grep -q '^(#\s*)?AllowTcpForwarding' $FILE && sed -i 's/^(#\s*)?AllowTcpForwarding.*/AllowTcpForwarding no/' $FILE || echo 'AllowTcpForwarding no' >> $FILE
  fi
  read -p "Do you need X11 forwarding? (most commonly \"no\") (y/N): " -r CHOICE
  if [[ ! $CHOICE =~ ^[Yy] ]]
  then
    grep -q '^(#\s*)?X11Forwarding' $FILE && sed -i 's/^(#\s*)?X11Forwarding.*/X11Forwarding no/' $FILE || echo 'X11Forwarding no' >> $FILE
  fi

  read -p "Users to allow (eg. root,user1,user2): " -r USERS
  grep -q '^(#\s*)?AllowUsers' $FILE && sed -i 's/^(#\s*)?AllowUsers.*/AllowUsers ${USERS//,/ }/' $FILE || echo 'AllowUsers ${USERS//,/ }' >> $FILE
  if [[ $USERS =~ root ]]
  then
    grep -q '^(#\s*)?PermitRootLogin' $FILE && sed -i 's/^(#\s*)?PermitRootLogin.*/PermitRootLogin yes/' $FILE || echo 'PermitRootLogin yes' >> $FILE
  else
    grep -q '^(#\s*)?PermitRootLogin' $FILE && sed -i 's/^(#\s*)?PermitRootLogin.*/PermitRootLogin no/' $FILE || echo 'PermitRootLogin no' >> $FILE
  fi

  echo "[INFO] Restarting OpenSSH.."
  echo "[WARN] PLEASE VERIFY THAT YOU CAN STILL LOG IN USING ANOTHER SESSION"
  systemctl restart ssh.service
fi

echo
echo "[INFO] Service configuration complete!"