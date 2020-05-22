#!/bin/bash

# file1.txt

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

echo
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
# file2.txt

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
    iptables -A INPUT -p tcp --dport "$PORT" -m conntrack --ctstate NEW,ESTABLISHED,RELATED -j ACCEPT
    iptables -A OUTPUT -p tcp --sport "$PORT" -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    iptables -A INPUT -p udp --dport "$PORT" -m conntrack --ctstate NEW,ESTABLISHED,RELATED -j ACCEPT
    iptables -A OUTPUT -p udp --sport "$PORT" -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
  else
    iptables -A INPUT -p "$TYPE" --dport "$PORT" -m conntrack --ctstate NEW,ESTABLISHED,RELATED -j ACCEPT
    iptables -A OUTPUT -p "$TYPE" --sport "$PORT" -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
  fi
done

iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT # Allow established/related incoming (don't lock us out while we reset rules)
iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT # Allow established/related outgoing (don't lock us out while we reset rules)
iptables -A INPUT -m conntrack --ctstate INVALID -j DROP # Drop invalid





















# -snip-
# file3.txt

#PORTS=(53 80 443 9418) # TCP out
#for i in "${PORTS[@]}"
#do
#  iptables -A OUTPUT -p tcp --dport "$i" -m conntrack --ctstate NEW,ESTABLISHED,RELATED -j ACCEPT
#  iptables -A INPUT -p tcp --sport "$i" -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
#done

iptables -A OUTPUT -p tcp -d 10.120.0.0/24 -m conntrack --ctstate NEW,ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p tcp -s 10.120.0.0/24 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

PORTS=(53 123) # UDP out
for i in "${PORTS[@]}"
do
  iptables -A OUTPUT -p udp --dport "$i" -m conntrack --ctstate NEW,ESTABLISHED,RELATED -j ACCEPT
  iptables -A INPUT -p udp --sport "$i" -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
done

iptables -A OUTPUT -p icmp -m conntrack --ctstate NEW,ESTABLISHED,RELATED,RELATED -j ACCEPT # ICMP out
iptables -A INPUT -p icmp -m conntrack --ctstate ESTABLISHED,RELATED,RELATED -j ACCEPT # ICMP out

iptables -A INPUT -j LOG -m limit --limit 12/min --log-level 4 --log-prefix 'IP INPUT drop: '
iptables -A OUTPUT -j LOG -m limit --limit 12/min --log-level 4 --log-prefix 'IP OUTPUT drop: '

# Install tools
"$INSTALLER" -y install htop iotop iftop ncdu pydf # BEFORE out deny

iptables -P INPUT DROP # Default deny incoming (after established/related rules so we don't lock ourselves out while we reset rules)
iptables -P OUTPUT DROP # Default deny outgoing (after established/related rules so we don't lock ourselves out while we reset rules)

if [ "$OS_TYPE" == "debian" ]
then
  IPTABLES=/etc/iptables/rules.v4
else
  IPTABLES=/etc/sysconfig/iptables
fi

mkdir -p "$(dirname $IPTABLES)"
touch $IPTABLES
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

# Restart the box to eliminate any lingering open connections
reboot now