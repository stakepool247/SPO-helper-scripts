#!/bin/bash
# get latest cardano-node version from github releases
clear 

# Declare variables
FILENAME="cardano-node-1.35.7-linux.tar.gz"
NODE_VERSION=$(cardano-node version | grep -oP '(?<=cardano-node )[0-9\.]+')
BIN_DIR="$HOME/.local/bin"

# Print information
echo -e "\e[1mStarting Cardano node update process...\e[0m"
echo -e "\e[1mCurrent node version: $NODE_VERSION\e[0m"
echo -e "\e[1mDownloading new binaries...\e[0m"

# Create directories
mkdir -p "$BIN_DIR/$NODE_VERSION"

# Backup existing binary files
cp "$BIN_DIR/cardano-node" "$BIN_DIR/$NODE_VERSION/"
cp "$BIN_DIR/cardano-cli" "$BIN_DIR/$NODE_VERSION/"


# Stop Cardano node service
echo -e "\e[1mStopping Cardano node service...\e[0m"
sudo systemctl stop cardano-node.service

# Download and install new binary files
wget -q "https://update-cardano-mainnet.iohk.io/cardano-node-releases/$FILENAME" -P "$BIN_DIR/$NODE_VERSION"
tar -xzf "$BIN_DIR/$NODE_VERSION/$FILENAME" -C "$BIN_DIR/"

# Start Cardano node service
echo -e "\e[1mStarting Cardano node service...\e[0m"
sudo systemctl start cardano-node.service

# Delete unnecessary files
echo -e "\e[1mCleaning up...\e[0m"
rm "$BIN_DIR/$NODE_VERSION/$FILENAME"

# Check version of installed Cardano node
echo -e "\e[1mNew node version: $(cardano-node version | grep -oP '(?<=cardano-node )[0-9\.]+')\e[0m"
