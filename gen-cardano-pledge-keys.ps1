# Clear console screen
Clear-Host

# Create a folder for the keys in the Documents folder
$cardano_files_folder = $env:USERPROFILE + "\Documents\cardano-files"

# Create a folder for the keys in the Documents folder
if (Test-Path $cardano_files_folder) {
    Write-Host "Folder already exists. Skipping creation." -ForegroundColor Green
}
else {
    New-Item -ItemType Directory -Path $cardano_files_folder
    Write-Host "Folder created." -ForegroundColor Green
}


# Change the directory to the folder
Set-Location $cardano_files_folder

# Downloading the latest release of cardano-wallet
Write-Host "Downloading latest release of cardano-wallet..." -ForegroundColor yellow


# get the latest release version from github api
$cardano_wallet_latest_release_version = (Invoke-WebRequest -Uri 'https://api.github.com/repos/cardano-foundation/cardano-wallet/releases/latest' -UseBasicParsing).Content | ConvertFrom-Json | Select-Object -ExpandProperty tag_name

# print the latest release version
Write-Host "Latest release version: $cardano_wallet_latest_release_version" -ForegroundColor Green

# generate download URL for the latest release
$download_url = "https://github.com/cardano-foundation/cardano-wallet/releases/download/"+ $cardano_wallet_latest_release_version + "/cardano-wallet.exe-" + $cardano_wallet_latest_release_version + "-win64.zip"

# print the download URL
Write-Host "Download URL: $download_url" -ForegroundColor Green


try {
    $download_file = "cardano-wallet-exe-" + $cardano_wallet_latest_release_version + "-win64.zip"

    # check if the file already exists. skip if exists
    if (Test-Path $download_file) {
        Write-Host "File already exists. Skipping download."-ForegroundColor Green
    }
    else {
        # download the latest release
        Invoke-WebRequest -Uri $download_url -OutFile $download_file
        Write-Host "Download complete." -ForegroundColor Yellow
    }
    
    # check if the folder already exists. skip if exists
    if (Test-Path ".\cardano-hw-cli") {
        Write-Host "Folder already exists. Skipping creation." -ForegroundColor Green
    }
    else {
        # Extract files from the downloaded archive
        Write-Host "Extracting files..." -ForegroundColor Yellow
        Expand-Archive -Path $download_file -DestinationPath .\cardano-wallet -Force
        Write-Host "Extracting complete." -ForegroundColor Yellow
    } 


}
catch [Exception] {
    Write-Host "Error: $($PSItem.Exception.Message)"
}

# Downloading the latest Cardano HW cli
Write-Host "Downloading latest Cardano HW cli..." -ForegroundColor Yellow

try {
    # get the latest release version from github api
    $cardano_hw_latest_release_version = (Invoke-WebRequest -Uri 'https://api.github.com/repos/vacuumlabs/cardano-hw-cli/releases/latest' -UseBasicParsing).Content | ConvertFrom-Json | Select-Object -ExpandProperty tag_name

    # print the latest release version
    Write-Host "Latest release version: $cardano_hw_latest_release_version" -ForegroundColor Green

    # remove the first letter from the version
    $cardano_hw_file_name_latest_release_version = $cardano_hw_latest_release_version.Substring(1)

    # generate download URL for the latest release
    $download_url = "https://github.com/vacuumlabs/cardano-hw-cli/releases/download/"+ $cardano_hw_latest_release_version + "/cardano-hw-cli-" + $cardano_hw_file_name_latest_release_version + "_windows-x64.zip"
              
    $download_file = "cardano-hw-cli-"+ $cardano_hw_latest_release_version + "_windows-x64.zip"

    if (Test-Path $download_file) {
        Write-Host "File already exists. Skipping download." -ForegroundColor Yellow
    }
    else {
        # download the latest release
        Invoke-WebRequest -Uri $download_url -OutFile $download_file
        Write-Host "Download complete." -ForegroundColor Yellow
    }


    # check if the folder already exists. skip if exists
    if (Test-Path ".\cardano-hw-cli") {
        Write-Host "Folder already exists. Skipping creation." -ForegroundColor Green
    }
    else {
        # Extract files from the downloaded archive
        Write-Host "Extracting files..." -ForegroundColor Yellow
        Expand-Archive -Path $download_file -DestinationPath .\cardano-hw-cli -Force
        Write-Host "Extracting complete." -ForegroundColor Yellow
    }


}
catch [Exception] {
    Write-Host "Error: $($PSItem.Exception.Message)"
}

Write-Host " ---------- Generating pledge keys for stake pool registration ----------" -ForegroundColor Cyan -BackgroundColor Red


# Generating cryptographic keys and certificates
## Generating staking cli keys
Write-Host "Generating staking cli keys..." -ForegroundColor Yellow
.\cardano-wallet\cardano-cli.exe stake-address key-gen --verification-key-file pool.staking.vkey --signing-key-file pool.staking.skey


# ask if HW is connected and Cardano app is open and waiting for commands
Write-Host "Is your HW connected and Cardano app is open and waiting for commands? (y/n)" -ForegroundColor Red
$answer = Read-Host

# If not connected or the app is not open, ask to connect and open the app
if ($answer -ne "y") {
    Write-Host "Please connect your HW and open Cardano app and wait for commands." -ForegroundColor Red
    Write-Host "Press any key to continue..."
    $null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Generating payment HW keys
Write-Host "Generating payment HW keys (public)..." -ForegroundColor Yellow
.\cardano-hw-cli\cardano-hw-cli\cardano-hw-cli.exe  address key-gen --path 1852H/1815H/0H/0/0 --verification-key-file pool.payment.vkey --hw-signing-file pool.payment.hwsfile

# Generating the payment Address
Write-Host "Generating payment address..." -ForegroundColor Yellow
.\cardano-wallet\cardano-cli.exe address build --payment-verification-key-file pool.payment.vkey --staking-verification-key-file pool.staking.vkey  --mainnet > pool.payment.addr


# Building a stake Address
Write-Host "Building a stake Address..." -ForegroundColor Yellow
.\cardano-wallet\cardano-cli.exe stake-address build --stake-verification-key-file pool.staking.vkey --out-file pool.stake.addr --mainnet

# Create the staking registration certificate
Write-Host "Creating the staking registration certificate..." -ForegroundColor Yellow
.\cardano-wallet\cardano-cli.exe stake-address registration-certificate --stake-verification-key-file pool.staking.vkey --out-file pool.staking.cert

# Print pledge address content (in RED)
Write-Host "Pledge address (where you will store your Pledge ADA):" - ForegroundColor Green
Get-Content .\pool.payment.addr | Foreach-Object { Write-Host $_ -ForegroundColor Red -BackgroundColor white }

# zip the created files
Write-Host "Zipping the created files..." -ForegroundColor Yellow
Compress-Archive -Path .\pool.staking.vkey, .\pool.staking.skey, .\pool.payment.vkey, .\pool.stake.addr, .\pool.staking.cert -DestinationPath .\cardano-keys.zip -Force

# print the path to the created zip file
Write-Host "The created files are zipped in the following file:" -ForegroundColor Green
Write-Host "$PWD\cardano-keys.zip" -ForegroundColor Yellow

# Open the folder where the zip file is located
Write-Host "Opening the folder where the zip file is located..." -ForegroundColor Yellow    
Start-Process $PWD
