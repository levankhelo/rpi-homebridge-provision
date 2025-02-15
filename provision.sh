#!/bin/bash

# Variables
SERVICE_FILE_SOURCE="./homebridge.service"
SERVICE_FILE_TARGET="/etc/systemd/system/homebridge.service"
HOME_USER="homebridge"
NODEJS_VERSION="14"  # Specify Node.js version (adjust if needed)

echo "Starting Homebridge installation and setup..."

# 1. Check if the service file exists next to the script
if [[ ! -f $SERVICE_FILE_SOURCE ]]; then
  echo "Error: Service file ($SERVICE_FILE_SOURCE) not found!"
  exit 1
fi

# 2. Update and install dependencies
echo "Updating system and installing required packages..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl software-properties-common git make gcc g++ systemd

# 3. Install Node.js (if not already installed)
if ! command -v node &> /dev/null; then
  echo "Installing Node.js..."
  curl -sL https://deb.nodesource.com/setup_${NODEJS_VERSION}.x | sudo -E bash -
  sudo apt install -y nodejs
else
  echo "Node.js is already installed."
fi

# 4. Create homebridge user if it doesn't exist
if id "$HOME_USER" &> /dev/null; then
  echo "User $HOME_USER already exists."
else
  echo "Creating homebridge user..."
  sudo useradd -m -s /bin/bash $HOME_USER
  sudo passwd -d $HOME_USER  # No password required for the homebridge user
  sudo mkdir -p /home/$HOME_USER/.homebridge
  sudo chown -R $HOME_USER:$HOME_USER /home/$HOME_USER
fi

# 5. Install Homebridge globally using npm
echo "Installing Homebridge globally..."
sudo npm install -g homebridge --unsafe-perm

# 6. Copy the service file to the correct location
echo "Copying service file to $SERVICE_FILE_TARGET..."
sudo cp $SERVICE_FILE_SOURCE $SERVICE_FILE_TARGET

# 7. Set proper permissions on the service file
echo "Setting permissions on the service file..."
sudo chmod 644 $SERVICE_FILE_TARGET

# 8. Reload systemd, enable and start the Homebridge service
echo "Enabling and starting the Homebridge service..."
sudo systemctl daemon-reload
sudo systemctl enable homebridge
sudo systemctl start homebridge

# 9. Confirm the service status
echo "Checking Homebridge service status..."
sudo systemctl status homebridge --no-pager

echo "Homebridge installation and setup completed successfully!"
