#!/usr/bin/env bash

set -e

cd ~

function print_error { printf '%b' "\e[31m${1}\e[0m\n" >&2; }
function print_green { printf '%b' "\e[32m${1}\e[0m\n" 2>&1; }

case "$(uname -m)" in
	aarch*64|arm*64)
		cpu_arch='arm64'
		;;
	amd*64|x86*64)
		cpu_arch='x64'
		;;
	*)
		{ print_error 'only support arm64 or x86_64'; exit 1; }
		;;
esac

function install_apt_packages {
	sudo apt update && sudo apt install -y nala
	sudo nala install -y nano net-tools lsof iputils-ping gpg curl wget file unzip psmisc man-db locate git tree bat jq \
		build-essential cmake poppler-utils
		# btop plocate ripgrep gdu finger nginx ssh nmap ufw dnsutils cron
}

function install_ohmyposh {
	bash -c "$(curl -fsSL https://ohmyposh.dev/install.sh)"
	echo 'eval "$(~/.local/bin/oh-my-posh init bash --config ~/dracula.omp.json)"' >> ~/.bashrc
	print_green 'installed oh-my-posh'
}

function install_fzf {
	git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
	yes | ~/.fzf/install
	curl -fsSL https://raw.githubusercontent.com/junegunn/fzf-git.sh/main/fzf-git.sh -o ~/fzf-git.sh
	chmod +x ~/fzf-git.sh
	cat >> ~/.bashrc <<-'EOF'
		export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
		source ~/fzf-git.sh
	EOF
	print_green 'installed fzf'
}

function install_git_delta {
	sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/upciti/wakemeops/main/assets/install_repository)"
	sudo nala install -y git-delta
	cat >> ~/.gitconfig <<-'EOF'
		[core]
		    pager = delta
		[interactive]
		    diffFilter = delta --color-only
		[delta]
		    navigate = true
		[merge]
		    conflictstyle = diff3
		[diff]
		    colorMoved = default
	EOF
	print_green 'installed git_delta'
}

function install_z {
	curl -fsSL https://raw.githubusercontent.com/rupa/z/master/z.sh -o ~/z.sh
	echo 'source ~/z.sh' >> ~/.bashrc
	print_green 'installed z'
}

function install_eza {
	curl -fsSL https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/gierens.gpg
	echo "deb [arch=$(dpkg --print-architecture)] http://deb.gierens.de stable main" \
		| sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null
	sudo nala update && sudo nala install -y eza
	print_green 'installed eza'
}

function install_docker {
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/docker-archive-keyring.gpg
	echo "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
		| sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	sudo nala update && sudo nala install -y docker-ce docker-compose
	sudo usermod -aG docker "$USER"
	print_green 'installed docker'
}

function install_r {
	if [ "$cpu_arch" = 'arm64' ]; then
		curl -fsSL https://github.com/r-lib/rig/releases/download/latest/rig-linux-arm64-latest.tar.gz -o /tmp/rig-linux-arm64-latest.tar.gz
		sudo tar -xzvf /tmp/rig-linux-arm64-latest.tar.gz -C /usr/local/
		sudo rig add release
		sudo rig default release
	elif [ "$cpu_arch" = 'x64' ]; then
		sudo nala install -y gdebi-core
		export R_VERSION="$(curl -fsSL https://cran.r-project.org/src/base/R-4/ | tail -6 | grep -oE '<a href="R-.+\.tar\.gz">' | cut -c12-16)"
		curl -fsSL https://cdn.rstudio.com/r/ubuntu-2204/pkgs/r-${R_VERSION}_1_amd64.deb -o /tmp/r-${R_VERSION}_1_amd64.deb
		yes | sudo gdebi /tmp/r-${R_VERSION}_1_amd64.deb
		sudo ln -s /opt/R/${R_VERSION}/bin/R /usr/local/bin/R
		sudo ln -s /opt/R/${R_VERSION}/bin/Rscript /usr/local/bin/Rscript
	fi
	print_green 'installed r'
}

function install_powershell {
	pwsh_latest_version="$(curl -fsSL https://api.github.com/repos/PowerShell/PowerShell/releases/latest | jq .tag_name | tr -d 'v"')"
	curl -fsSL "https://github.com/PowerShell/PowerShell/releases/download/v${pwsh_latest_version}/powershell-${pwsh_latest_version}-linux-${cpu_arch}.tar.gz" \
		-o /tmp/powershell.tar.gz
	sudo mkdir -p /opt/microsoft/powershell/
	sudo tar -xzvf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/
	sudo chmod +x /opt/microsoft/powershell/pwsh
	mkdir -p ~/.config/powershell
	echo 'export PATH="/opt/microsoft/powershell:$PATH"' >> ~/.bashrc
	print_green 'installed powershell'
}

