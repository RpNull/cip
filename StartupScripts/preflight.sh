#!/bin/bash

# Check to see if root level permissions
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo -e "\e[1;31mThis script needs root privileges to run. Please try again using sudo.\e[0m"
    exit
fi

# Set your IP address as a variable. This is for instructions below.
IP="$(hostname -I | sed -e 's/[[:space:]]*$//' | awk '{print $1}')"

# Custom domain; default is cip.local
DOMAIN=cip.local

# Update your Host file
echo -e "${IP} ${HOSTNAME}" | tee -a /etc/hosts
echo -e "${IP} ${DOMAIN}" | tee -a /etc/hosts

# Add Docker && Kubernetes repositories

apt-get update
apt-get install -y apt-transport-https ca-certificates ne curl gnupg2 software-properties-common

# Add docker repositry
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository \
          "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
           $(lsb_release -cs) \
           stable"
           
# Add kubernetes repository           
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF | tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

# Add Helm Repo
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
sudo apt-get install apt-transport-https --yes
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update


# Install Docker && Kubernetes
apt-get install -y docker-ce docker-ce-cli containerd.io kubelet kubeadm kubectl helm

# Set Docker Engine to Experimental for metrics collection, change cgroup driver to systemd

mkdir -p /etc/docker/
cp ./Configuration_Files/daemon.json /etc/docker/daemon.json

# Adjust kernel map count for Elastic requirements
if ! grep -q "vm.max_map_count=262144" /etc/systctl.conf;then
	sysctl -w vm.max_map_count=262144
fi

# Ensure SWAP partitioning is disabled, this will require a reboot.

sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab


echo "Please modify /usr/lib/systemd/system/docker.service per the documentation."
echo "Please reboot the system, and then run takeoff.sh"

