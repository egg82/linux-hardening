#!/bin/bash

source ./settings.sh
source ./utils.sh

echo
echo "[INFO] Starting service configuration.."

if [ -f /etc/ssh/sshd_config ]
then
  echo
  echo "[INFO] Configuring OpenSSH.."
  FILE=/etc/ssh/sshd_config
  cp $FILE $FILE.bak
  echo "[INFO] Copied unmodified OpenSSH config to $FILE.bak"
  grep -qoP '^(#\s*)?PermitEmptyPasswords' $FILE && sed -i -E 's/^(#\s*)?PermitEmptyPasswords.*/PermitEmptyPasswords no/' $FILE || echo 'PermitEmptyPasswords no' >> $FILE
  grep -qoP '^(#\s*)?PermitUserEnvironment' $FILE && sed -i -E 's/^(#\s*)?PermitUserEnvironment.*/PermitUserEnvironment no/' $FILE || echo 'PermitUserEnvironment no' >> $FILE
  grep -qoP '^(#\s*)?PrintLastLog' $FILE && sed -i -E 's/^(#\s*)?PrintLastLog.*/PrintLastLog no/' $FILE || echo 'PrintLastLog no' >> $FILE
  grep -qoP '^(#\s*)?Protocol' $FILE && sed -i -E 's/^(#\s*)?Protocol.*/Protocol 2/' $FILE || echo 'Protocol 2' >> $FILE
  grep -qoP '^(#\s*)?IgnoreRhosts' $FILE && sed -i -E 's/^(#\s*)?IgnoreRhosts.*/IgnoreRhosts yes/' $FILE || echo 'IgnoreRhosts yes' >> $FILE
  grep -qoP '^(#\s*)?RhostsAuthentication' $FILE && sed -i -E 's/^(#\s*)?RhostsAuthentication.*/RhostsAuthentication no/' $FILE || echo 'RhostsAuthentication no' >> $FILE
  grep -qoP '^(#\s*)?RhostsRSAAuthentication' $FILE && sed -i -E 's/^(#\s*)?RhostsRSAAuthentication.*/RhostsRSAAuthentication no/' $FILE || echo 'RhostsRSAAuthentication no' >> $FILE
  grep -qoP '^(#\s*)?RSAAuthentication' $FILE && sed -i -E 's/^(#\s*)?RSAAuthentication.*/RSAAuthentication yes/' $FILE || echo 'RSAAuthentication yes' >> $FILE
  grep -qoP '^(#\s*)?HostbasedAuthentication' $FILE && sed -i -E 's/^(#\s*)?HostbasedAuthentication.*/HostbasedAuthentication no/' $FILE || echo 'HostbasedAuthentication no' >> $FILE
  grep -qoP '^(#\s*)?LoginGraceTime' $FILE && sed -i -E 's/^(#\s*)?LoginGraceTime.*/LoginGraceTime 120/' $FILE || echo 'LoginGraceTime 120' >> $FILE
  grep -qoP '^(#\s*)?MaxStartups' $FILE && sed -i -E 's/^(#\s*)?MaxStartups.*/MaxStartups 2/' $FILE || echo 'MaxStartups 2' >> $FILE
  read -p "Do you need TCP forwarding? (most commonly \"no\") (y/N): " -r CHOICE
  if [[ ! $CHOICE =~ ^[Yy] ]]
  then
    grep -qoP '^(#\s*)?AllowTcpForwarding' $FILE && sed -i -E 's/^(#\s*)?AllowTcpForwarding.*/AllowTcpForwarding no/' $FILE || echo 'AllowTcpForwarding no' >> $FILE
  fi
  read -p "Do you need X11 forwarding? (most commonly \"no\") (y/N): " -r CHOICE
  if [[ ! $CHOICE =~ ^[Yy] ]]
  then
    grep -qoP '^(#\s*)?X11Forwarding' $FILE && sed -i -E 's/^(#\s*)?X11Forwarding.*/X11Forwarding no/' $FILE || echo 'X11Forwarding no' >> $FILE
  fi

  read -p "Users to allow (eg. root,user1,user2): " -r USERS
  grep -qoP '^(#\s*)?AllowUsers' $FILE && sed -i -E 's/^(#\s*)?AllowUsers.*/AllowUsers '"${USERS//,/ }"'/' $FILE || echo 'AllowUsers '"${USERS//,/ }"'' >> $FILE
  if [[ $USERS =~ root ]]
  then
    grep -qoP '^(#\s*)?PermitRootLogin' $FILE && sed -i -E 's/^(#\s*)?PermitRootLogin.*/PermitRootLogin yes/' $FILE || echo 'PermitRootLogin yes' >> $FILE
  else
    grep -qoP '^(#\s*)?PermitRootLogin' $FILE && sed -i -E 's/^(#\s*)?PermitRootLogin.*/PermitRootLogin no/' $FILE || echo 'PermitRootLogin no' >> $FILE
  fi

  echo "[INFO] Restarting OpenSSH.."
  echo "[WARN] PLEASE VERIFY THAT YOU CAN STILL LOG IN USING ANOTHER SESSION"
  systemctl restart ssh.service
fi

if [ "$OS_TYPE" == "debian" ] && [ "$(eval "${PKG_CHECK_AVAIL_CMD//\{item\}/apparmor}")" -ne 0 ]
then
  echo
  echo "[INFO] Configuring Apparmor.."
  install_if_nxe "apparmor"
  install_if_nxe "apparmor-profiles"
  install_if_nxe "apparmor-profiles-extra"
  install_if_nxe "apparmor-utils"
  if [ "$OS_TYPE" == "debian" ] && [ "$(eval "${PKG_CHECK_AVAIL_CMD//\{item\}/apache2}")" -ne 0 ]
  then
    install_if_nxe "libapache2-mod-apparmor"
  fi
elif [ "$OS_TYPE" == "redhat" ]
then
  echo
  echo "[INFO] Configuring SELinux.."
  FILE=/etc/selinux/config
  cp $FILE $FILE.bak
  echo "[INFO] Copied unmodified SELinux config to $FILE.bak"
  grep -qoP '^(#\s*)?SELINUX' $FILE && sed -i -E 's/^(#\s*)?SELINUX.*/SELINUX=enforcing/' $FILE || echo 'SELINUX=enforcing' >> $FILE
  setenforce 1
fi

echo
echo "[INFO] Service configuration complete!"