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
CUSTOM_LIST=/var/data/pihole/custom.list


# Initialize the Cluster
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=$IP
JTOKEN = sudo kubeadm token create --print-join-command

# Create mount points for working volumes

echo -e "\e[1;32mCreating bind-mount volumes\e[0m."
# Cip Services
mkdir -p /var/data/traefik
cp -r Configuration_Files/traefik /var/data/traefik



# Create SSL certificates
mkdir -p $(pwd)/traefik/certs/
echo -e "\e[1;32mCreating self-signed certificate for Traefik\e[0m."
openssl req -newkey rsa:2048 -nodes -keyout /var/data/traefik/certs/cip.key -x509 -sha256 -days 365 -out /var/data/traefik/certs/cip.crt -subj "/C=WK/ST=MOUNTAINS/L=JABARI/O=CIP/OU=SERVICES/CN=*.${DOMAIN}"

echo "Create an Administrator name for Grafana services"
while true; do
	read -s -p "Account Name: " prom_admin
	echo
	read -s -p "Account Name (again): " prom_admin2
	echo 
	[ "$prom_admin" = "$prom_admin2" ] && break
	echo "Please try again"
done
export ADMIN_USER=$prom_admin

echo "Create an Administrator Password for Grafana services"
echo "Using special characters may break the service."
while true; do
	read -s -p "Account Name: " prom_pass
	echo
	read -s -p "Account Name (again): " prom_pass2
	echo 
	[ "$prom_pass" = "$prom_pass2" ] && break
	echo "Please try again"
done
export HASHED_PASSWORD=$(openssl passwd -apr1 $prom_pass)
export DOMAIN

#build Cron & Cortex
docker build ../Build_Files/Cortex/. -t cortex_analyzers:local
docker build ../Build_Files/Cron/. -t cron:local



