#!/bin/bash

set -e

echo "======================================"
echo "Koneksi Setup for macOS"
echo "======================================"

# Function to display menu
show_menu() {
    echo ""
    echo "Please select an option:"
    echo "1) Install Koneksi Engine and CLI"
    echo "2) Run Koneksi Engine and CLI"
    echo "3) Install and Run"
    echo "4) Exit"
    echo ""
    read -p "Enter your choice [1-4]: " choice
}

# Function to install Koneksi
install_koneksi() {
    echo ""
    echo "Starting installation process..."
    echo "======================================"
    
    # GET ENGINE REPO INFO
    ENGINE_REPO_NAME="koneksi-engine-updates"
    ENGINE_REPO_OWNER="koneksi-tech"
    ENGINE_REPO_URL="https://github.com/$ENGINE_REPO_OWNER/$ENGINE_REPO_NAME/releases/download"
    
    # GET ENGINE LATEST RELEASE
    echo "Fetching latest Engine release version..."
    ENGINE_LATEST_RELEASE=$(curl -s https://api.github.com/repos/$ENGINE_REPO_OWNER/$ENGINE_REPO_NAME/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
    
    if [ -z "$ENGINE_LATEST_RELEASE" ]; then
        echo "Error: Unable to fetch latest Engine release version"
        exit 1
    fi
    echo "Latest Engine version: $ENGINE_LATEST_RELEASE"
    
    # GET CLI REPO INFO
    CLI_REPO_NAME="koneksi-cli-updates"
    CLI_REPO_OWNER="koneksi-tech"
    CLI_REPO_URL="https://github.com/$CLI_REPO_OWNER/$CLI_REPO_NAME/releases/download"
    
    # GET CLI LATEST RELEASE
    echo "Fetching latest CLI release version..."
    CLI_LATEST_RELEASE=$(curl -s https://api.github.com/repos/$CLI_REPO_OWNER/$CLI_REPO_NAME/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
    
    if [ -z "$CLI_LATEST_RELEASE" ]; then
        echo "Error: Unable to fetch latest CLI release version"
        exit 1
    fi
    echo "Latest CLI version: $CLI_LATEST_RELEASE"
    
    # Detect architecture for macOS
    ARCH=$(uname -m)
    if [ "$ARCH" == "arm64" ]; then
        ENGINE_BINARY_FILENAME="koneksi-engine-macos-arm64"
        CLI_BINARY_FILENAME="koneksi-cli-macos-arm64"
        echo "Detected Apple Silicon (ARM64) architecture"
    else
        ENGINE_BINARY_FILENAME="koneksi-engine-macos-amd64"
        CLI_BINARY_FILENAME="koneksi-cli-macos-amd64"
        echo "Detected Intel (x86_64) architecture"
    fi
    
    ENGINE_FINAL_NAME="koneksi"
    CLI_FINAL_NAME="koneksi"
    
    # Create folder for engine
    echo ""
    echo "Setting up Koneksi Engine..."
    echo "======================================"
    mkdir -p koneksi-engine
    cd koneksi-engine
    
    # Check if Engine is already installed
    if [ -f "$ENGINE_FINAL_NAME" ]; then
        echo "Koneksi Engine binary already exists."
        read -p "Do you want to update it? (y/n): " UPDATE_ENGINE
        if [ "$UPDATE_ENGINE" != "y" ]; then
            echo "Skipping Engine installation..."
            cd ..
        else
            echo "Updating Koneksi Engine..."
            rm -f "$ENGINE_FINAL_NAME"
        fi
    fi
    
    if [ ! -f "$ENGINE_FINAL_NAME" ]; then
        # Create the .env file for the Koneksi Engine binary
        echo "Creating .env configuration file..."
        cat > .env << EOF
APP_KEY=1oUPOOVVhRoN3SwIdMG4VP6iABNOTmQE     # Secret key for internal authentication or encryption
MODE=release                                 # Use 'debug' to display verbose logs
API_URL=https://uat.koneksi.co.kr            # URL of the gateway or central API the engine will communicate with
RETRY_COUNT=5                                # Number of retry attempts for failed requests or operations
UPLOAD_CONCURRENCY=1                         # Number of concurrent uploads
UPLOAD_DELAY=100ms                           # Delay between uploads in milliseconds
TOKEN_CHECK_INTERVAL=60s                     # Interval for checking if a token is still valid
BACKUP_TASK_COOLDOWN=60s                     # Cooldown period between backup operations
QUEUE_CHECK_INTERVAL=2s                      # Interval for checking processing queues for new tasks
PAUSE_TIMEOUT=30s                            # Timeout duration for pause operations in the backup queue table
EOF
        
        echo "Downloading Koneksi Engine binary..."
        if ! curl -LO "$ENGINE_REPO_URL/$ENGINE_LATEST_RELEASE/$ENGINE_BINARY_FILENAME"; then
            echo "Error: Failed to download Engine binary"
            exit 1
        fi
        
        # Rename and make executable
        mv "$ENGINE_BINARY_FILENAME" "$ENGINE_FINAL_NAME"
        chmod +x "$ENGINE_FINAL_NAME"
        
        # Remove quarantine attribute that macOS adds to downloaded files
        xattr -d com.apple.quarantine "$ENGINE_FINAL_NAME" 2>/dev/null || true
        
        echo "Koneksi Engine installed successfully!"
        cd ..
    fi
    
    # Create folder for CLI
    echo ""
    echo "Setting up Koneksi CLI..."
    echo "======================================"
    mkdir -p koneksi-cli
    cd koneksi-cli
    
    # Check if CLI is already installed
    if [ -f "$CLI_FINAL_NAME" ]; then
        echo "Koneksi CLI binary already exists."
        read -p "Do you want to update it? (y/n): " UPDATE_CLI
        if [ "$UPDATE_CLI" != "y" ]; then
            echo "Skipping CLI installation..."
            cd ..
        else
            echo "Updating Koneksi CLI..."
            rm -f "$CLI_FINAL_NAME"
        fi
    fi
    
    if [ ! -f "$CLI_FINAL_NAME" ]; then
        echo "Downloading Koneksi CLI binary..."
        if ! curl -LO "$CLI_REPO_URL/$CLI_LATEST_RELEASE/$CLI_BINARY_FILENAME"; then
            echo "Error: Failed to download CLI binary"
            exit 1
        fi
        
        # Rename and make executable
        mv "$CLI_BINARY_FILENAME" "$CLI_FINAL_NAME"
        chmod +x "$CLI_FINAL_NAME"
        
        # Remove quarantine attribute
        xattr -d com.apple.quarantine "$CLI_FINAL_NAME" 2>/dev/null || true
        
        echo "Koneksi CLI installed successfully!"
        cd ..
    fi
    
    # Register CLI to System (optional)
    echo ""
    read -p "Do you want to register Koneksi CLI to system PATH? (requires sudo) (y/n): " REGISTER_CLI
    if [ "$REGISTER_CLI" == "y" ]; then
        echo "Registering Koneksi CLI to system..."
        CLI_PATH=$(pwd)/koneksi-cli/$CLI_FINAL_NAME
        if sudo ln -sf "$CLI_PATH" /usr/local/bin/koneksi; then
            echo "Koneksi CLI registered successfully! You can now use 'koneksi' command from anywhere."
        else
            echo "Warning: Failed to register CLI to system PATH"
        fi
    fi
    
    echo ""
    echo "======================================"
    echo "Installation completed successfully!"
    echo "======================================"
}

# Function to run Koneksi
run_koneksi() {
    echo ""
    echo "Starting Koneksi services..."
    echo "======================================"
    
    # Check if binaries exist
    if [ ! -f "koneksi-engine/koneksi" ]; then
        echo "Error: Engine binary not found at koneksi-engine/koneksi"
        echo "Please run installation first (option 1)"
        return 1
    fi
    
    if [ ! -f "koneksi-cli/koneksi" ]; then
        echo "Error: CLI binary not found at koneksi-cli/koneksi"
        echo "Please run installation first (option 1)"
        return 1
    fi
    
    echo ""
    echo "About Koneksi Architecture:"
    echo "• Engine: Core background service that processes backup & recovery tasks"
    echo "• CLI: Command-line interface to control and communicate with the Engine"
    echo ""
    echo "The Engine runs continuously in the background, while you use the CLI"
    echo "to send commands and manage your backup operations."
    echo ""
    read -p "Start Koneksi Engine as background service with auto-startup? (y/n): " START_ENGINE
    
    if [ "$START_ENGINE" != "y" ]; then
        echo "Exiting..."
        return 0
    fi
    
    echo "Starting Koneksi Engine in background..."
    cd koneksi-engine
    
    # Create a launch agent plist for auto-start
    PLIST_PATH="$HOME/Library/LaunchAgents/com.koneksi.engine.plist"
    ENGINE_PATH="$(pwd)/koneksi"
    
    echo "Creating launch agent for auto-start..."
    cat > "$PLIST_PATH" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.koneksi.engine</string>
    <key>ProgramArguments</key>
    <array>
        <string>$ENGINE_PATH</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$(pwd)</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$(pwd)/koneksi-engine.log</string>
    <key>StandardErrorPath</key>
    <string>$(pwd)/koneksi-engine.log</string>
</dict>
</plist>
EOF
    
    # Load the launch agent
    launchctl load "$PLIST_PATH" 2>/dev/null || true
    launchctl start com.koneksi.engine 2>/dev/null || true
    
    cd ..
    
    echo ""
    echo "Koneksi Engine is now running as a background service."
    echo "It will automatically start when the machine boots up."
    echo ""
    echo "Log file: koneksi-engine/koneksi-engine.log"
    echo ""
    echo "To view logs:"
    echo "  tail -f koneksi-engine/koneksi-engine.log"
    echo ""
    echo "To stop the service:"
    echo "  launchctl stop com.koneksi.engine"
    echo ""
    echo "To disable auto-start:"
    echo "  launchctl unload ~/Library/LaunchAgents/com.koneksi.engine.plist"
}

# Function to check system requirements
check_requirements() {
    echo "Checking system requirements..."
    
    # Check if running on macOS
    if [ "$(uname -s)" != "Darwin" ]; then
        echo "Warning: This script is designed for macOS."
        read -p "Do you want to continue anyway? (y/n): " CONTINUE
        if [ "$CONTINUE" != "y" ]; then
            exit 1
        fi
    fi
    
    # Check for curl
    if ! command -v curl &> /dev/null; then
        echo "Error: curl is not installed."
        echo "curl should be pre-installed on macOS. Please check your system."
        exit 1
    fi
    
    # Check architecture
    ARCH=$(uname -m)
    echo "Detected architecture: $ARCH"
    
    # Check macOS version
    OS_VERSION=$(sw_vers -productVersion)
    echo "macOS version: $OS_VERSION"
    
    # Check if Homebrew is installed (optional, for tmux)
    if command -v brew &> /dev/null; then
        echo "Homebrew is installed (optional features available)"
    else
        echo "Note: Homebrew is not installed. Some optional features may not be available."
    fi
    
    echo "System requirements check completed."
}

# Main execution
main() {
    echo "Welcome to Koneksi Setup for macOS!"
    echo ""
    
    # Check requirements first
    check_requirements
    
    while true; do
        show_menu
        
        case $choice in
            1)
                install_koneksi
                ;;
            2)
                run_koneksi
                ;;
            3)
                install_koneksi
                if [ $? -eq 0 ]; then
                    echo ""
                    read -p "Installation complete. Do you want to run the services now? (y/n): " RUN_NOW
                    if [ "$RUN_NOW" == "y" ]; then
                        run_koneksi
                    fi
                fi
                ;;
            4)
                echo "Exiting..."
                exit 0
                ;;
            *)
                echo "Invalid option. Please try again."
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Run main function
main