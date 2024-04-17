#!/usr/bin/env bash

set -e
\unalias -a

function print_error { printf '%b' "\e[31m${1}\e[0m\n" >&2; }
function print_green { printf '%b' "\e[32m${1}\e[0m\n" 2>&1; }

if [ -n "$1" ]; then
	user_name="$1"
else
	read -p "Please input the user name: " user_name
fi

user_name="${user_name// /}"
[ -z "$user_name" ] && { print_error 'user name cannot be empty string'; exit 1; }

chmod +x ./set_up.sh ./add_user.sh ./install_bash_packages.sh ./install_pwsh_packages.ps1

docker-compose run --name ubuntu4ds --detach ubuntu4ds
docker cp . ubuntu4ds:/root/script
docker exec -it -w /root/script ubuntu4ds ./set_up.sh "$user_name"
docker exec -it -w "/home/$user_name" ubuntu4ds su "$user_name"

# docker exec -it -u "$user_name" -w "/home/$user_name" ubuntu4ds bash
# docker attach ubuntu4ds