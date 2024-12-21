#!/bin/bash -xe

function record() {
  echo "[$(date +%Y%m%d-%H:%M:%S)] $1" | tee -a $HOME/what_is_installed.txt
}

function install_prerequisites() {
    echo "Installing prerequisites..."
    sudo apt-get install -y -qq \
        apt-transport-https ca-certificates curl git gnupg \
        software-properties-common unzip wget zip
}

function install_python() {
    echo "Installing Python..."
    sudo apt-get install -y -qq python3.8 python3.8-dev python3-pip
    sudo python3.8 -m pip install --quiet --upgrade pip
    record "$(python3.8 -m pip -V)"
}

function install_golang() {
    echo "Installing Golang..."
    curl -L -o go.tar.gz https://golang.org/dl/go1.17.2.linux-amd64.tar.gz
    sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go.tar.gz
    rm -rf go.tar.gz
    cat >> ${HOME}/.profile <<EOF
export PATH=\$PATH:/usr/local/go/bin
EOF
    record "$(/usr/local/go/bin/go version)"
}

function install_docker() {
    echo "Installing docker..."
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y -qq \
        docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin
    sudo usermod -aG docker $USER
    record "$(docker --version)"
}

function install_homebrew() {
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    test -d ~/.linuxbrew && eval "$(~/.linuxbrew/bin/brew shellenv)"
    test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >> ~/.bashrc
}

function install_brew_packages() {
    # Simple binaries can be installed by homebrew's `brew install` command
    echo "Installing Homebrew packages..."
    local l_brew_packages=(
        dive
        govc
        helm
        jq
        minamijoyo/hcledit/hcledit
        okta-aws-cli
        sops
        spacelift-io/spacelift/spacectl
        yq
    )
    for package in "${l_brew_packages[@]}"; do
        brew install $package
        record "$(brew list $package)"
    done
}

function install_aws_cli() {
    echo "Installing AWS CLI..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip && sudo ./aws/install
    rm -rf awscliv2.zip aws
    record "$(aws --version)"
}

function install_gcloud_cli() {
    echo "Installing Google Cloud CLI..."
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
    sudo apt-get update
    sudo apt-get install google-cloud-cli -y
    gcloud components install kubectl
    gcloud components install gke-gcloud-auth-plugin
    record "$(gcloud version)"
}

function install_azure_cli() {
    echo "Installing Azure CLI..."
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo /bin/bash
    record "$(az --version)"
}

function set_git_config() {
    echo "Setting git config..."
    git config --global alias.co checkout
    git config --global alias.br branch
    git config --global alias.ci commit
    git config --global alias.st status
    git config --global pager.branch false
}


function what_is_next() {
    echo "What's next?"
    echo " * Mount configuration folders from your local machine to the VM"
    echo "WINDOWS_USER=<windows-username>"
    echo "ln -s /mnt/c/Users/\${WINDOWS_USER}/.ssh ~/.ssh"
    echo "ln -s /mnt/c/Users/\${WINDOWS_USER}/.aws ~/.aws"
    echo "ln -s /mnt/c/Users/\${WINDOWS_USER}/.azure ~/.azure"
    echo "ln -s /mnt/c/Users/\${WINDOWS_USER}/.config ~/.config"
    echo "ln -s /mnt/c/Users/\${WINDOWS_USER}/.jenkins ~/.jenkins"
    echo "ln -s /mnt/c/Users/\${WINDOWS_USER}/.kube ~/.kube"
    echo "ln -s /mnt/c/Users/\${WINDOWS_USER}/.spacelift ~/.spacelift"
    echo "chmod 600 ~/.ssh/*"
}

install_prerequisites
install_python
install_golang
install_docker
install_homebrew
install_brew_packages
install_aws_cli
install_gcloud_cli
install_azure_cli
set_git_config
what_is_next
