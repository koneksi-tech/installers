#!/bin/bash

set -e

echo "======================================"
echo "Koneksi Setup for Amazon Linux"
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
    
    # Amazon Linux uses linux-amd64 binaries
    ENGINE_BINARY_FILENAME="koneksi-engine-linux-amd64"
    CLI_BINARY_FILENAME="koneksi-cli-linux-amd64"
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
API_URL=https://uat.koneksi.co.kr        # URL of the gateway or central API the engine will communicate with
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
    echo "Select how to run the services:"
    echo "1) Run both in background (recommended for servers)"
    echo "2) Run in foreground with output"
    echo "3) Run in separate screen sessions (if screen is installed)"
    echo "4) Cancel"
    echo ""
    read -p "Enter your choice [1-4]: " RUN_MODE
    
    case $RUN_MODE in
        1)
            echo "Starting Koneksi Engine in background..."
            
            # Kill any existing processes first
            pkill -f "koneksi-engine/koneksi" 2>/dev/null || true
            pkill -f "koneksi-cli/koneksi" 2>/dev/null || true
            sleep 1
            
            cd koneksi-engine
            nohup ./koneksi > koneksi-engine.log 2>&1 &
            ENGINE_PID=$!
            echo "Engine started with PID: $ENGINE_PID"
            cd ..
            
            # Verify engine startup with health check
            echo "Verifying engine startup..."
            for i in {1..10}; do
                if curl -s http://localhost:3080/check-health > /dev/null 2>&1; then
                    echo "✓ Engine is running and responding to health checks"
                    break
                elif [ $i -eq 10 ]; then
                    echo "⚠ Warning: Engine may not have started properly"
                    echo "  Check logs: tail -f koneksi-engine/koneksi-engine.log"
                else
                    echo "  Waiting for engine to start... ($i/10)"
                    sleep 2
                fi
            done
            
            echo "Starting Koneksi CLI in background..."
            cd koneksi-cli
            nohup ./koneksi > koneksi-cli.log 2>&1 &
            CLI_PID=$!
            echo "CLI started with PID: $CLI_PID"
            cd ..
            
            echo ""
            echo "Both services are running in background."
            echo "Engine PID: $ENGINE_PID (log: koneksi-engine/koneksi-engine.log)"
            echo "CLI PID: $CLI_PID (log: koneksi-cli/koneksi-cli.log)"
            echo ""
            echo "To stop the services, run:"
            echo "  kill $ENGINE_PID $CLI_PID"
            ;;
            
        2)
            echo "Starting services in foreground..."
            echo "Press Ctrl+C to stop both services"
            echo ""
            
            # Function to handle cleanup
            cleanup() {
                echo ""
                echo "Stopping services..."
                kill $ENGINE_PID $CLI_PID 2>/dev/null
                wait $ENGINE_PID $CLI_PID 2>/dev/null
                echo "Services stopped."
                exit 0
            }
            
            # Set up trap for Ctrl+C
            trap cleanup SIGINT
            
            echo "Starting Koneksi Engine..."
            cd koneksi-engine && ./koneksi &
            ENGINE_PID=$!
            cd ..
            
            sleep 2
            
            echo "Starting Koneksi CLI..."
            cd koneksi-cli && ./koneksi &
            CLI_PID=$!
            cd ..
            
            echo ""
            echo "Services are running. Press Ctrl+C to stop."
            
            # Wait for processes
            wait $ENGINE_PID $CLI_PID
            ;;
            
        3)
            if ! command -v screen &> /dev/null; then
                echo "Screen is not installed. Installing screen..."
                if ! sudo yum install -y screen; then
                    echo "Failed to install screen. Please install it manually."
                    return 1
                fi
            fi
            
            # Kill any existing screen sessions
            screen -X -S koneksi-engine quit 2>/dev/null || true
            screen -X -S koneksi-cli quit 2>/dev/null || true
            sleep 1
            
            echo "Starting Koneksi Engine in screen session..."
            screen -dmS koneksi-engine bash -c "cd koneksi-engine && ./koneksi"
            
            # Verify engine startup with health check
            echo "Verifying engine startup..."
            for i in {1..10}; do
                if curl -s http://localhost:3080/check-health > /dev/null 2>&1; then
                    echo "✓ Engine is running and responding to health checks"
                    break
                elif [ $i -eq 10 ]; then
                    echo "⚠ Warning: Engine may not have started properly"
                    echo "  Check logs: screen -r koneksi-engine"
                else
                    echo "  Waiting for engine to start... ($i/10)"
                    sleep 2
                fi
            done
            
            echo "Starting Koneksi CLI in screen session..."
            screen -dmS koneksi-cli bash -c "cd koneksi-cli && ./koneksi"
            
            echo ""
            echo "Services are running in screen sessions."
            echo "To view Engine output: screen -r koneksi-engine"
            echo "To view CLI output: screen -r koneksi-cli"
            echo "To detach from screen: Ctrl+A, then D"
            echo "To list sessions: screen -ls"
            echo "To stop a service: screen -X -S [session-name] quit"
            ;;
            
        4)
            echo "Cancelled."
            return 0
            ;;
            
        *)
            echo "Invalid choice."
            return 1
            ;;
    esac
}

# Function to check system requirements
check_requirements() {
    echo "Checking system requirements..."
    
    # Check if running on Linux
    if [ "$(uname -s)" != "Linux" ]; then
        echo "Warning: This script is designed for Linux systems."
    fi
    
    # Check for curl (required for downloads and health checks)
    if ! command -v curl &> /dev/null; then
        echo "Error: curl is not installed. Installing..."
        if ! sudo yum install -y curl; then
            echo "Failed to install curl. Please install it manually."
            echo "curl is required for downloading binaries and verifying engine health."
            exit 1
        fi
        echo "curl installed successfully."
    fi
    
    # Check architecture
    ARCH=$(uname -m)
    if [ "$ARCH" != "x86_64" ]; then
        echo "Warning: This script is designed for x86_64 architecture. Your architecture: $ARCH"
        echo "The binaries may not work correctly."
        read -p "Do you want to continue anyway? (y/n): " CONTINUE
        if [ "$CONTINUE" != "y" ]; then
            exit 1
        fi
    fi
    
    echo "System requirements check completed."
}

# Main execution
main() {
    echo "Welcome to Koneksi Setup for Amazon Linux!"
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