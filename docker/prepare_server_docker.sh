#!/bin/bash
## Before you run this script, your filesystem (the docker subvolume part) needs to be configured !!
## After you run this script, you can run docker-compose.yml and enjoy your server!
#
# See https://github.com/zilexa/Homeserver
sudo apt -y update
# ____________________
# Install server tools
# ____________________
# SSH
sudo apt -y install ssh
sudo systemctl enable --now ssh
# firewall of Ubuntu is disabled by default, I keep it like that but do add the rule in case fw is activated in the future.
sudo ufw allow ssh 

# Install lm-sensors
sudo apt install lm-sensors

# Install Powertop
sudo apt -y install powertop
# Create a service file to run powertop --auto-tune at boot
sudo tee -a /etc/systemd/system/powertop.service << EOF
[Unit]
Description=PowerTOP auto tune

[Service]
Type=idle
Environment="TERM=dumb"
ExecStart=/usr/sbin/powertop --auto-tune

[Install]
WantedBy=multi-user.target
EOF
# Enable the service
sudo systemctl daemon-reload
sudo systemctl enable powertop.service
# Tune system now
sudo powertop --auto-tune
# Start the service
sudo systemctl start powertop.service


# NFS Server - 15%-30% faster than SAMBA/SMB shares
sudo apt -y install nfs-server

echo "========================================================================="
echo "                                                                         "
echo "               The following tools have been installed:                  "
echo "                                                                         "
echo "                SSH - secure terminal & sftp connection                  "
echo "           POWERTOP - to optimise power management automatically         "
echo "               A systemd service to run Powertop at boot                 "
echo "          LMSENSORS - for the OS to access its diagnostic sensors        "
echo "           NFS - the fastest network protocol to share folders           "
echo "                                                                         "
echo "========================================================================="
echo "to configure NFSv4.2 with server-side copy:
echo "(save this URL and hit a key to continue): 
read -p "https://github.com/zilexa/Homeserver/tree/master/network%20share%20(NFSv4.2)"
echo "                                                               "
echo "==============================================================="
echo "                                                               "
echo "lmsensors will now scan & configure your sensors:              " 
echo "Just accept & confirm everything!                              "
echo "---------------------------------------------------------------"
read -p "hit a key to start... "
echo  sudo sensors-detect --auto"
echo "==============================================================="
echo "                                                               "
echo "PiVPN install wizard will be downloaded & started, a few hints:"
echo "1) Select Wireguard.                                           "
echo "2) Plan on running AdGuard Home with/without Unbound?          "
echo "Then fill in your own server LAN IP as the DNS server.         "
echo "If not, e select Quad9 or similar DNS server.                  "
echo "---------------------------------------------------------------"
read -p "hit a key to start... "
# PiVPN ~ Install & configure wizard
curl -L https://install.pivpn.io | bash  
echo "==============================================================="
echo "                                                               "
echo "Netdata monitoring tool install wizard will start              "
echo "---------------------------------------------------------------"
read -p  hit a key to start... "
# Netdata ~ install wizard
bash <(curl -Ss https://my-netdata.io/kickstart.sh)

# ______________________________________________________________
# Install Docker 
# --------------------------------------------------------------
# Install Docker, Docker-Compose and bash completion for Compose
wget -qO - https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt -y update
sudo apt -y install docker-ce docker-ce-cli containerd.io
sudo curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo curl -L https://raw.githubusercontent.com/docker/compose/1.26.2/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose

# ______________________________________________________________
# Configure Docker
# --------------------------------------------------------------
# Make docker-compose file an executable file and add the current user to the docker container
sudo chmod +x /usr/local/bin/docker-compose
sudo usermod -aG docker ${USER}

# Create the docker folder
sudo mkdir -p $HOME/docker
sudo setfacl -Rdm g:docker:rwx ~/docker
sudo chmod -R 755 ~/docker
# Get environment variables to be used by Docker (i.e. requires TZ in quotes)
sudo wget -O $HOME/docker/.env https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/.env

# Get docker compose file
sudo wget -O $HOME/docker/docker-compose.yml https://raw.githubusercontent.com/zilexa/Homeserver/master/docker/docker-compose.yml


# __________________________________________________________________________________
# Docker per-application configuration, required before starting the apps container
# ----------------------------------------------------------------------------------

# FileRun & ElasticSearch ~ requirements
# ---------------------------------------------
# Create folder and set permissions
sudo mkdir -p $HOME/docker/filerun/esearch
sudo chown -R $USER:$USER $HOME/docker/filerun/esearch
sudo chmod 777 $HOME/docker/filerun/esearch
# IMPORTANT! Should be the same user:group as the owner of the personal data you access via FileRun!
sudo mkdir -p $HOME/docker/html
sudo chown -R $USER:$USER $HOME/docker/html
sudo chmod 755 $HOME/docker/filerun/esearch
# Change OS virtual mem allocation as it is too low by default for ElasticSearch
sudo sysctl -w vm.max_map_count=262144
# Make this change permanent
sudo sh -c "echo 'vm.max_map_count=262144' >> /etc/sysctl.conf"

# Required on Ubuntu systems if you will run your own DNS resolver and/or adblocking DNS server.
# ---------------------------------------------
sudo systemctl disable systemd-resolved.service
sudo systemctl stop systemd-resolved.service
echo "dns=default" | sudo tee -a /etc/NetworkManager/NetworkManager.conf
echo "----------------------------------------------------------------------------------"
echo "To support running your own DNS server on Ubuntu, via docker or bare, disable Ubuntu's built in DNS resolver now."
echo "----------------------------------------------------------------------------------"
echo "Move dns=default to the [MAIN] section by manually deleting it and typing it."
echo "AFTER you have done that, save changes via CTRL+O, exit the editor via CTRL+X."
read -p "ready to do this? Hit a key..."
sudo nano /etc/NetworkManager/NetworkManager.conf
sudo rm /etc/resolv.conf
sudo systemctl restart NetworkManager.service
echo "All done, if there were errors, go through the script manually, find and execute the failed commands."
