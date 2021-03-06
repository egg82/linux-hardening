#!/bin/bash

source ./root_check.sh

echo
echo "[INFO] Starting user configuration.."

echo
echo "Logged-in users:"
who

echo
echo "Last logged-in users:"
last

echo
read -p "Users to kick (eg. root,admin,test): " -r USERS
for i in ${USERS//,/$IFS}
do
  eval "pkill -15 -u $i"
  sleep 2
  eval "pkill -9 -u $i"
  echo "[INFO] Kicked $i"
done

echo
echo "Non-system users:"
eval getent passwd "{$(awk '/^UID_MIN/ {print $2}' /etc/login.defs)..$(awk '/^UID_MAX/ {print $2}' /etc/login.defs)}" | cut -d: -f1

echo
echo "Root users:"
getent group | grep 'x:0:' /etc/passwd | cut -d: -f1 | tr '\n' ','

echo
echo
echo "Sudoers:"
getent group root wheel adm admin | cut -d: -f4 | tr -d '\n'

echo
echo
echo "Users with shells:"
getent passwd | awk -F/ '$NF != "nologin" && $NF != "false" && $NF != "sync" && $NF != "!"' | cut -d: -f1

echo
read -p "Users to password change (eg. root,admin,test): " -r USERS
for i in ${USERS//,/$IFS}
do
  passwd "$i"
done

echo
echo "[INFO] Locking accounts.."
# TODO: We may be logging in as root. Offer the option instead.
#passwd -l root

# TODO: Make a backup of /etc/shadow and /etc/passwd, maybe check it every now and then?

echo
echo "Files with setuid:"
find / -perm -04000 2>/dev/null

echo
echo "[INFO] User configuration complete!"