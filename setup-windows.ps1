# Koneksi Setup Script for Windows
# Requires PowerShell 5.1 or later

param(
    [switch]$Silent,
    [switch]$SkipEngineInstall,
    [switch]$SkipCliInstall
)

$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Koneksi Setup for Windows" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Function to display menu
function Show-Menu {
    Write-Host ""
    Write-Host "Please select an option:" -ForegroundColor Yellow
    Write-Host "1) Install Koneksi Engine and CLI"
    Write-Host "2) Run Koneksi Engine and CLI"
    Write-Host "3) Install Both and Run"
    Write-Host "4) Exit"
    Write-Host ""
    $choice = Read-Host "Enter your choice [1-4]"
    return $choice
}

# Function to check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to install Koneksi
function Install-Koneksi {
    Write-Host ""
    Write-Host "Starting installation process..." -ForegroundColor Green
    Write-Host "======================================" -ForegroundColor Green
    
    # Define repository information
    $engineRepoOwner = "koneksi-tech"
    $engineRepoName = "koneksi-engine-updates"
    $cliRepoOwner = "koneksi-tech"
    $cliRepoName = "koneksi-cli-updates"
    
    try {
        # Get latest releases
        Write-Host "Fetching latest Engine release version..."
        $engineReleaseUrl = "https://api.github.com/repos/$engineRepoOwner/$engineRepoName/releases/latest"
        $engineRelease = Invoke-RestMethod -Uri $engineReleaseUrl -UseBasicParsing
        $engineLatestVersion = $engineRelease.tag_name
        Write-Host "Latest Engine version: $engineLatestVersion" -ForegroundColor Green
        
        Write-Host "Fetching latest CLI release version..."
        $cliReleaseUrl = "https://api.github.com/repos/$cliRepoOwner/$cliRepoName/releases/latest"
        $cliRelease = Invoke-RestMethod -Uri $cliReleaseUrl -UseBasicParsing
        $cliLatestVersion = $cliRelease.tag_name
        Write-Host "Latest CLI version: $cliLatestVersion" -ForegroundColor Green
    }
    catch {
        Write-Host "Error: Unable to fetch latest release versions" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        return $false
    }
    
    # Windows Server binaries
    $engineBinaryFilename = "koneksi-engine-windows-amd64.exe"
    $cliBinaryFilename = "koneksi-cli-windows-amd64.exe"
    $engineFinalName = "koneksi.exe"
    $cliFinalName = "koneksi.exe"
    
    # Create folder for Engine
    if (-not $SkipEngineInstall) {
        Write-Host ""
        Write-Host "Setting up Koneksi Engine..." -ForegroundColor Cyan
        Write-Host "======================================" -ForegroundColor Cyan
        
        if (-not (Test-Path "koneksi-engine")) {
            New-Item -ItemType Directory -Path "koneksi-engine" | Out-Null
        }
        
        Set-Location "koneksi-engine"
        
        # Check if Engine is already installed
        if (Test-Path $engineFinalName) {
            $update = Read-Host "Koneksi Engine binary already exists. Do you want to update it? (y/n)"
            if ($update -ne 'y') {
                Write-Host "Skipping Engine installation..."
                Set-Location ..
            }
            else {
                Write-Host "Updating Koneksi Engine..."
                Remove-Item $engineFinalName -Force
            }
        }
        
        if (-not (Test-Path $engineFinalName)) {
            # Create .env file
            Write-Host "Creating .env configuration file..."
            $envContent = @"
APP_KEY=pH0s9fH2ZecZlZcxnZK44wTVkiGPs5vN     # Secret key for internal authentication or encryption
MODE=release                                 # Use 'debug' to display verbose logs
API_URL=https://uat.koneksi.co.kr        # URL of the gateway or central API the engine will communicate with
RETRY_COUNT=5                                # Number of retry attempts for failed requests or operations
MAX_UPLOAD_FILE_SIZE=10                      # Unit of GB (ex. 1 = 1GB, 10 = 10GB) Default is 10GB
UPLOAD_CONCURRENCY=3                         # Number of concurrent uploads
UPLOAD_DELAY=500ms                           # Delay between uploads in milliseconds
TOKEN_CHECK_INTERVAL=60s                     # Interval for checking if a token is still valid
BACKUP_TASK_COOLDOWN=60s                     # Cooldown period between backup operations
QUEUE_CHECK_INTERVAL=2s                      # Interval for checking processing queues for new tasks
PAUSE_TIMEOUT=30s                            # Timeout duration for pause operations in the backup queue table
"@
            Set-Content -Path ".env" -Value $envContent
            
            # Download Engine binary
            Write-Host "Downloading Koneksi Engine binary..."
            $engineDownloadUrl = "https://github.com/$engineRepoOwner/$engineRepoName/releases/download/$engineLatestVersion/$engineBinaryFilename"
            
            try {
                # Enable TLS 1.2 for secure downloads
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                Invoke-WebRequest -Uri $engineDownloadUrl -OutFile $engineBinaryFilename -UseBasicParsing
                
                # Rename to final name
                Move-Item $engineBinaryFilename $engineFinalName -Force
                Write-Host "Koneksi Engine installed successfully!" -ForegroundColor Green
            }
            catch {
                Write-Host "Error: Failed to download Engine binary" -ForegroundColor Red
                Write-Host $_.Exception.Message -ForegroundColor Red
                Set-Location ..
                return $false
            }
        }
        
        Set-Location ..
    }
    
    # Create folder for CLI
    if (-not $SkipCliInstall) {
        Write-Host ""
        Write-Host "Setting up Koneksi CLI..." -ForegroundColor Cyan
        Write-Host "======================================" -ForegroundColor Cyan
        
        if (-not (Test-Path "koneksi-cli")) {
            New-Item -ItemType Directory -Path "koneksi-cli" | Out-Null
        }
        
        Set-Location "koneksi-cli"
        
        # Check if CLI is already installed
        if (Test-Path $cliFinalName) {
            $update = Read-Host "Koneksi CLI binary already exists. Do you want to update it? (y/n)"
            if ($update -ne 'y') {
                Write-Host "Skipping CLI installation..."
                Set-Location ..
            }
            else {
                Write-Host "Updating Koneksi CLI..."
                Remove-Item $cliFinalName -Force
            }
        }
        
        if (-not (Test-Path $cliFinalName)) {
            # Download CLI binary
            Write-Host "Downloading Koneksi CLI binary..."
            $cliDownloadUrl = "https://github.com/$cliRepoOwner/$cliRepoName/releases/download/$cliLatestVersion/$cliBinaryFilename"
            
            try {
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                Invoke-WebRequest -Uri $cliDownloadUrl -OutFile $cliBinaryFilename -UseBasicParsing
                
                # Rename to final name
                Move-Item $cliBinaryFilename $cliFinalName -Force
                Write-Host "Koneksi CLI installed successfully!" -ForegroundColor Green
            }
            catch {
                Write-Host "Error: Failed to download CLI binary" -ForegroundColor Red
                Write-Host $_.Exception.Message -ForegroundColor Red
                Set-Location ..
                return $false
            }
        }
        
        Set-Location ..
    }
    
    # Add to PATH (optional)
    $addToPath = Read-Host "Do you want to add Koneksi CLI to system PATH? (requires admin) (y/n)"
    if ($addToPath -eq 'y') {
        if (Test-Administrator) {
            $cliPath = Join-Path (Get-Location) "koneksi-cli"
            $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
            
            if ($currentPath -notlike "*$cliPath*") {
                [Environment]::SetEnvironmentVariable("Path", "$currentPath;$cliPath", "Machine")
                Write-Host "Koneksi CLI added to system PATH successfully!" -ForegroundColor Green
                Write-Host "Please restart your PowerShell session to use 'koneksi' command." -ForegroundColor Yellow
            }
            else {
                Write-Host "Koneksi CLI is already in system PATH." -ForegroundColor Yellow
            }
        }
        else {
            Write-Host "Administrator privileges required to modify system PATH." -ForegroundColor Red
            Write-Host "Please run this script as Administrator to add to PATH." -ForegroundColor Yellow
        }
    }
    
    Write-Host ""
    Write-Host "======================================" -ForegroundColor Green
    Write-Host "Installation completed successfully!" -ForegroundColor Green
    Write-Host "======================================" -ForegroundColor Green
    
    return $true
}

