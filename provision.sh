#!/bin/bash

# Variables
SERVICE_FILE_SOURCE="./homebridge.service"
SERVICE_FILE_TARGET="/etc/systemd/system/homebridge.service"
HOME_USER="homebridge"
HOME_DIR="/home/$HOME_USER"
SSH_KEY_PATH="$HOME_DIR/.ssh/id_rsa"
REPO_URL="https://github.com/levankhelo/rpi-fan-controller.git"
REPO_CLONE_PATH="$HOME_DIR/rpi-fan-controller"
FINAL_PATH="$HOME_DIR/.fan"
NODEJS_VERSION="14"  # Specify Node.js version (adjust if needed)

echo "Starting Homebridge installation and setup..."

# Check if the service file exists next to the script
if [[ ! -f $SERVICE_FILE_SOURCE ]]; then
  echo "Error: Service file ($SERVICE_FILE_SOURCE) not found!"
  exit 1
fi

# Update and install necessary packages
echo "Updating system and installing required packages..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl software-properties-common git make gcc g++ systemd dnsutils net-tools nmap arp-scan iputils-ping

# Install Homebridge
echo "Installing Homebridge globally..."
sudo apt-get install -y homebridge

# Create homebridge user if it doesn't exist
if id "$HOME_USER" &> /dev/null; then
  echo "User $HOME_USER already exists."
  sudo passwd -d $HOME_USER
else
  echo "Creating homebridge user..."
  sudo useradd -m -s /bin/bash $HOME_USER
  sudo passwd -d $HOME_USER  # No password required for the homebridge user
  sudo mkdir -p $HOME_DIR/.homebridge
  sudo chown -R $HOME_USER:$HOME_USER $HOME_DIR
fi

# Generate SSH key for homebridge user if not already present
if [[ ! -f $SSH_KEY_PATH ]]; then
  echo "Generating SSH key for $HOME_USER..."
  sudo -u $HOME_USER mkdir -p $HOME_DIR/.ssh
  sudo -u $HOME_USER ssh-keygen -t rsa -b 4096 -f $SSH_KEY_PATH -N ""
  echo "SSH key generated at $SSH_KEY_PATH"
else
  echo "SSH key already exists at $SSH_KEY_PATH. Skipping generation."
fi

# Clone the rpi-fan-controller repository
if [[ -d $FINAL_PATH ]]; then
  echo "Directory $FINAL_PATH already exists. Skipping clone."
else
  echo "Cloning rpi-fan-controller repository to $REPO_CLONE_PATH..."
  sudo -u $HOME_USER git clone $REPO_URL $REPO_CLONE_PATH

  # Rename the directory to .fan
  echo "Renaming $REPO_CLONE_PATH to $FINAL_PATH..."
  sudo mv $REPO_CLONE_PATH $FINAL_PATH
  sudo chown -R $HOME_USER:$HOME_USER $FINAL_PATH
  sudo chmod -R 755 $FINAL_PATH
fi

# Copy the service file to the correct location
echo "Copying service file to $SERVICE_FILE_TARGET..."
sudo cp $SERVICE_FILE_SOURCE $SERVICE_FILE_TARGET

# Set proper permissions on the service file
echo "Setting permissions on the service file..."
sudo chmod 644 $SERVICE_FILE_TARGET

# Reload systemd, enable and start the Homebridge service
echo "Enabling and starting the Homebridge service..."
sudo systemctl daemon-reload
sudo systemctl enable homebridge
sudo systemctl start homebridge

# Confirm the service status
echo "Checking Homebridge service status..."
sudo systemctl status homebridge --no-pager

echo "Homebridge installation and setup completed successfully!"
