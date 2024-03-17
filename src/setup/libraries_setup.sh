#!/bin/bash

# This file performs the setup for a deployment machine/environment.

###############################################################################
# Azure CLI
###############################################################################

# Install prerequisite packages
sudo apt-get update
sudo apt-get install -y ca-certificates curl apt-transport-https lsb-release gnupg

# Download and install the Microsoft signing key
curl -sL https://packages.microsoft.com/keys/microsoft.asc | 
    gpg --dearmor | 
    sudo tee /etc/apt/trusted.gpg.d/microsoft.asc.gpg > /dev/null

# Add the Azure CLI repository
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | 
    sudo tee /etc/apt/sources.list.d/azure-cli.list

# Update repository information and install Azure CLI
sudo apt-get update
sudo apt-get install -y azure-cli


###############################################################################
# Terraform
###############################################################################

# Download Terraform binary
TERRAFORM_VERSION="1.0.0"  # Replace with the desired version
wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Unzip the downloaded file
unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Move the Terraform binary to a directory included in the PATH
sudo mv terraform /usr/local/bin/

# Verify installation
terraform --version


###############################################################################
# Docker
###############################################################################

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin


###############################################################################
# Kubectl
###############################################################################

# to install latest version
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
# to install specific version (might be needed to match the server version)
curl -LO https://dl.k8s.io/release/v1.27.9/bin/linux/amd64/kubectl


