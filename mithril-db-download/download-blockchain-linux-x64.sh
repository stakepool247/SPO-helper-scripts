#!/bin/bash

# Record start time
start_time=$(date +%s)

# Default values
DOWNLOAD_DIR="/home/cardano/cnode"
NETWORK="mainnet"
NODE_CHOICE=""
NETWORK_CHOICE=""

# Check if cardano-node process is running
if pgrep -x "cardano-node" > /dev/null; then
    if [[ -z "$NODE_CHOICE" ]]; then
        NODE_CHOICE=${1:-""}
    fi
    if [[ -z "$NODE_CHOICE" ]]; then
        echo "Warning: cardano-node process is running. It should be stopped before proceeding."
        echo "1) Cancel process"
        echo "2) Continue anyway"
        read -p "Enter your choice (1/2): " NODE_CHOICE
    fi
    case $NODE_CHOICE in
        1)
            echo "Operation cancelled by user."
            exit 0
            ;;
        2)
            echo "Continuing despite cardano-node running."
            ;;
        *)
            echo "Invalid selection. Exiting."
            exit 1
            ;;
    esac
fi

# Ask for custom download directory (press Enter to use default)
if [[ -z "$DOWNLOAD_DIR" ]]; then
    read -p "Enter download directory [default: $DOWNLOAD_DIR]: " input_dir
    DOWNLOAD_DIR="${input_dir:-$DOWNLOAD_DIR}"
fi

# Prompt to select the Cardano network
if [[ -z "$NETWORK_CHOICE" ]]; then
    echo "Select the network:"
    echo "1) Mainnet"
    echo "2) Preprod"
    echo "3) Preview"
    echo "4) Sanchonet"
    read -p "Enter the number corresponding to your choice: " NETWORK_CHOICE
fi

# Set network variables based on choice
case $NETWORK_CHOICE in
    1)
        MITHRIL_NETWORK="release-mainnet"
        CARDANO_NETWORK="mainnet"
        AGGREGATOR_ENDPOINT="https://aggregator.release-mainnet.api.mithril.network/aggregator"
        GENESIS_VERIFICATION_KEY="https://raw.githubusercontent.com/input-output-hk/mithril/main/mithril-infra/configuration/release-mainnet/genesis.vkey"
        ;;
    2)
        MITHRIL_NETWORK="release-preprod"
        CARDANO_NETWORK="preprod"
        CARDANO_MAGIC_ID="1"
        AGGREGATOR_ENDPOINT="https://aggregator.release-preprod.api.mithril.network/aggregator"
        GENESIS_VERIFICATION_KEY="https://raw.githubusercontent.com/input-output-hk/mithril/main/mithril-infra/configuration/release-preprod/genesis.vkey"
        ;;
    3)
        MITHRIL_NETWORK="pre-release-preview"
        CARDANO_NETWORK="preview"
        CARDANO_MAGIC_ID="2"
        AGGREGATOR_ENDPOINT="https://aggregator.pre-release-preview.api.mithril.network/aggregator"
        GENESIS_VERIFICATION_KEY="https://raw.githubusercontent.com/input-output-hk/mithril/main/mithril-infra/configuration/pre-release-preview/genesis.vkey"
        ;;
    4)
        MITHRIL_NETWORK="testing-sanchonet"
        CARDANO_NETWORK="sanchonet"
        CARDANO_MAGIC_ID="4"
        AGGREGATOR_ENDPOINT="https://aggregator.testing-sanchonet.api.mithril.network/aggregator"
        GENESIS_VERIFICATION_KEY="https://raw.githubusercontent.com/input-output-hk/mithril/main/mithril-infra/configuration/testing-sanchonet/genesis.vkey"
        ;;
    *)
        echo "Invalid selection. Exiting."
        exit 1
        ;;
        
esac

# Navigate to download directory
cd "$DOWNLOAD_DIR" || exit

# Check if db folder is empty
if [ -d "$DOWNLOAD_DIR/db" ] && [ -n "$(ls -A "$DOWNLOAD_DIR/db")" ]; then
    read -p "The $DOWNLOAD_DIR/db folder is not empty. Do you want to delete it? (y/n): " confirm_delete
    if [[ "$confirm_delete" != "y" ]]; then
        echo "Operation cancelled by user."
        exit 0
    fi
    echo "Deleting the $DOWNLOAD_DIR/db folder."
    rm -rf "$DOWNLOAD_DIR/db"
else
    echo "Database folder is empty or does not exist. Proceeding with download."
    rm -rf "$DOWNLOAD_DIR/db"
fi

# Get the latest Mithril release from GitHub
latest_release=$(curl -s https://api.github.com/repos/input-output-hk/mithril/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3)}')
wget "https://github.com/input-output-hk/mithril/releases/download/${latest_release}/mithril-${latest_release}-linux-x64.tar.gz" -O mithril-latest.tar.gz

# Unzip the downloaded file into the download directory
tar -xvzf mithril-latest.tar.gz -C "$DOWNLOAD_DIR"

# Clean up the downloaded archive
rm mithril-latest.tar.gz

# Set environment variables
export CARDANO_NETWORK="$CARDANO_NETWORK"
export AGGREGATOR_ENDPOINT="$AGGREGATOR_ENDPOINT"
export GENESIS_VERIFICATION_KEY=$(wget -q -O - "$GENESIS_VERIFICATION_KEY")
[ -n "$CARDANO_MAGIC_ID" ] && export CARDANO_MAGIC_ID="$CARDANO_MAGIC_ID"

# Ensure the mithril-client is executable and in the current path
chmod +x "$DOWNLOAD_DIR/mithril-client"

# Run mithril-client command to download the latest snapshot
if "$DOWNLOAD_DIR/mithril-client" cardano-db download latest; then
    echo "Snapshot download successful."
else
    echo "Failed to download snapshot. Please check for errors."
    exit 1
fi

# Record end time and calculate duration
end_time=$(date +%s)
duration=$((end_time - start_time))
echo "Process completed in $(date -ud @$duration +'%H:%M:%S') (hours:minutes:seconds)"

exit 0