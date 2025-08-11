# Koneksi CLI Installation & Usage Guide

## Table of Contents

- [System Requirements](#system-requirements)
- [Installation Methods](#installation-methods)
  - [Amazon Linux](#amazon-linux)
  - [macOS](#macos)
  - [Windows Server 2025](#windows-server-2025)
- [Running Koneksi](#running-koneksi)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Developer Guide](#developer-guide)
  - [CLI Command Examples](#cli-command-examples)

---

## System Requirements

### Minimum Requirements

- **OS**: Linux (Amazon Linux, Ubuntu, RHEL), macOS 10.15+, Windows Server 2016+, Ubuntu 22.04+
- **Architecture**: x86_64/AMD64 (ARM64 for macOS M1/M2)
- **RAM**: 512MB minimum, 1GB recommended
- **Disk Space**: 100MB for binaries and logs
- **Network**: Internet connection for initial download

### Prerequisites

- **Linux/macOS**: `curl` command-line tool
- **Windows**: `curl` (included in Windows 10/Server 2016+)
- **Optional**: `tmux` or `screen` for Linux/macOS session management

---

## Installation Methods

### Amazon Linux

1. **Download the setup script:**

   ```bash
   wget https://raw.githubusercontent.com/koneksi-tech/koneksi-cli-setup/main/setup-amazon-linux.sh
   chmod +x setup-amazon-linux.sh
   ```

2. **Run the installer:**

   ```bash
   ./setup-amazon-linux.sh
   ```

3. **Select from menu:**
   - Option 1: Install only
   - Option 2: Run existing installation
   - Option 3: Install and run

### macOS

1. **Download the setup script:**

   ```bash
   curl -O https://raw.githubusercontent.com/koneksi-tech/koneksi-cli-setup/main/setup-macos.sh
   chmod +x setup-macos.sh
   ```

2. **Run the installer:**

   ```bash
   ./setup-macos.sh
   ```

3. **Select from menu:**
   - Option 1: Install only
   - Option 2: Run existing installation
   - Option 3: Install and run

### Windows Server 2025

1. **Download the setup script:**

   ```cmd
   curl -O https://raw.githubusercontent.com/koneksi-tech/koneksi-cli-setup/main/setup-windows-server.bat
   ```

2. **Run as Administrator (recommended):**

   ```cmd
   setup-windows-server.bat
   ```

3. **Installation options:**
   - Standard installation
   - Windows Service configuration (requires admin)
   - Scheduled task setup

---

## Running Koneksi

### Basic Commands

**Manual Start both services:**

```bash
# Linux/macOS
cd koneksi-engine && ./koneksi &
cd ../koneksi-cli && ./koneksi &

# Windows
cd koneksi-engine && start koneksi.exe
cd ..\koneksi-cli && start koneksi.exe
```

### Production Deployment

**Linux/macOS with systemd:**

```bash
# Create service file
sudo nano /etc/systemd/system/koneksi-engine.service

# Add content:
[Unit]
Description=Koneksi Engine Service
After=network.target

[Service]
Type=simple
User=koneksi
WorkingDirectory=/opt/koneksi/koneksi-engine
ExecStart=/opt/koneksi/koneksi-engine/koneksi
Restart=always

[Install]
WantedBy=multi-user.target

# Enable and start
sudo systemctl enable koneksi-engine
sudo systemctl start koneksi-engine
```

**Windows Service:**

```cmd
# Run as Administrator
sc create KoneksiEngine binPath= "C:\koneksi\koneksi-engine\koneksi.exe" start= auto
sc start KoneksiEngine
```

### Monitoring

**View logs:**

```bash
# Linux/macOS
tail -f koneksi-engine/koneksi-engine.log
tail -f koneksi-cli/koneksi-cli.log

# Windows
type koneksi-engine\koneksi-engine.log
```

**Check process status:**

```bash
# Linux/macOS
ps aux | grep koneksi

# Windows
tasklist | findstr koneksi
```

---

## Configuration

### Environment Variables (.env)

Located in `koneksi-engine/.env`:

```env
# Core Settings
APP_KEY=1oUPOOVVhRoN3SwIdMG4VP6iABNOTmQE     # Authentication key
MODE=release                                 # release or debug
API_URL=https://uat.koneksi.co.kr            # API endpoint

# Performance Tuning
RETRY_COUNT=5                                # Request retry attempts
UPLOAD_CONCURRENCY=1                         # Parallel uploads
UPLOAD_DELAY=100ms                           # Delay between uploads

# Intervals
TOKEN_CHECK_INTERVAL=60s                     # Token validation frequency
BACKUP_TASK_COOLDOWN=60s                     # Backup operation cooldown
QUEUE_CHECK_INTERVAL=2s                      # Queue polling interval
PAUSE_TIMEOUT=30s                            # Pause operation timeout
```

## Troubleshooting

### Common Issues

**1. Permission Denied (Linux/macOS)**

```bash
chmod +x koneksi-engine/koneksi
chmod +x koneksi-cli/koneksi
```

**2. Port Already in Use**

```bash
# Find process using port
lsof -i :8080  # Linux/macOS
netstat -ano | findstr :8080  # Windows

# Kill process
kill -9 <PID>  # Linux/macOS
taskkill /PID <PID> /F  # Windows
```

**3. Connection Refused**

- Check firewall settings
- Verify API_URL in .env file
- Ensure network connectivity

**4. Service Won't Start (Windows)**

```cmd
# Check Windows Event Log
eventvwr.msc

# Run in console mode for debugging
koneksi-engine\koneksi.exe
```

---

## Developer Guide

### CLI Command Examples

The Koneksi CLI provides various commands for interacting with the engine and managing operations.

#### Basic Commands

```bash
# Check version
koneksi --version

# Display help
koneksi --help

# Health check
koneksi health
```

#### Authentication

```bash
# Login with credentials
koneksi auth login --password yourpassword --email user@example.com

# Logout
koneksi auth revoke-token --token access_token --email user@example.com
```

#### Backup Operations

```bash
# Upload file
koneksi file upload --file-path /path/to/file.txt --email user@example.com

# Upload directory
koneksi directory upload --path /path/to/directory --email user@example.com
```

#### Real-time Backup Operations

```bash
# Add realtime backup location
koneksi realtime-backup path add --path /path/to/directory --email user@example.com

# Verify current backup location
koneksi realtime-backup path read --email user@example.com

# Start initial backup
koneksi realtime-backup realtime start --email user@example.com

# Start watcher to detect backup location changes
koneksi realtime-backup watcher start --email user@example.com

# List realtime backup queue
koneksi realtime-backup queues read --email user@example.com

# Stop watcher to disable backup location changes detection
koneksi realtime-backup watcher stop --email user@example.com

# Remove realtime backup location
koneksi realtime-backup path remove --email user@example.com
```

#### Recovery Operations

```bash
# Create recovery request (will start the initial recovery queue process)
koneksi recovery request --path /path/to/recovery-path --scope full --email user@example.com

# List recovery requests
koneksi recovery list --email user@example.com

# List recovery request queue items
koneksi recovery list-queue --recovery-id 6899e7cedafb251035d62d66 --email user@example.com

# Process recovery queue (for retry)
koneksi recovery process-queue --recovery-id 6899e7cedafb251035d62d66 --email user@example.com

# Delete recovery request (including the recovery queue items)
koneksi recovery delete --recovery-id 6899e7cedafb251035d62d66 --email user@example.com

```

---

## Support & Resources

**GitHub Issues**:
  - Engine: [github.com/koneksi-tech/koneksi-engine-updates/issues](https://github.com/koneksi-tech/koneksi-engine-updates/issues)
  - CLI: [github.com/koneksi-tech/koneksi-cli-updates/issues](https://github.com/koneksi-tech/koneksi-cli-updates/issues)
---

## License

Copyright © 2025 Koneksi Tech. All rights reserved.
