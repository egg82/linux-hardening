#!/bin/bash

INSTALLER=""
INSTALL_CMD=""
UPDATE_CMD=""
PKG_CHECK_INST_CMD=""
PKG_CHECK_AVAIL_CMD=""
OS_TYPE="none"

if [ -f "/etc/debian_version" ]
then
  OS_TYPE="debian"
elif [ -f "/etc/redhat-release" ] || [ -f "/etc/centos-release" ]
then
  OS_TYPE="redhat"
fi

if [ -n "$(command -v yum)" ]
then
  INSTALLER="yum"
  INSTALL_CMD="yum -y install {item}"
  UPDATE_CMD="yum -y upgrade"
  PKG_CHECK_INST_CMD="yum list installed {item} >/dev/null 2>&1"
  PKG_CHECK_AVAIL_CMD="yum list available {item} >/dev/null 2>&1"
elif [ -n "$(command -v apt)" ]
then
  INSTALLER="apt"
  INSTALL_CMD="apt -y install {item}"
  UPDATE_CMD="apt -y full-upgrade && apt -y autoremove && apt autoclean"
  PKG_CHECK_INST_CMD="dpkg-query -W -f='\${Status}' {item} 2>/dev/null | grep -c \"ok installed\""
  PKG_CHECK_AVAIL_CMD="apt-cache search ^{item}\$ | grep -c \"{item}\""
elif [ -n "$(command -v apt-get)" ]
then
  INSTALLER="apt-get"
  INSTALL_CMD="apt-get -y install {item}"
  UPDATE_CMD="apt-get -y full-upgrade && apt-get -y autoremove && apt-get autoclean"
  PKG_CHECK_INST_CMD="dpkg-query -W -f='\${Status}' {item} 2>/dev/null | grep -c \"ok installed\""
  PKG_CHECK_AVAIL_CMD="apt-cache search ^{item}\$ | grep -c \"{item}\""
elif [ -n "$(command -v dnf)" ]
then
  INSTALLER="dnf"
  INSTALL_CMD="dnf -y install {item}"
  UPDATE_CMD="dnf -y upgrade"
  PKG_CHECK_INST_CMD="dnf list --installed {item} >/dev/null 2>&1"
  PKG_CHECK_AVAIL_CMD="dnf list --available {item} >/dev/null 2>&1"
fi