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
	sudo nala install -y nano net-tools lsof iputils-ping dnsutils gpg curl file unzip psmisc man-db \
		locate git tree cron default-jre bat jq libhdf5-dev cmake wget libsndfile1
		# btop plocate ripgrep gdu finger nginx ssh nmap ufw
}

function install_ohmyposh {
	sudo bash -c "$(curl -fsSL https://ohmyposh.dev/install.sh)"
	echo 'eval "$(oh-my-posh init bash --config ~/dracula.omp.json)"' >> ~/.bashrc
	print_green 'installed oh-my-posh'
}

function install_fzf {
	git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
	yes | ~/.fzf/install
	echo "export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'" >> ~/.bashrc
	print_green 'installed fzf'
}

function install_z {
	curl -fsSL https://raw.githubusercontent.com/rupa/z/master/z.sh -o ~/z.sh
	echo 'source ~/z.sh' >> ~/.bashrc
	print_green 'installed z'
}

function install_docker {
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/docker-archive-keyring.gpg
	echo "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
		| sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	sudo nala update && sudo nala install -y docker-ce docker-compose
	sudo usermod -aG docker "$USER"
	print_green 'installed docker'
}

function install_powershell {
	pwsh_latest_version="$(curl -sL https://api.github.com/repos/PowerShell/PowerShell/releases/latest | jq .tag_name | tr -d 'v"')"
	curl -sL "https://github.com/PowerShell/PowerShell/releases/download/v${pwsh_latest_version}/powershell-${pwsh_latest_version}-linux-${cpu_arch}.tar.gz" \
		-o /tmp/powershell.tar.gz
	sudo mkdir -p /opt/microsoft/powershell/
	sudo tar -xzvf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/
	sudo chmod +x /opt/microsoft/powershell/pwsh
	mkdir -p ~/.config/powershell
	echo 'export PATH="/opt/microsoft/powershell:$PATH"' >> ~/.bashrc
	print_green 'installed powershell'
}

function install_r {
	if [ "$cpu_arch" = 'arm64' ]; then
		curl -sL https://github.com/r-lib/rig/releases/download/latest/rig-linux-arm64-latest.tar.gz -o /tmp/rig-linux-arm64-latest.tar.gz
		sudo tar -xzvf /tmp/rig-linux-arm64-latest.tar.gz -C /usr/local/
		sudo rig add release
		sudo rig default release
	elif [ "$cpu_arch" = 'x64' ]; then
		sudo nala install -y gdebi-core
		export R_VERSION="$(curl -sL https://cran.r-project.org/src/base/R-4/ | tail -6 | grep -oE '<a href="R-.+\.tar\.gz">' | cut -c12-16)"
		curl -sL https://cdn.rstudio.com/r/ubuntu-2204/pkgs/r-${R_VERSION}_1_amd64.deb -o /tmp/r-${R_VERSION}_1_amd64.deb
		yes | sudo gdebi /tmp/r-${R_VERSION}_1_amd64.deb
		sudo ln -s /opt/R/${R_VERSION}/bin/R /usr/local/bin/R
		sudo ln -s /opt/R/${R_VERSION}/bin/Rscript /usr/local/bin/Rscript
	fi
	print_green 'installed r'
}

function install_r_packages {
	sudo nala install -y libssl-dev libcurl4-openssl-dev unixodbc-dev libxml2-dev libmariadb-dev libfontconfig1-dev libharfbuzz-dev libfribidi-dev \
		libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev

	r_ds_packages='c("tidyverse", "tidymodels", "lubridate", "glmnet", "randomForest", "caret", "xgboost", "mlr3", "e1071")'
	r_econometrics_packages='c("plm", "cquad", "sandwich", "lmtest", "ivreg", "fastDummies", "stargazer")'
	r_survey_packages='c("ordinal", "lavaan", "semPaths", "semPLS")'

	if [ "$cpu_arch" = 'arm64' ]; then
		Rscript -e "install.packages(c($r_ds_packages, $r_econometrics_packages, $r_survey_packages), repos='http://cran.us.r-project.org')"
	elif [ "$cpu_arch" = 'x64' ]; then
		sudo Rscript -e "install.packages(c($r_ds_packages, $r_econometrics_packages, $r_survey_packages), repos='http://cran.us.r-project.org')"
	fi

	print_green 'installed r packages'
}

