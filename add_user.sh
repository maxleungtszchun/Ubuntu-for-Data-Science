#!/usr/bin/env bash

set -e
user_name="$1"

# change to your location
ln -fs /usr/share/zoneinfo/Hongkong /etc/localtime

apt update
DEBIAN_FRONTEND=noninteractive apt install -y sudo adduser tzdata

adduser "$user_name" --gecos ''
usermod -aG sudo "$user_name"