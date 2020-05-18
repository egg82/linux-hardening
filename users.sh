#!/bin/bash

source ./root_check.sh

echo
echo "[INFO] Starting user configuration.."

echo
echo "Root users:"
getent group | grep 'x:0:' /etc/passwd | cut -d: -f1 | tr '\n' ','
echo
echo "Sudoers:"
getent group root wheel adm admin | cut -d: -f4 | tr -d '\n'

echo
echo
echo "[INFO] Locking accounts.."
passwd -l root

# TODO: Make a backup of /etc/shadow and /etc/passwd, maybe check it every now and then?

echo
echo "Files with setuid:"
find / -perm -04000 2>/dev/null

echo
echo "[INFO] User configuration complete!"