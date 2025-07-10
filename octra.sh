#!/bin/bash

RED='\033[0;31m'         # Error
YELLOW='\033[0;33m'       # Warning
DEEP_GREEN='\033[0;32m'   # Success
HGREEN='\033[0;36m'      # Runtime/Info
NC='\033[0m'             # No Color
BOLD='\033[1m'           # Bold text

# --- Functions ---

type_text() {
    local text="$1"
    local delay="${2:-0.05}"
    
    for (( i=0; i<${#text}; i++ )); do
        echo -n "${text:$i:1}"
        sleep "$delay"
    done
    echo ""
}

MrXintro() {
    clear
    echo ""

    echo -e "${BOLD}${HGREEN}"
    echo "███╗   ███╗██████╗        ██╗  ██╗"
    echo "████╗ ████║██╔══██╗       ╚██╗██╔╝"
    echo "██╔████╔██║██████╔╝        ╚███╔╝ "
    echo "██║╚██╔╝██║██╔══██╗        ██╔██╗ "
    echo "██║ ╚═╝ ██║██║  ██║██╗    ██╔╝ ██╗"
    echo "╚═╝     ╚═╝╚═╝  ╚═╝╚═╝    ╚═╝  ╚═╝"

    echo "                 Github: http://github.com/iamxlord"
    echo -e "                 Twitter: http://x.com/iamxlord${NC}"
    echo ""
    sleep 1
    echo -e "${HGREEN}"
    type_text "Welcome to the Octra Testnet wallet Manager!" 0.09
    type_text "This script will help you set-up & manage your Octra Testnet Wallet Interactions" 0.04
    type_text "Script parsed with love & Supremacy" 0.1
    echo ""
    type_text "Press any key to continue..." 0.03
    echo -e "${NC}"
    read -n 1 -s
    echo ""
}

check_sudo_privileges() {
    if ! sudo -n true 2>/dev/null; then
        echo -e "${RED}SUDO (elevated sudo privilege not authorized on your device;)${NC}"
        echo -e "${RED}Please ensure you have sudo privileges and try again.${NC}"
        exit 1
    fi
}

check_internet_connection() {
    echo -e "${HGREEN}Checking internet connection...${NC}"
    if ping -q -c 1 google.com &>/dev/null && ping -q -c 1 github.com &>/dev/null; then
        echo -e "${DEEP_GREEN}Internet connection is active.${NC}"
        return 0
    else
        echo -e "${RED}Error: No internet connection. Please check your network and try again.${NC}"
        return 1
    fi
}

get_ip_address() {
    local ip=""
    if command -v curl &>/dev/null; then
        ip=$(curl -s ifconfig.me)
    elif command -v wget &>/dev/null; then
        ip=$(wget -qO- ifconfig.me)
    fi
    echo "$ip"
}

install_wallet_generator() {
    clear
    echo -e "${HGREEN}--- Option 1: Wallet Generator Installer ---${NC}"
    echo ""

    if ! check_internet_connection; then
        read -n 1 -s -p "Press any key to return to the main menu..."
        return
    fi

    echo -e "${HGREEN}Installing necessary dependencies...${NC}"
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y curl git build-essential ufw unzip

    echo -e "${HGREEN}Installing Bun...${NC}"
    curl -fsSL https://bun.sh/install | bash
    export PATH="$HOME/.bun/bin:$PATH"

    echo -e "${HGREEN}Cloning Octa Wallet Generator repository...${NC}"
    if [ -d "wallet-gen" ]; then
        echo -e "${YELLOW}Wallet-gen directory already exists. Pulling latest changes...${NC}"
        cd wallet-gen
        git pull
    else
        git clone https://github.com/octra-labs/wallet-gen.git
        cd wallet-gen
    fi

    echo -e "${HGREEN}Installing project dependencies with Bun...${NC}"
    bun install

    echo -e "${HGREEN}Adding tweetnacl manually if needed...${NC}"
    bun add tweetnacl

    echo -e "${HGREEN}Allowing port 8888 through UFW...${NC}"
    sudo ufw allow 8888

    echo -e "${HGREEN}Starting the wallet generator...${NC}"
    ./wallet-generator.sh &
    local PID=$!
    sleep 20

    echo -e "${DEEP_GREEN}Wallet generator installed successfully and running!${NC}"
    echo ""

    local ip_address=$(get_ip_address)
    local wallet_url=""

    if [ -z "$ip_address" ]; then
        wallet_url="http://127.0.0.1:8888 (personal PC)"
        echo -e "${YELLOW}Could not determine public IP. Assuming local PC.${NC}"
    else
        wallet_url="http://${ip_address}:8888 (cloud hosted VPS)"
    fi

    echo -e "${BOLD}${HGREEN}INSTRUCTIONS:${NC}"
    echo -e "${HGREEN}Open your default device browser then copy this URL:${NC}"
    echo -e "${YELLOW}  $wallet_url ${NC}"
    echo ""
    echo -e "${HGREEN}After accessing the URL:${NC}"
    echo -e "${HGREEN}Click “Generate Wallet” on the page. Scroll up, copy everything & save in a secure place! - no keys no entry! 👍${NC}"
        echo ""
            read -n 1 -s -p "Press ENTER to ACTIVATE the wallet generator... (This will make it accessible) 👍"
    echo ""   
    echo -e "${HGREEN}Wallet generator is now active and accessible via $wallet_url ${NC}"
    echo ""
    echo -e "${HGREEN}TAKE NOTE: This process will be killed when you press the next Enter.${NC}"
    echo -e "${HGREEN}Make sure you've copied all necessary info from the wallet generator before proceeding!${NC}"
    read -n 1 -s -p "Press Enter to go back to Menu...."
    echo ""
    
    kill $PID 2>/dev/null # Attempt to stop the wallet generator
    cd .. # Go back to the main script directory
}

install_octra_cli() {
    clear
    echo -e "${HGREEN}--- Option 2: Installing OCTRA CLI ---${NC}"
    echo ""

    if ! check_internet_connection; then
        read -n 1 -s -p "Press any key to return to the main menu..."
        return
    fi

    echo -e "${HGREEN}Updating & installing Python tools...${NC}"
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y python3 python3-pip python3-venv python3-dev git curl

    echo -e "${HGREEN}Cloning or pulling latest Octra CLI image...${NC}"
    if [ -d "octra_pre_client" ]; then
        echo -e "${YELLOW}Octra client directory already exists. Pulling latest changes...${NC}"
        cd octra_pre_client
        git pull
    else
        echo -e "${HGREEN}Initiating octra client repo X${NC}"
        git clone https://github.com/octra-labs/octra_pre_client.git
        cd octra_pre_client
    fi

    echo -e "${HGREEN}Creating a virtual environment & activating...${NC}"
    if [ ! -d "venv" ]; then
        python3 -m venv venv
    fi
    source venv/bin/activate

    echo -e "${HGREEN}Installing requirements...${NC}"
    pip install --upgrade pip
    pip install -r requirements.txt

    echo -e "${HGREEN}Input your private key (Base64, no spaces):${NC}"
    read -r octa_privateX

    echo -e "${HGREEN}Input your Octra address (OCTxxxxx..):${NC}"
    read -r octa_addy

    cat <<EOF > wallet.json
{
  "priv": "$octa_privateX",
  "addr": "$octa_addy",
  "rpc": "https://octra.network"
}
EOF

    echo -e "${DEEP_GREEN}wallet.json created with your private key & address.${NC}"
    echo ""
    read -n 1 -s -p "Press Enter to go back to Menu..."
    cd .. # Go back to the main script directory
}

launch_cli() {
    clear
    echo -e "${HGREEN}--- Option 3: Launch CLI ---${NC}"
    echo ""

    type_text "Booting up your OCTA CLI in " 0.05
    for i in 3 2 1; do
        echo -e "${HGREEN}$i${NC}"
        sleep 1
    done

    echo -e "${HGREEN}Changing directory to octra_pre_client...${NC}"
    if [ -d "octra_pre_client" ]; then
        cd octra_pre_client
    else
        echo -e "${RED}Error: Octra CLI directory 'octra_pre_client' not found. Please install it first (Option 2).${NC}"
        read -n 1 -s -p "Press any key to return to the main menu..."
        return
    fi

    echo -e "${HGREEN}Activating virtual environment...${NC}"
    if [ -d "venv" ]; then
        source venv/bin/activate
    else
        echo -e "${RED}Error: Virtual environment not found. Please ensure Octra CLI is properly installed.${NC}"
        read -n 1 -s -p "Press any key to return to the main menu..."
        cd ..
        return
    fi

    echo -e "${HGREEN}Launching....${NC}"
    python3 cli.py

    echo ""
    read -n 1 -s -p "Press Enter to go back to Menu..."
    deactivate 2>/dev/null # Deactivate virtual environment
    cd .. # Go back to the main script directory
}

# update_all: Updates all installed components
update_all() {
    clear
    echo -e "${HGREEN}--- Option 4: Update All ---${NC}"
    echo ""

    if ! check_internet_connection; then
        read -n 1 -s -p "Press any key to return to the main menu..."
        return
    fi

    echo -e "${HGREEN}Checking for updates...${NC}"

    local update_available="false"

    if [ -d "wallet-gen" ]; then
        type_text "Checking for Wallet Generator updates..." 0.03
        (cd wallet-gen && git fetch) &>/dev/null
        if [ "$(cd wallet-gen && git rev-parse HEAD)" != "$(cd wallet-gen && git rev-parse @{u})" ]; then
            echo -e "${YELLOW}New updates available for Wallet Generator.${NC}"
            update_available="true"
        else
            echo -e "${DEEP_GREEN}Wallet Generator is up to date.${NC}"
        fi
    fi

    if [ -d "octra_pre_client" ]; then
        type_text "Checking for Octra CLI updates..." 0.03
        (cd octra_pre_client && git fetch) &>/dev/null
        if [ "$(cd octra_pre_client && git rev-parse HEAD)" != "$(cd octra_pre_client && git rev-parse @{u})" ]; then
            echo -e "${YELLOW}New updates available for Octra CLI.${NC}"
            update_available="true"
        else
            echo -e "${DEEP_GREEN}Octra CLI is up to date.${NC}"
        fi
    fi

    if [ "$update_available" = "true" ]; then
        echo ""
        echo -e "${YELLOW}New updates available. Do you want to update now? (y/n)${NC}"
        read -n 1 -r response
        echo ""
        if [[ "$response" =~ ^[Yy]$ ]]; then
            echo -e "${HGREEN}Updating...${NC}"
            if [ -d "wallet-gen" ]; then
                type_text "Updating Wallet Generator..." 0.03
                (cd wallet-gen && git merge)
                echo -e "${DEEP_GREEN}Wallet Generator updated.${NC}"
            fi
            if [ -d "octra_pre_client" ]; then
                type_text "Updating Octra CLI..." 0.03
                (cd octra_pre_client && git merge)
                (cd octra_pre_client && source venv/bin/activate && pip install -r requirements.txt && deactivate) 2>/dev/null
                echo -e "${DEEP_GREEN}Octra CLI updated.${NC}"
            fi
            echo -e "${DEEP_GREEN}All updates complete.${NC}"
        else
            echo -e "${YELLOW}Update skipped.${NC}"
        fi
    else
        echo -e "${DEEP_GREEN}No new updates available.${NC}"
    fi

    echo ""
    read -n 1 -s -p "Press Enter to go back to Menu..."
}

display_menu() {
    while true; do
        clear
        echo -e "${BOLD}${HGREEN}--- Octa Testnet Wallet Manager Menu ---${NC}"
        echo -e "${HGREEN}1. Wallet Generator Installer${NC}"
        echo -e "${HGREEN}2. Installing OCTRA CLI${NC}"
        echo -e "${HGREEN}3. Launch CLI${NC}"
        echo -e "${HGREEN}4. Update ALL${NC}"
        echo -e "${RED}5. Exit${NC}"
        echo ""
        echo -e "${HGREEN}Enter your choice:${NC}"
        read -r choice

        case "$choice" in
            1) install_wallet_generator ;;
            2) install_octra_cli ;;
            3) launch_cli ;;
            4) update_all ;;
            5)
                type_text "Exiting Octa Testnet Wallet Manager. Goodbye! 😌" 0.05
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Please choose a number between 1 and 5.${NC}"
                sleep 2
                ;;
        esac
    done
}

check_sudo_privileges
MrXintro
display_menu
