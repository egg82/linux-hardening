#!/bin/bash

if [ "$(id -u)" != "0" ]
then
  sudo "$0" "$@"
  exit $?
fi