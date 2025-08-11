@echo off
setlocal enabledelayedexpansion

echo ======================================
echo Koneksi Setup for Windows Server 2025
echo ======================================
echo.

:MAIN_MENU
echo.
echo Please select an option:
echo 1) Install Koneksi Engine and CLI
echo 2) Run Koneksi Engine and CLI
echo 3) Install and Run
echo 4) Exit
echo.
set /p choice="Enter your choice [1-4]: "

if "%choice%"=="1" goto INSTALL
if "%choice%"=="2" goto RUN
if "%choice%"=="3" goto INSTALL_AND_RUN
if "%choice%"=="4" goto EXIT
echo Invalid option. Please try again.
goto MAIN_MENU

:INSTALL
echo.
echo Starting installation process...
echo ======================================

:: Set repository information
set ENGINE_REPO_OWNER=koneksi-tech
set ENGINE_REPO_NAME=koneksi-engine-updates
set CLI_REPO_OWNER=koneksi-tech
set CLI_REPO_NAME=koneksi-cli-updates

:: Get latest release versions using curl
echo Fetching latest Engine release version...
for /f "tokens=2 delims=:" %%a in ('curl -s https://api.github.com/repos/%ENGINE_REPO_OWNER%/%ENGINE_REPO_NAME%/releases/latest ^| findstr "tag_name"') do (
    set ENGINE_VERSION_RAW=%%a
)
:: Remove quotes and spaces
set ENGINE_VERSION=!ENGINE_VERSION_RAW:"=!
set ENGINE_VERSION=!ENGINE_VERSION: =!
set ENGINE_VERSION=!ENGINE_VERSION:,=!

if "!ENGINE_VERSION!"=="" (
    echo Error: Unable to fetch latest Engine release version
    echo Please check your internet connection and try again.
    pause
    goto MAIN_MENU
)
echo Latest Engine version: !ENGINE_VERSION!

echo Fetching latest CLI release version...
for /f "tokens=2 delims=:" %%a in ('curl -s https://api.github.com/repos/%CLI_REPO_OWNER%/%CLI_REPO_NAME%/releases/latest ^| findstr "tag_name"') do (
    set CLI_VERSION_RAW=%%a
)
:: Remove quotes and spaces
set CLI_VERSION=!CLI_VERSION_RAW:"=!
set CLI_VERSION=!CLI_VERSION: =!
set CLI_VERSION=!CLI_VERSION:,=!

if "!CLI_VERSION!"=="" (
    echo Error: Unable to fetch latest CLI release version
    echo Please check your internet connection and try again.
    pause
    goto MAIN_MENU
)
echo Latest CLI version: !CLI_VERSION!

:: Windows binary names
set ENGINE_BINARY_FILENAME=koneksi-engine-windows-amd64.exe
set CLI_BINARY_FILENAME=koneksi-cli-windows-amd64.exe
set ENGINE_FINAL_NAME=koneksi.exe
set CLI_FINAL_NAME=koneksi.exe

:: Create folder for Engine
echo.
echo Setting up Koneksi Engine...
echo ======================================
if not exist "koneksi-engine" mkdir koneksi-engine
cd koneksi-engine

:: Check if Engine already exists
if exist "%ENGINE_FINAL_NAME%" (
    set /p UPDATE_ENGINE="Koneksi Engine binary already exists. Do you want to update it? (y/n): "
    if /i not "!UPDATE_ENGINE!"=="y" (
        echo Skipping Engine installation...
        cd ..
        goto INSTALL_CLI
    ) else (
        echo Updating Koneksi Engine...
        del /f "%ENGINE_FINAL_NAME%"
    )
)

:: Create .env file
echo Creating .env configuration file...
(
echo APP_KEY=1oUPOOVVhRoN3SwIdMG4VP6iABNOTmQE     # Secret key for internal authentication or encryption
echo MODE=release                                 # Use 'debug' to display verbose logs
echo API_URL=https://uat.koneksi.co.kr        # URL of the gateway or central API the engine will communicate with
echo RETRY_COUNT=5                                # Number of retry attempts for failed requests or operations
echo UPLOAD_CONCURRENCY=1                         # Number of concurrent uploads
echo UPLOAD_DELAY=100ms                           # Delay between uploads in milliseconds
echo TOKEN_CHECK_INTERVAL=60s                     # Interval for checking if a token is still valid
echo BACKUP_TASK_COOLDOWN=60s                     # Cooldown period between backup operations
echo QUEUE_CHECK_INTERVAL=2s                      # Interval for checking processing queues for new tasks
echo PAUSE_TIMEOUT=30s                            # Timeout duration for pause operations in the backup queue table
) > .env

:: Download Engine binary
echo Downloading Koneksi Engine binary...
curl -LO "https://github.com/%ENGINE_REPO_OWNER%/%ENGINE_REPO_NAME%/releases/download/!ENGINE_VERSION!/%ENGINE_BINARY_FILENAME%"

if not exist "%ENGINE_BINARY_FILENAME%" (
    echo Error: Failed to download Engine binary
    cd ..
    pause
    goto MAIN_MENU
)

:: Rename to final name
move /y "%ENGINE_BINARY_FILENAME%" "%ENGINE_FINAL_NAME%" >nul
echo Koneksi Engine installed successfully!
cd ..

:INSTALL_CLI
:: Create folder for CLI
echo.
echo Setting up Koneksi CLI...
echo ======================================
if not exist "koneksi-cli" mkdir koneksi-cli
cd koneksi-cli

:: Check if CLI already exists
if exist "%CLI_FINAL_NAME%" (
    set /p UPDATE_CLI="Koneksi CLI binary already exists. Do you want to update it? (y/n): "
    if /i not "!UPDATE_CLI!"=="y" (
        echo Skipping CLI installation...
        cd ..
        goto INSTALL_COMPLETE
    ) else (
        echo Updating Koneksi CLI...
        del /f "%CLI_FINAL_NAME%"
    )
)

