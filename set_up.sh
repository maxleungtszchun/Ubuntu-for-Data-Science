#!/usr/bin/env bash

set -e

function print_error { printf '%b' "\e[31m${1}\e[0m\n" >&2; }
function print_green { printf '%b' "\e[32m${1}\e[0m\n" 2>&1; }

user_name="$1"
start="$SECONDS"; trap 'print_green "set_up.sh is done. Spent $(( (SECONDS - start) / 60 )) mins\n"' EXIT

./add_user.sh "$user_name"
sudo -u "$user_name" ./install_bash_packages.sh

mv ./dracula.omp.json ./install_pwsh_packages.ps1 "/home/$user_name"
sudo -u "$user_name" "/home/$user_name/install_pwsh_packages.ps1"