#!/bin/bash

# Variables
SERVICE_FILE_SOURCE="./homebridge.service"
SERVICE_FILE_TARGET="/etc/systemd/system/homebridge.service"
HOME_USER="homebridge"
HOME_DIR="/home/$HOME_USER"
REPO_URL="https://github.com/levankhelo/rpi-fan-controller.git"
REPO_CLONE_PATH="$HOME_DIR/rpi-fan-controller"
FINAL_PATH="$HOME_DIR/.fan"
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
  sudo mkdir -p $HOME_DIR/.homebridge
  sudo chown -R $HOME_USER:$HOME_USER $HOME_DIR
fi

# 5. Install Homebridge globally using npm
echo "Installing Homebridge globally..."
sudo npm install -g homebridge --unsafe-perm

# 6. Clone the rpi-fan-controller repository
if [[ -d $FINAL_PATH ]]; then
  echo "Directory $FINAL_PATH already exists. Skipping clone."
else
  echo "Cloning rpi-fan-controller repository to $REPO_CLONE_PATH..."
  sudo -u $HOME_USER git clone $REPO_URL $REPO_CLONE_PATH

  # 7. Rename the directory to .fan
  echo "Renaming $REPO_CLONE_PATH to $FINAL_PATH..."
  sudo mv $REPO_CLONE_PATH $FINAL_PATH
  sudo chown -R $HOME_USER:$HOME_USER $FINAL_PATH
  sudo chmod -R 755 $FINAL_PATH
fi

# 8. Copy the service file to the correct location
echo "Copying service file to $SERVICE_FILE_TARGET..."
sudo cp $SERVICE_FILE_SOURCE $SERVICE_FILE_TARGET

# 9. Set proper permissions on the service file
echo "Setting permissions on the service file..."
sudo chmod 644 $SERVICE_FILE_TARGET

# 10. Reload systemd, enable and start the Homebridge service
echo "Enabling and starting the Homebridge service..."
sudo systemctl daemon-reload
sudo systemctl enable homebridge
sudo systemctl start homebridge

# 11. Confirm the service status
echo "Checking Homebridge service status..."
sudo systemctl status homebridge --no-pager

echo "Homebridge installation and setup completed successfully!"