# Function to run Koneksi
function Start-Koneksi {
    param(
        [switch]$AutoRun
    )
    
    Write-Host ""
    Write-Host "Starting Koneksi services..." -ForegroundColor Green
    Write-Host "======================================" -ForegroundColor Green
    
    # Check if binaries exist
    if (-not (Test-Path "koneksi-engine\koneksi.exe")) {
        Write-Host "Error: Engine binary not found at koneksi-engine\koneksi.exe" -ForegroundColor Red
        Write-Host "Please run installation first (option 1)" -ForegroundColor Yellow
        return
    }
    
    if (-not (Test-Path "koneksi-cli\koneksi.exe")) {
        Write-Host "Error: CLI binary not found at koneksi-cli\koneksi.exe" -ForegroundColor Red
        Write-Host "Please run installation first (option 1)" -ForegroundColor Yellow
        return
    }
    
    # If AutoRun is specified, automatically choose option 2
    if ($AutoRun) {
        $runMode = "2"
    } else {
        Write-Host ""
        Write-Host "Select how to run the services:" -ForegroundColor Yellow
        Write-Host "1) Run both in separate console windows"
        Write-Host "2) Run both in background (hidden)"
        Write-Host "3) Run in Windows Terminal tabs (if installed)"
        Write-Host "4) Run as scheduled tasks"
        Write-Host "5) Cancel"
        Write-Host ""
        $runMode = Read-Host "Enter your choice [1-5]"
    }
    
    switch ($runMode) {
        "1" {
            Write-Host "Starting Koneksi Engine in new console window..."
            $enginePath = Join-Path (Get-Location) "koneksi-engine"
            Start-Process cmd -ArgumentList "/k", "cd /d `"$enginePath`" && echo Running Koneksi Engine... && koneksi.exe" -WindowStyle Normal
            
            Start-Sleep -Seconds 2
            
            Write-Host "Starting Koneksi CLI in new console window..."
            $cliPath = Join-Path (Get-Location) "koneksi-cli"
            Start-Process cmd -ArgumentList "/k", "cd /d `"$cliPath`" && echo Running Koneksi CLI... && koneksi.exe" -WindowStyle Normal
            
            Write-Host ""
            Write-Host "Both services are running in separate console windows." -ForegroundColor Green
        }
        
        "2" {
            Write-Host "Starting Koneksi Engine in background with logging..."
            
            $enginePath = Join-Path (Get-Location) "koneksi-engine\koneksi.exe"
            $engineWorkDir = Join-Path (Get-Location) "koneksi-engine"
            
            # Start engine with logging using cmd redirection
            $engineProcess = Start-Process cmd -ArgumentList "/c", "cd /d `"$engineWorkDir`" && koneksi.exe > koneksi-engine.log 2>&1" -WindowStyle Hidden -PassThru
            Write-Host "Engine started with PID: $($engineProcess.Id)" -ForegroundColor Green
            Write-Host "Engine logs: koneksi-engine\koneksi-engine.log" -ForegroundColor Yellow
            
            Start-Sleep -Seconds 2
            
            Write-Host "Starting Koneksi CLI in new terminal with health check..."
            $cliPath = Join-Path (Get-Location) "koneksi-cli"
            Start-Process cmd -ArgumentList "/k", "cd /d `"$cliPath`" && echo Running Koneksi CLI health check... && koneksi health" -WindowStyle Normal
            
            Write-Host ""
            Write-Host "Engine is running in background with logging." -ForegroundColor Green
            Write-Host "CLI terminal opened with health check command." -ForegroundColor Green
            Write-Host "To stop the engine, use Task Manager or run:" -ForegroundColor Yellow
            Write-Host "  Stop-Process -Id $($engineProcess.Id)" -ForegroundColor White
            Write-Host "To view engine logs:" -ForegroundColor Yellow
            Write-Host "  Get-Content .\koneksi-engine\koneksi-engine.log -Wait" -ForegroundColor White
        }
        
        "3" {
            # Check if Windows Terminal is installed
            $wtInstalled = Get-Command wt -ErrorAction SilentlyContinue
            
            if ($wtInstalled) {
                Write-Host "Starting services in Windows Terminal tabs..."
                
                $enginePath = Join-Path (Get-Location) "koneksi-engine"
                $cliPath = Join-Path (Get-Location) "koneksi-cli"
                
                # Start Windows Terminal with two tabs
                $wtCommand = "new-tab -d `"$enginePath`" cmd /k `"echo Running Koneksi Engine... && koneksi.exe`" ; new-tab -d `"$cliPath`" cmd /k `"echo Running Koneksi CLI... && koneksi.exe`""
                Start-Process wt -ArgumentList $wtCommand
                
                Write-Host "Services are running in Windows Terminal tabs." -ForegroundColor Green
            }
            else {
                Write-Host "Windows Terminal is not installed." -ForegroundColor Red
                Write-Host "Install it from Microsoft Store or use another option." -ForegroundColor Yellow
            }
        }
        
        "4" {
            if (-not (Test-Administrator)) {
                Write-Host "Administrator privileges required to create scheduled tasks." -ForegroundColor Red
                Write-Host "Please run this script as Administrator." -ForegroundColor Yellow
                return
            }
            
            Write-Host "Creating scheduled tasks..."
            
            $enginePath = Join-Path (Get-Location) "koneksi-engine\koneksi.exe"
            $engineWorkDir = Join-Path (Get-Location) "koneksi-engine"
            $cliPath = Join-Path (Get-Location) "koneksi-cli\koneksi.exe"
            $cliWorkDir = Join-Path (Get-Location) "koneksi-cli"
            
            # Create Engine task
            $engineAction = New-ScheduledTaskAction -Execute $enginePath -WorkingDirectory $engineWorkDir
            $engineTrigger = New-ScheduledTaskTrigger -AtStartup
            $engineSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
            
            Register-ScheduledTask -TaskName "KoneksiEngine" -Action $engineAction -Trigger $engineTrigger -Settings $engineSettings -Description "Koneksi Engine Service" -Force
            
            # Create CLI task
            $cliAction = New-ScheduledTaskAction -Execute $cliPath -WorkingDirectory $cliWorkDir
            $cliTrigger = New-ScheduledTaskTrigger -AtStartup
            $cliSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
            
            Register-ScheduledTask -TaskName "KoneksiCLI" -Action $cliAction -Trigger $cliTrigger -Settings $cliSettings -Description "Koneksi CLI Service" -Force
            
            Write-Host "Scheduled tasks created successfully!" -ForegroundColor Green
            
            $startNow = Read-Host "Do you want to start the tasks now? (y/n)"
            if ($startNow -eq 'y') {
                Start-ScheduledTask -TaskName "KoneksiEngine"
                Start-ScheduledTask -TaskName "KoneksiCLI"
                Write-Host "Tasks started successfully!" -ForegroundColor Green
            }
            
            Write-Host ""
            Write-Host "Task management commands:" -ForegroundColor Yellow
            Write-Host "  Start: Start-ScheduledTask -TaskName 'KoneksiEngine'" -ForegroundColor White
            Write-Host "  Stop:  Stop-ScheduledTask -TaskName 'KoneksiEngine'" -ForegroundColor White
            Write-Host "  Status: Get-ScheduledTask -TaskName 'Koneksi*'" -ForegroundColor White
        }
        
        "5" {
            Write-Host "Cancelled." -ForegroundColor Yellow
        }
        
        default {
            Write-Host "Invalid choice." -ForegroundColor Red
        }
    }
}

# Function to configure Windows Service
function Configure-WindowsService {
    if (-not (Test-Administrator)) {
        Write-Host "Administrator privileges required to configure Windows Services." -ForegroundColor Red
        Write-Host "Please run this script as Administrator." -ForegroundColor Yellow
        return
    }
    
    Write-Host ""
    Write-Host "Configuring Windows Services..." -ForegroundColor Green
    Write-Host "======================================" -ForegroundColor Green
    
    # Check if binaries exist
    if (-not (Test-Path "koneksi-engine\koneksi.exe")) {
        Write-Host "Error: Engine binary not found. Please install first." -ForegroundColor Red
        return
    }
    
    if (-not (Test-Path "koneksi-cli\koneksi.exe")) {
        Write-Host "Error: CLI binary not found. Please install first." -ForegroundColor Red
        return
    }
    
    Write-Host ""
    Write-Host "Select an option:" -ForegroundColor Yellow
    Write-Host "1) Install as Windows Services"
    Write-Host "2) Remove Windows Services"
    Write-Host "3) Start Services"
    Write-Host "4) Stop Services"
    Write-Host "5) Check Service Status"
    Write-Host "6) Cancel"
    Write-Host ""
    $serviceChoice = Read-Host "Enter your choice [1-6]"
    
    $enginePath = Join-Path (Get-Location) "koneksi-engine\koneksi.exe"
    $cliPath = Join-Path (Get-Location) "koneksi-cli\koneksi.exe"
    
    switch ($serviceChoice) {
        "1" {
            Write-Host "Installing Windows Services..."
            
            # Install Engine Service
            New-Service -Name "KoneksiEngine" `
                       -BinaryPathName $enginePath `
                       -DisplayName "Koneksi Engine Service" `
                       -Description "Koneksi Engine background service" `
                       -StartupType Automatic
            
            # Install CLI Service
            New-Service -Name "KoneksiCLI" `
                       -BinaryPathName $cliPath `
                       -DisplayName "Koneksi CLI Service" `
                       -Description "Koneksi CLI background service" `
                       -StartupType Automatic
            
            Write-Host "Services installed successfully!" -ForegroundColor Green
            
            $startNow = Read-Host "Do you want to start the services now? (y/n)"
            if ($startNow -eq 'y') {
                Start-Service -Name "KoneksiEngine"
                Start-Service -Name "KoneksiCLI"
                Write-Host "Services started successfully!" -ForegroundColor Green
            }
        }
        
        "2" {
            Write-Host "Removing Windows Services..."
            
            Stop-Service -Name "KoneksiEngine" -ErrorAction SilentlyContinue
            Stop-Service -Name "KoneksiCLI" -ErrorAction SilentlyContinue
            
            Remove-Service -Name "KoneksiEngine" -ErrorAction SilentlyContinue
            Remove-Service -Name "KoneksiCLI" -ErrorAction SilentlyContinue
            
            Write-Host "Services removed successfully!" -ForegroundColor Green
        }
        
        "3" {
            Write-Host "Starting services..."
            Start-Service -Name "KoneksiEngine"
            Start-Service -Name "KoneksiCLI"
            Write-Host "Services started successfully!" -ForegroundColor Green
        }
        
        "4" {
            Write-Host "Stopping services..."
            Stop-Service -Name "KoneksiEngine"
            Stop-Service -Name "KoneksiCLI"
            Write-Host "Services stopped successfully!" -ForegroundColor Green
        }
        
        "5" {
            Write-Host "Checking service status..."
            Get-Service -Name "Koneksi*" | Format-Table -AutoSize
        }
        
        "6" {
            Write-Host "Cancelled." -ForegroundColor Yellow
        }
        
        default {
            Write-Host "Invalid choice." -ForegroundColor Red
        }
    }
}

# Function to check system requirements
function Test-Requirements {
    Write-Host "Checking system requirements..." -ForegroundColor Cyan
    
    # Check Windows version
    $osVersion = [System.Environment]::OSVersion
    Write-Host "Operating System: $($osVersion.VersionString)"
    
    # Check if it's Windows Server
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    if ($os.Caption -like "*Server*") {
        Write-Host "Windows Server detected: $($os.Caption)" -ForegroundColor Green
    }
    else {
        Write-Host "Warning: This script is optimized for Windows Server but will work on: $($os.Caption)" -ForegroundColor Yellow
    }
    
    # Check PowerShell version
    $psVersion = $PSVersionTable.PSVersion
    Write-Host "PowerShell Version: $($psVersion.Major).$($psVersion.Minor)"
    
    if ($psVersion.Major -lt 5) {
        Write-Host "Error: PowerShell 5.1 or later is required." -ForegroundColor Red
        Write-Host "Please update PowerShell from: https://aka.ms/wmf5download" -ForegroundColor Yellow
        return $false
    }
    
    # Check architecture
    $arch = $env:PROCESSOR_ARCHITECTURE
    Write-Host "Architecture: $arch"
    
    if ($arch -ne "AMD64") {
        Write-Host "Warning: This script is designed for 64-bit systems." -ForegroundColor Yellow
    }
    
    # Check .NET Framework
    try {
        $dotNetVersion = Get-ItemProperty "HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\" -Name Release -ErrorAction Stop
        $release = $dotNetVersion.Release
        Write-Host ".NET Framework version: $release" -ForegroundColor Green
    }
    catch {
        Write-Host "Warning: Could not determine .NET Framework version" -ForegroundColor Yellow
    }
    
    # Check if running as Administrator
    if (Test-Administrator) {
        Write-Host "Running with Administrator privileges" -ForegroundColor Green
    }
    else {
        Write-Host "Note: Some features require Administrator privileges" -ForegroundColor Yellow
    }
    
    Write-Host "System requirements check completed." -ForegroundColor Green
    return $true
}

# Main execution
function Main {
    Write-Host "Welcome to Koneksi Setup for Windows Server!" -ForegroundColor Cyan
    Write-Host ""
    
    # Check requirements
    if (-not (Test-Requirements)) {
        Write-Host "System requirements not met. Exiting..." -ForegroundColor Red
        return
    }
    
    # Silent mode
    if ($Silent) {
        Write-Host "Running in silent mode..." -ForegroundColor Yellow
        $result = Install-Koneksi
        if ($result) {
            Start-Koneksi -AutoRun
        }
        return
    }
    
    # Interactive mode
    while ($true) {
        $choice = Show-Menu
        
        switch ($choice) {
            "1" {
                Install-Koneksi
            }
            
            "2" {
                Start-Koneksi
            }
            
            "3" {
                $result = Install-Koneksi
                if ($result) {
                    Write-Host ""
                    $runNow = Read-Host "Installation complete. Do you want to run the services now? (y/n)"
                    if ($runNow -eq 'y') {
                        Start-Koneksi -AutoRun
                    }
                }
            }
            
            "4" {
                Write-Host "Exiting..." -ForegroundColor Yellow
                exit 0
            }
            
            "5" {
                Configure-WindowsService
            }
            
            default {
                Write-Host "Invalid option. Please try again." -ForegroundColor Red
            }
        }
        
        Write-Host ""
        Write-Host "Press Enter to continue..." -ForegroundColor Gray
        Read-Host
    }
}

# Run main function
Main