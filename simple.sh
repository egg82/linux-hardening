#!/bin/bash

# Ensure we are root
if [ "$(id -u)" != "0" ]
then
  sudo "$0" "$@"
  exit $?
fi

# What OS are we running?
OS_TYPE=""
INSTALLER=""
if [ -f "/etc/debian_version" ]
then
  OS_TYPE="debian"
  INSTALLER="apt-get"
else
  OS_TYPE="redhat"
  INSTALLER="yum"
fi

read -p "Users to password change: " -r USERS
for i in ${USERS//,/$IFS}
do
  passwd "$i"
done

# Who's logged in?
echo
echo "Logged-in users:"
who

# Who has sudo?
echo
echo "Sudoers:"
getent group root wheel adm admin | cut -d: -f4 | tr -d '\n'
echo

# Kick 'em
echo
read -p "Users to kick: " -r USERS
for i in ${USERS//,/$IFS}
do
  pkill -9 -u "$i"
done

# OpenSSH hardening
# TODO: simplify
FILE=/etc/ssh/sshd_config
if [ -f $FILE ]
then
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
  grep -qoP '^(#\s*)?AllowTcpForwarding' $FILE && sed -i -E 's/^(#\s*)?AllowTcpForwarding.*/AllowTcpForwarding no/' $FILE || echo 'AllowTcpForwarding no' >> $FILE
  grep -qoP '^(#\s*)?X11Forwarding' $FILE && sed -i -E 's/^(#\s*)?X11Forwarding.*/X11Forwarding no/' $FILE || echo 'X11Forwarding no' >> $FILE

  read -p "Users to allow (eg. root,user1,user2): " -r USERS
  grep -qoP '^(#\s*)?AllowUsers' $FILE && sed -i -E 's/^(#\s*)?AllowUsers.*/AllowUsers '"${USERS//,/ }"'/' $FILE || echo 'AllowUsers '"${USERS//,/ }"'' >> $FILE
  if [[ $USERS =~ root ]]
  then
    grep -qoP '^(#\s*)?PermitRootLogin' $FILE && sed -i -E 's/^(#\s*)?PermitRootLogin.*/PermitRootLogin yes/' $FILE || echo 'PermitRootLogin yes' >> $FILE
  else
    grep -qoP '^(#\s*)?PermitRootLogin' $FILE && sed -i -E 's/^(#\s*)?PermitRootLogin.*/PermitRootLogin no/' $FILE || echo 'PermitRootLogin no' >> $FILE
  fi

  systemctl restart ssh.service
fi

## -snip-

# Firewall
ufw disable
systemctl disable firewalld
systemctl stop firewalld

# Install net-tools
"$INSTALLER" -y install net-tools

echo
echo "Listening ports:"
netstat -peanut | grep LISTEN

# TODO: iptables rules
# Default deny incoming/outgoing
if [ "$OS_TYPE" == "debian" ]
then
  iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT # Allow established/related incoming
  iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT # Allow established/related outgoing
  iptables -P INPUT DROP # Default deny incoming
  iptables -P OUTPUT DROP # Default deny outgoing

  iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT # DNS TCP out
  iptables -A OUTPUT -p udp --dport 53 -j ACCEPT # DNS UDP out
  iptables -A OUTPUT -p udp --dport 123 -j ACCEPT # NTP out
  iptables -A OUTPUT -p tcp --dport 80 -j ACCEPT # HTTP out
  iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT # HTTPS out
  iptables -A OUTPUT -p tcp --dport 9418 -j ACCEPT # Git out
  
  read -p "Ports to open to ALL (eg. 22/tcp,53,80/tcp,443/tcp): " -r PORTS
  for i in ${PORTS//,/$IFS}
  do
    P=(${i//\//$IFS})
    PORT=${P[0]}
    TYPE="tcp/udp"
    if [ ${#arr[@]} == 1 ]
    then
      TYPE=${P[1]}
    fi
    if [ "$TYPE" == "tcp/udp" ]
    then
      iptables -A INPUT -p tcp --dport "$PORT" -j ACCEPT
      iptables -A INPUT -p udp --dport "$PORT" -j ACCEPT
    else
      iptables -A INPUT -p "$TYPE" --dport "$PORT" -j ACCEPT
    fi
  done
elif [ "$OS_TYPE" == "redhat" ]
then
  # TODO: Test this
  iptables -A OUTPUT -p icmp -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT --permanent # Allow outbound ICMP
  iptables -A OUTPUT -p icmp -m state --state ESTABLISHED,RELATED -j ACCEPT --permanent # Allow outbound ICMP
  iptables -A OUTPUT -p tcp --dport 80 -m state --state RELATED,ESTABLISHED -m limit --limit 30/second -j DROP --permanent # Drop conns after 30 sec
  iptables -A OUTPUT -p tcp --dport 443 -m state --state RELATED,ESTABLISHED -m limit --limit 30/second -j DROP --permanent # Drop conns after 30 sec
  systemctl save iptables.service
  systemctl restart iptables.service
fi

# -snip-

# Whoami?
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

# passwd,shadow protection
chattr +i /etc/passwd
chattr +i /etc/shadow

# TODO: Test/simplify this
echo
echo "[INFO] Installing portspoof.."
git clone https://github.com/drk1wi/portspoof.git /root/portspoof
CWD=$(pwd)
cd /root/portspoof || return
./configure && make && make install >/dev/null 2>&1
cp system_files/improved/etc/init.d/portspoof /etc/init.d/portspoof
eval "cd $CWD"
FILE=/etc/init.d/portspoof
echo
read -p "Portspoof listen port (eg. 4444): " -r LISTEN_PORT
sed -i -E 's/\s+-i\s+ ${int}.*//' $FILE
grep -qoP '^(#\s*)?PS_LISTENPORT' $FILE && sed -i -E 's/^(#\s*)?PS_LISTENPORT.*/PS_LISTENPORT='"$LISTEN_PORT"'/' $FILE || echo 'PS_LISTENPORT='"$LISTEN_PORT"'' >> $FILE
grep -qoP '^(#\s*)?PS_USER' $FILE && sed -i -E 's/^(#\s*)?PS_USER.*/PS_USER=root/' $FILE || echo 'PS_USER=root' >> $FILE
grep -qoP '^(#\s*)?PS_ARGUMENTS' $FILE && sed -i -E 's/^(#\s*)?PS_ARGUMENTS.*/PS_ARGUMENTS=\"-p $PS_LISTENPORT -s \/root\/portspoof\/tools\/portspoof_signatures\"/' $FILE || echo 'PS_ARGUMENTS=\"-p $PS_LISTENPORT -s /root/portspoof/tools/portspoof_signatures\"' >> $FILE
read -p "Ports to redirect to portspoof (eg. 1:21 23:79 81:65535): " -r PORTS
grep -qoP '^(#\s*)?PS_UNFILTEREDPORTS' $FILE && sed -i -E 's/^(#\s*)?PS_UNFILTEREDPORTS.*/PS_UNFILTEREDPORTS=\"'"$PORTS"'\"/' $FILE || echo 'PS_UNFILTEREDPORTS=\"'"$PORTS"'\"' >> $FILE
if [ "$OS_TYPE" == "debian" ]
then
  update-rc.d portspoof defaults
elif [ "$OS_TYPE" == "redhat" ]
then
  chkconfig portspoof on
fi
/etc/init.d/portspoof start

# Install tools
"$INSTALLER" -y install htop iotop iftop ncdu pydf

# Restart the box to eliminate any lingering open connections
reboot now