function install_conda {
	curl -sL "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh" -o "/tmp/Miniforge3-$(uname)-$(uname -m).sh"
	printf '%b' 'yes\nyes\n\nyes\n' | bash "/tmp/Miniforge3-$(uname)-$(uname -m).sh"
	~/miniforge3/bin/conda init
	echo 'changeps1: false' >> ~/miniforge3/.condarc
	print_green 'installed conda'
}

function install_python_packages {
	~/miniforge3/bin/conda create -n ds_env python -y
	eval "$(~/miniforge3/bin/conda shell.posix activate ds_env)"
	pip install --no-input numpy scipy pandas tensorflow torch scikit-learn gensim spacy transformers langchain seaborn matplotlib "altair[all]"
	eval "$(~/miniforge3/bin/conda shell.posix deactivate)"
	print_green 'installed python packages'
}

function install_spark {
	spark_latest_version="$(curl -sL https://archive.apache.org/dist/spark/ | tail -4 | grep -oE '<a href="spark-.+/">' \
		| tr -d '<a href="spark-' | tr -d '/>')"
	curl -sL "https://archive.apache.org/dist/spark/spark-${spark_latest_version}/spark-${spark_latest_version}-bin-hadoop3.tgz" -o /tmp/spark.tgz
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
	eval "$(~/miniforge3/bin/conda shell.posix activate dbt)"
	pip install --no-input dbt-core dbt-bigquery dbt-postgres
	eval "$(~/miniforge3/bin/conda shell.posix deactivate)"
	print_green 'installed dbt'
}

function install_sadtalker {
	git clone --depth 1 https://github.com/OpenTalker/SadTalker.git ~/SadTalker
	~/miniforge3/bin/conda create -n sadtalker python=3.8 ffmpeg -y
	eval "$(~/miniforge3/bin/conda shell.posix activate sadtalker)"
	pip install --no-input torch==1.12.1 torchvision==0.13.1 torchaudio==0.12.1 dlib -r ~/SadTalker/requirements.txt
	eval "$(~/miniforge3/bin/conda shell.posix deactivate)"

	chmod +x ~/SadTalker/scripts/download_models.sh
	cd ~/SadTalker
	~/SadTalker/scripts/download_models.sh
	cd -
	print_green 'installed sadtalker'
}

function install_ollama {
	sudo sh -c "$(curl -fsSL https://ollama.com/install.sh)"
	ollama serve &
	sleep 10
	ollama pull llama3
	kill %1
	echo 'ollama serve &>/dev/null &' >> ~/.bashrc
	print_green 'installed ollama'
}

function main {
	install_apt_packages
	install_ohmyposh
	install_fzf
	install_z
	install_docker
	install_powershell
	install_r
	install_r_packages
	install_conda
	install_python_packages
	install_spark
	install_dbt
	install_sadtalker
	install_ollama
}

main

sudo curl -fsSL https://gist.githubusercontent.com/benjamin-chan/4ef37955eabf5fa8b9e70053c80b7d76/raw/57ff34139829e49652eec05d0d1c91488563f39e/R.nanorc \
	-o /usr/share/nano/R.nanorc
sudo curl -fsSL https://raw.githubusercontent.com/mitchell486/nanorc/master/powershell.nanorc -o /usr/share/nano/powershell.nanorc

cat >> ~/.bashrc <<-'EOF'
	alias edit_profile="nano ~/.bashrc"
	alias lm="ls -la"
	alias cat="batcat -p"
	alias llama3="ollama run llama3"
	# alias grep=rg
	# alias locate=plocate
	# alias btop="btop --utf-force"
EOF

yes | sudo unminimize
sudo updatedb
sudo rm -rf /tmp/*

print_green 'install.sh is done'