#!/bin/bash

## AUTHOR => wathika-eng

command_exists() {
    command -v "$1" &> /dev/null
}

REQUIRED_SPACE_MB=250
AVAILABLE_SPACE_MB=$(df --output=avail -m . | tail -1 | tr -d ' ')

if [ "$AVAILABLE_SPACE_MB" -lt "$REQUIRED_SPACE_MB" ]; then
    echo "Warning: You must have over 250 MB of free space to proceed."
    read -p "Do you want to proceed? (yes/no): " user_choice
    if [ "$user_choice" != "yes" ]; then
        echo "Exiting script."
        exit 1
    fi
fi

echo "Folders will be downloaded in the current directory: $(pwd)"

read -p "Enter the MediaFire URL: " mediafire_url

install_rust() {
    if ! command_exists cargo; then
        echo "Rust is not installed. Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source $HOME/.cargo/env
    fi
}

install_mediafire_rs() {
    echo "Installing mediafire_rs..."
    cargo install mediafire_rs
}

install_rust & rust_pid=$!
install_mediafire_rs & mediafire_rs_pid=$!
wait $rust_pid
wait $mediafire_rs_pid

if ! command_exists cargo; then
    echo "Cargo installation failed. Please install Rust and Cargo manually."
    exit 1
fi

if ! command_exists mdrs; then
    echo "Installation of mediafire_rs failed."
    exit 1
fi

show_progress() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    local temp

    echo -n "Downloading: "
    while ps -p $pid &> /dev/null; do
        temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    echo " Done"
}

echo "Starting download from MediaFire folder..."
mdrs "$mediafire_url" &

show_progress $!

echo "Download completed!"
