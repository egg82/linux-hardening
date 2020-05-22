#!/bin/bash

# Ensure IFS exists and is valid
IFS=" "

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

read -p "Users to password change (eg. root,admin,test): " -r USERS
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
read -p "Users to kick (eg. root,admin,test): " -r USERS
for i in ${USERS//,/$IFS}
do
  pkill -15 -u "$i"
  sleep 2
  pkill -9 -u "$i"
done

# OpenSSH hardening
FILE=/etc/ssh/sshd_config
if [ -f $FILE ]
then
  sed -i 's/^PermitEmptyPasswords/# PermitEmptyPasswords/' $FILE; echo 'PermitEmptyPasswords no' >> $FILE
  sed -i 's/^PermitUserEnvironment/# PermitUserEnvironment/' $FILE; echo 'PermitUserEnvironment no' >> $FILE
  sed -i 's/^PrintLastLog/# PrintLastLog/' $FILE; echo 'PrintLastLog no' >> $FILE
  sed -i 's/^Protocol/# Protocol/' $FILE; echo 'Protocol 2' >> $FILE
  sed -i 's/^IgnoreRhosts/# IgnoreRhosts/' $FILE; echo 'IgnoreRhosts yes' >> $FILE
  sed -i 's/^RhostsAuthentication/# RhostsAuthentication/' $FILE; echo 'RhostsAuthentication no' >> $FILE
  sed -i 's/^RhostsRSAAuthentication/# RhostsRSAAuthentication/' $FILE; echo 'RhostsRSAAuthentication no' >> $FILE
  sed -i 's/^RSAAuthentication/# RSAAuthentication/' $FILE; echo 'RSAAuthentication yes' >> $FILE
  sed -i 's/^HostbasedAuthentication/# HostbasedAuthentication/' $FILE; echo 'HostbasedAuthentication no' >> $FILE
  sed -i 's/^LoginGraceTime/# LoginGraceTime/' $FILE; echo 'LoginGraceTime 120' >> $FILE
  sed -i 's/^MaxStartups/# MaxStartups/' $FILE; echo 'MaxStartups 2' >> $FILE
  sed -i 's/^AllowTcpForwarding/# AllowTcpForwarding/' $FILE; echo 'AllowTcpForwarding no' >> $FILE
  sed -i 's/^X11Forwarding/# X11Forwarding/' $FILE; echo 'X11Forwarding no' >> $FILE

  read -p "Users to allow for SSH (eg. root,user1,user2): " -r USERS
  sed -i 's/^AllowUsers/# AllowUsers/' $FILE; echo "AllowUsers ${USERS//,/ }" >> $FILE # Note the double-quotes here
  if [[ $USERS =~ root ]]
  then
    sed -i 's/^PermitRootLogin/# PermitRootLogin/' $FILE; echo 'PermitRootLogin yes' >> $FILE
  else
    sed -i 's/^PermitRootLogin/# PermitRootLogin/' $FILE; echo 'PermitRootLogin no' >> $FILE
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

# Print existing rules
echo
echo "Current rules:"
iptables -nvL

echo
echo "Listening ports:"
netstat -peanut | grep LISTEN

# Save existing rules
iptables-save > iptables.bak
# Don't lock us out while we flush rules
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
# Flush all existing rules
iptables -t nat -F
iptables -t mangle -F
iptables -F
iptables -X

iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT # Allow established/related incoming (don't lock us out while we reset rules)
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT # Allow established/related outgoing (don't lock us out while we reset rules)
iptables -A INPUT -m conntrack --ctstate INVALID -j DROP # Drop invalid
iptables -P INPUT DROP # Default deny incoming (after established/related rules so we don't lock ourselves out while we reset rules)
iptables -P OUTPUT DROP # Default deny outgoing (after established/related rules so we don't lock ourselves out while we reset rules)

iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT # DNS TCP out
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT # DNS UDP out
iptables -A OUTPUT -p udp --dport 123 -j ACCEPT # NTP out
iptables -A OUTPUT -p tcp --dport 80 -j ACCEPT # HTTP out
iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT # HTTPS out
iptables -A OUTPUT -p tcp --dport 9418 -j ACCEPT # Git out

# TODO: Simplify?
iptables -A OUTPUT -p icmp -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT # ICMP out
iptables -A OUTPUT -p icmp -m state --state ESTABLISHED,RELATED -j ACCEPT # ICMP out
# TODO: Test this
iptables -A OUTPUT -p tcp --dport 80 -m state --state RELATED,ESTABLISHED -m limit --limit 30/second -j DROP # Drop HTTP conns after 30 sec
iptables -A OUTPUT -p tcp --dport 443 -m state --state RELATED,ESTABLISHED -m limit --limit 30/second -j DROP # Drop HTTPS conns after 30 sec

echo
read -p "Ports to open to ALL (eg. 22/tcp,53,80/tcp,443/tcp): " -r PORTS
for i in ${PORTS//,/$IFS}
do
  read -r -a P <<< "${i//\//$IFS}"
  PORT=${P[0]}
  TYPE="tcp/udp"
  if [ ${#P[@]} -gt 1 ]
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

# -snip-

if [ "$OS_TYPE" == "debian" ]
then
  IPTABLES=/etc/iptables/rules.v4
else
  IPTABLES=/etc/sysconfig/iptables
fi

iptables-save > $IPTABLES
(crontab -l || true; echo "@reboot iptables-restore < $IPTABLES")| crontab -

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

# Install tools
"$INSTALLER" -y install htop iotop iftop ncdu pydf

# Restart the box to eliminate any lingering open connections
reboot now