function install_conda {
	curl -fsSL "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh" -o "/tmp/Miniforge3-$(uname)-$(uname -m).sh"
	printf '%b' 'yes\nyes\n\nno\n' | bash "/tmp/Miniforge3-$(uname)-$(uname -m).sh"
	~/miniforge3/bin/conda init
	echo 'changeps1: false' >> ~/miniforge3/.condarc
	print_green 'installed conda'
}

function install_spark {
	sudo nala install -y default-jre
	spark_latest_version="$(curl -fsSL https://archive.apache.org/dist/spark/ | tail -4 | grep -oE '<a href="spark-.+/">' \
		| tr -d '<a href="spark-' | tr -d '/>')"
	curl -fsSL "https://archive.apache.org/dist/spark/spark-${spark_latest_version}/spark-${spark_latest_version}-bin-hadoop3.tgz" -o /tmp/spark.tgz
	sudo mkdir -p /opt/spark
	sudo tar -xzvf /tmp/spark.tgz -C /opt/spark/
	sudo mv "/opt/spark/spark-${spark_latest_version}-bin-hadoop3/" /opt/spark/spark/
	cd "/opt/spark/spark/python/lib"
	sudo unzip '*.zip'

	cat >> ~/.bashrc <<-'EOF'
		export SPARK_HOME="/opt/spark/spark"
		export PATH="$SPARK_HOME/bin:$PATH"
		export PYTHONPATH="/opt/spark/spark/python/lib:$PYTHONPATH"
		export PYSPARK_PYTHON=python
	EOF
	print_green 'installed spark'
}

function install_dbt {
	~/miniforge3/bin/conda create -n dbt python -y
	~/miniforge3/envs/dbt/bin/pip install --no-input dbt-core
	print_green 'installed dbt'
}

function install_nvm {
	bash -c "$(curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh)"
	. ~/.nvm/nvm.sh
	nvm install --lts 22
	nvm alias default 22
	nvm use 22
	print_green 'installed nvm'
}

function install_sadtalker {
	git clone --depth 1 https://github.com/OpenTalker/SadTalker.git ~/SadTalker
	~/miniforge3/bin/conda create -n sadtalker python=3.8 ffmpeg -y
	~/miniforge3/envs/sadtalker/bin/pip install --no-input torch==1.12.1 torchvision==0.13.1 torchaudio==0.12.1 dlib -r ~/SadTalker/requirements.txt

	chmod +x ~/SadTalker/scripts/download_models.sh
	cd ~/SadTalker
	~/SadTalker/scripts/download_models.sh
	cd -
	print_green 'installed sadtalker'
}

function install_ollama {
	sudo sh -c "$(curl -fsSL https://ollama.com/install.sh)"
	# curl -fsSL https://github.com/ollama/ollama/releases/download/v0.4.0-rc5/ollama-linux-arm64.tgz -o ~/ollama-linux-arm64.tgz
	# sudo tar -xzvf ~/ollama-linux-arm64.tgz -C /usr/local/
	# rm -rf ~/ollama-linux-arm64.tgz

	ollama serve &
	sleep 10
	ollama pull qwen3:14b
	ollama pull llama3.2-vision
	# ollama pull deepseek-r1:14b
	kill %1
	echo 'ollama serve &>/dev/null &' >> ~/.bashrc
	print_green 'installed ollama'
}

function install_open_webui {
	# sudo nala install -y ffmpeg
	# git clone --depth 1 https://github.com/open-webui/open-webui.git ~/open-webui
	# cp -RPp ~/open-webui/.env.example ~/open-webui/.env
	# npm --prefix ~/open-webui/ install
	# npm --prefix ~/open-webui/ run build
	# ~/miniforge3/bin/conda create -n open_webui python=3.11 -y
	# ~/miniforge3/envs/open_webui/bin/pip install --no-input -r ~/open-webui/backend/requirements.txt
	# cat >> ~/.bashrc <<-'EOF'
	# 	eval "$(~/miniforge3/bin/conda shell.posix activate open_webui)"
	# 	~/open-webui/backend/start.sh &>/dev/null &
	# 	eval "$(~/miniforge3/bin/conda shell.posix deactivate)"
	# EOF
	~/miniforge3/bin/conda create -n open_webui python=3.11 -y
	~/miniforge3/envs/open_webui/bin/pip install --no-input open-webui
	cat >> ~/.bashrc <<-'EOF'
		eval "$(~/miniforge3/bin/conda shell.posix activate open_webui)"
		open-webui serve &>/dev/null &
		eval "$(~/miniforge3/bin/conda shell.posix deactivate)"
	EOF
	print_green 'installed open webui'
}

