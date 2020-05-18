#!/bin/bash

source ./root_check.sh
source ./settings.sh

install_if_nxe () {
  echo "[INFO] Checking for $1.."
  if [ "$(eval "${PKG_CHECK_INST_CMD//\{item\}/$1}")" -eq 0 ]
  then
    echo "[INFO] $1 is not installed, checking availability.."
    if [ "$(eval "${PKG_CHECK_AVAIL_CMD//\{item\}/$1}")" -ne 0 ]
    then
      echo "[INFO] Installing $1.."
      eval "${INSTALL_CMD//\{item\}/$1} >/dev/null 2>&1"
      if [ "$(eval "${PKG_CHECK_INST_CMD//\{item\}/$1}")" -eq 0 ]
      then
        >&2 echo "[ERROR] Could not install $1."
        exit 1
      fi
    else
      >&2 echo "[ERROR] $1 is not available."
      exit 1
    fi
  else
    echo "[INFO] $1 is installed!"
  fi
}

install_if_nxe_safe () {
  echo "[INFO] Checking for $1.."
  if [ "$(eval "${PKG_CHECK_INST_CMD//\{item\}/$1}")" -eq 0 ]
  then
    echo "[INFO] $1 is not installed, checking availability.."
    if [ "$(eval "${PKG_CHECK_AVAIL_CMD//\{item\}/$1}")" -ne 0 ]
    then
      echo "[INFO] Installing $1.."
      eval "${INSTALL_CMD//\{item\}/$1} >/dev/null 2>&1"
      if [ "$(eval "${PKG_CHECK_INST_CMD//\{item\}/$1}")" -eq 0 ]
      then
        >&2 echo "[WARN] Could not install $1."
      fi
    else
      >&2 echo "[WARN] $1 is not available."
    fi
  else
    echo "[INFO] $1 is installed!"
  fi
}