:: Download CLI binary
echo Downloading Koneksi CLI binary...
curl -LO "https://github.com/%CLI_REPO_OWNER%/%CLI_REPO_NAME%/releases/download/!CLI_VERSION!/%CLI_BINARY_FILENAME%"

if not exist "%CLI_BINARY_FILENAME%" (
    echo Error: Failed to download CLI binary
    cd ..
    pause
    goto MAIN_MENU
)

:: Rename to final name
move /y "%CLI_BINARY_FILENAME%" "%CLI_FINAL_NAME%" >nul
echo Koneksi CLI installed successfully!
cd ..

:INSTALL_COMPLETE
echo.
echo ======================================
echo Installation completed successfully!
echo ======================================

:: Add to PATH (optional)
set /p ADD_PATH="Do you want to add Koneksi CLI to system PATH? (requires admin) (y/n): "
if /i "%ADD_PATH%"=="y" (
    echo.
    echo To add Koneksi CLI to PATH, run these commands as Administrator:
    echo   setx PATH "%%PATH%%;%CD%\koneksi-cli" /M
    echo.
    echo Or add this directory manually to your system PATH:
    echo   %CD%\koneksi-cli
    echo.
)

pause
goto MAIN_MENU

:RUN
echo.
echo Starting Koneksi services...
echo ======================================

:: Check if binaries exist
if not exist "koneksi-engine\koneksi.exe" (
    echo Error: Engine binary not found at koneksi-engine\koneksi.exe
    echo Please run installation first ^(option 1^)
    pause
    goto MAIN_MENU
)

if not exist "koneksi-cli\koneksi.exe" (
    echo Error: CLI binary not found at koneksi-cli\koneksi.exe
    echo Please run installation first ^(option 1^)
    pause
    goto MAIN_MENU
)

echo.
echo About Koneksi Architecture:
echo • Engine: Core background service that processes backup ^& recovery tasks
echo • CLI: Command-line interface to control and communicate with the Engine
echo.
echo The Engine runs continuously in the background, while you use the CLI
echo to send commands and manage your backup operations.
echo.
set /p START_ENGINE="Start Koneksi Engine as background service with auto-startup? (y/n): "

if /i not "%START_ENGINE%"=="y" (
    echo Exiting...
    pause
    goto MAIN_MENU
)

echo Starting Koneksi Engine in background...

:: Kill any existing processes first
taskkill /f /im koneksi.exe >nul 2>&1
timeout /t 1 /nobreak >nul

:: Create scheduled task for auto-startup
echo Creating scheduled task for auto-startup...
set ENGINE_PATH=%CD%\koneksi-engine\koneksi.exe
set ENGINE_WORKDIR=%CD%\koneksi-engine

:: Remove any existing task first
schtasks /delete /tn "KoneksiEngine" /f >nul 2>&1

:: Create new scheduled task
schtasks /create /tn "KoneksiEngine" /tr "\"%ENGINE_PATH%\"" /sc onstart /ru SYSTEM /rl highest /f >nul 2>&1
if !errorlevel!==0 (
    echo Scheduled task created successfully
) else (
    echo Warning: Failed to create scheduled task
)

:: Start the task now
schtasks /run /tn "KoneksiEngine" >nul 2>&1
if !errorlevel!==0 (
    echo Scheduled task started successfully
) else (
    echo Warning: Failed to start scheduled task
)

:: Give the service a moment to start
timeout /t 2 /nobreak >nul

:: Verify engine startup with health check
echo Verifying engine startup...
for /l %%i in (1,1,10) do (
    timeout /t 2 /nobreak >nul
    curl -s http://localhost:3080/check-health >nul 2>&1
    if !errorlevel!==0 (
        echo ✓ Engine is running and responding to health checks
        goto ENGINE_READY
    )
    echo   Waiting for engine to start... (%%i/10)
)
echo ⚠ Warning: Engine may not have started properly
echo   Check task status: schtasks /query /tn "KoneksiEngine"

:ENGINE_READY
echo.
echo Koneksi Engine is now running as a scheduled task.
echo It will automatically start when the machine boots up.
echo.
echo Log file: koneksi-engine\koneksi-engine.log ^(if available^)
echo.
echo To view task status:
echo   schtasks /query /tn "KoneksiEngine"
echo.
echo To stop the service:
echo   schtasks /end /tn "KoneksiEngine"
echo.
echo To disable auto-start:
echo   schtasks /delete /tn "KoneksiEngine"
pause
goto MAIN_MENU

:INSTALL_AND_RUN
call :INSTALL
echo.
set /p RUN_NOW="Installation complete. Do you want to run the services now? (y/n): "
if /i "%RUN_NOW%"=="y" goto RUN
goto MAIN_MENU

:EXIT
echo Exiting...
exit /b 0

:CHECK_REQUIREMENTS
echo Checking system requirements...

:: Check Windows version
ver | findstr /i "10.0" >nul
if %errorlevel%==0 (
    echo Windows 10/11/Server 2016+ detected
) else (
    echo Warning: This script is optimized for Windows 10/Server 2016 or later
)

:: Check if curl exists (required for downloads and health checks)
where curl >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: curl is not installed or not in PATH
    echo curl is required for downloading binaries and verifying engine health.
    echo Please install curl or use Windows 10/Server 2016 or later
    exit /b 1
)

:: Check architecture
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    echo Architecture: 64-bit ^(AMD64^)
) else (
    echo Warning: This script is designed for 64-bit systems
    echo Your architecture: %PROCESSOR_ARCHITECTURE%
)

echo System requirements check completed.
exit /b 0