function install_stable_diffusion_webui {
	sudo nala install -y python3-dev python3-venv libgl1 libglib2.0-0 libsndfile1 google-perftools
	curl -fsSL https://raw.githubusercontent.com/AUTOMATIC1111/stable-diffusion-webui/master/webui.sh -o ~/webui.sh
	chmod +x ~/webui.sh
	echo '~/webui.sh --skip-torch-cuda-test --precision full --no-half --listen --api &>/dev/null &' >> ~/.bashrc
	print_green 'installed stable diffusion webui'
}

function install_go {
	if [ "$cpu_arch" = 'arm64' ]; then
		curl -fsSL https://go.dev/dl/go1.23.0.linux-arm64.tar.gz -o ~/go.tar.gz
	elif [ "$cpu_arch" = 'x64' ]; then
		curl -fsSL https://go.dev/dl/go1.23.0.linux-amd64.tar.gz -o ~/go.tar.gz
	fi
	sudo tar -xzvf ~/go.tar.gz -C /usr/local/
	rm -rf ~/go.tar.gz
	echo 'export PATH="/usr/local/go/bin:$PATH"' >> ~/.bashrc
	print_green 'installed go'
}

function install_fabric {
	/usr/local/go/bin/go install github.com/danielmiessler/fabric/cmd/fabric@latest

	mkdir -p ~/.config/fabric/
	cat > ~/.config/fabric/.env <<-'EOF'
		DEFAULT_VENDOR=Ollama
		DEFAULT_MODEL=llama3.2-vision
		PATTERNS_LOADER_GIT_REPO_URL=https://github.com/danielmiessler/fabric.git
		PATTERNS_LOADER_GIT_REPO_PATTERNS_FOLDER=patterns
		OLLAMA_API_URL=http://localhost:11434
	EOF

	cat >> ~/.bashrc <<-'EOF'
		export GOROOT=/usr/local/go
		export GOPATH=~/go
		export PATH="$GOPATH/bin:$GOROOT/bin:~/.local/bin:$PATH"
		fabric -U &>/dev/null
	EOF
	print_green 'installed fabric'
}

function install_aider {
	sh -c "$(curl -fsSL https://aider.chat/install.sh)"
	cat >> ~/.bashrc <<-'EOF'
		export PATH="~/.local/bin:$PATH"
		export OLLAMA_API_BASE=http://127.0.0.1:11434
	EOF

	cat > ~/.aider.conf.yml <<-'EOF'
		model: ollama/deepseek-r1:14b
		dark-mode: true
	EOF
	print_green 'installed aider'
}

function install_docling {
	~/miniforge3/bin/conda create -n docling python -y
	~/miniforge3/envs/docling/bin/pip install --no-input docling
	print_green 'installed docling'
}

function install_n8n {
	nvm use 22
	npm install n8n -g
	cat >> ~/.bashrc <<-'EOF'
		export N8N_RUNNERS_ENABLED=true
		n8n start &>/dev/null &
	EOF
	print_green 'installed n8n'
}

function main {
	install_apt_packages
	install_ohmyposh
	install_fzf
	install_git_delta
	install_z
	install_eza
	# install_docker
	# install_r
	install_powershell
	install_conda
	# install_spark
	# install_dbt
	install_nvm
	# install_sadtalker
	install_ollama
	install_open_webui
	install_stable_diffusion_webui
	install_go
	install_fabric
	# install_aider
	install_docling
	install_n8n
}

main

sudo curl -fsSL https://gist.githubusercontent.com/benjamin-chan/4ef37955eabf5fa8b9e70053c80b7d76/raw/57ff34139829e49652eec05d0d1c91488563f39e/R.nanorc \
	-o /usr/share/nano/R.nanorc
sudo curl -fsSL https://raw.githubusercontent.com/mitchell486/nanorc/master/powershell.nanorc -o /usr/share/nano/powershell.nanorc

cat >> ~/.bashrc <<-'EOF'
	export BAT_THEME=Dracula
	alias edit_profile="nano ~/.bashrc"
	alias lm="eza --long --color=always --icons=always --all"
	alias cat="batcat -p"
	# alias grep=rg
	# alias locate=plocate
	# alias btop="btop --utf-force"
EOF

# yes | sudo unminimize
sudo updatedb
sudo rm -rf /tmp/*
rm -rf ~/.cache/*

print_green 'install.sh is done'