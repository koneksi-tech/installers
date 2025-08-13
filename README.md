# Koneksi CLI Installation & Usage Guide

## Table of Contents

- [System Requirements](#system-requirements)
- [Installation Methods](#installation-methods)
  - [Linux](#linux)
  - [macOS](#macos)
  - [Windows](#windows)
- [Developer Guide](#developer-guide)
- [Troubleshooting](#troubleshooting)

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

### Linux

1. **Download the setup script:**

   ```bash
   wget https://raw.githubusercontent.com/koneksi-tech/koneksi-cli-setup/main/setup-linux.sh
   chmod +x setup-linux.sh
   ```
   or get directly from https://github.com/koneksi-tech/koneksi-cli-setup

2. **Run the installer:**

   ```bash
   ./setup-linux.sh
   ```

3. **Select from menu:**
   - Option 1: Install Koneksi Engine & CLI
   - Option 2: Run existing installation
   - Option 3: Install both and run (Recommended for initial installation)

### macOS

1. **Download the setup script:**

   ```bash
   curl -O https://raw.githubusercontent.com/koneksi-tech/koneksi-cli-setup/main/setup-macos.sh
   chmod +x setup-macos.sh
   ```
   or get directly from https://github.com/koneksi-tech/koneksi-cli-setup

2. **Run the installer:**

   ```bash
   ./setup-macos.sh
   ```

3. **Select from menu:**
   - Option 1: Install Koneksi Engine & CLI
   - Option 2: Run existing installation
   - Option 3: Install both and run (Recommended for initial installation)

### Windows

1. **Download the setup script:**

   ```cmd
   // curl
   curl -O https://raw.githubusercontent.com/koneksi-tech/koneksi-cli-setup/main/setup-windows.ps1

   // powershell
   Invoke-WebRequest -Uri https://raw.githubusercontent.com/koneksi-tech/koneksi-cli-setup/main/setup-windows.ps1 -OutFile setup-windows.ps1
   ```
   or get directly from https://github.com/koneksi-tech/koneksi-cli-setup

2. **Run as Administrator (recommended):**

   ```cmd
   ./setup-windows.ps1
   ```

3. **Installation options:**
   - Option 1: Install Koneksi Engine & CLI
   - Option 2: Run existing installation
   - Option 3: Install both and run (Recommended for initial installation)

---

## Developer Guide

The Koneksi CLI provides various commands for interacting with the engine and managing operations. You can find all CLI commands here: [Koneksi CLI Guide](https://koneksi-1.gitbook.io/docs/command-line-tools/unified-cli/command-guides)

#### Basic Commands

```bash
# Check version
koneksi version

# Health check
koneksi health
```

#### Authentication

```bash
# Login with credentials
koneksi auth login --email user@example.com --password yourpassword 

# Logout
koneksi auth revoke-token --token access_token --email user@example.com
```

### Backup & Recovery Scenario

#### Backup Operations
1. File Upload
```bash
# Upload file
koneksi file upload --file-path /path/to/file.txt --email user@example.com
```
2. Folder Upload
```bash
# Upload directory
koneksi directory upload --path /path/to/directory --email user@example.com
```
3. Real-time backups
```bash
# Add realtime backup location
koneksi realtime-backup path add --path /path/to/directory --email user@example.com

# Verify current backup location
koneksi realtime-backup path read --email user@example.com

# Start initial backup
koneksi realtime-backup realtime start --email user@example.com

# Start watcher to detect backup location changes
koneksi realtime-backup watcher start --email user@example.com

# List realtime backup queue to check in-progress / pending uploads
koneksi realtime-backup queues read --email user@example.com

# Stop watcher to disable backup location changes detection
koneksi realtime-backup watcher stop --email user@example.com

# Remove realtime backup location
koneksi realtime-backup path remove --email user@example.com
```

#### Verify Backups

```bash
# List root directory content
koneksi directory read --email user@example.com

# List specific directory content
koneksi directory read --directory-id 6899f1bbdafb251035d62d67 --email user@example.com
```

#### Recovery Operations

```bash
# Create recovery request (it will start the initial recovery process)
koneksi recovery request --path /path/to/recovery-path --scope full --email user@example.com

# List recovery requests (view recovery requests history)
koneksi recovery list --email user@example.com

# List recovery request queue items (view all pending files to recover)
koneksi recovery list-queue --recovery-id 6899e7cedafb251035d62d66 --email user@example.com

# Process recovery queue (if recovery fails, we can use this to retry)
koneksi recovery process-queue --recovery-id 6899e7cedafb251035d62d66 --email user@example.com

# Delete recovery request (force stop ongoing recovery or remove recovery request from history)
koneksi recovery delete --recovery-id 6899e7cedafb251035d62d66 --email user@example.com

```

### Engine Service Monitoring

**Monitor logs:**

```bash
# Linux/macOS
tail -f koneksi-engine/koneksi-engine.log

# Windows
//cmd
type koneksi-engine\koneksi-engine.log

// powershell
Get-Content .\koneksi-engine\koneksi-engine.log -Wait
```

**Check process status:**

```bash
# Linux/macOS
ps aux | grep koneksi

# Windows
// cmd
tasklist | findstr /i koneksi

// powershell
Get-Process | Where-Object { $_.Name -like "*koneksi*" } | Select-Object Name, Id, CPU, WorkingSet
```

---

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
lsof -i :3080  # Linux/macOS
netstat -ano | findstr :3080  # Windows

# Kill process
kill -9 <PID>  # Linux/macOS
taskkill /PID <PID> /F  # Windows
```

**3. Connection Refused**

- Check firewall settings
- Verify API_URL in .env file
- Ensure network connectivity

**4. Engine connection failed**
```
request failed: Get "http://localhost:3080/check-health": dial tcp [::1]:3080: connectex: No connection could be made because the target machine actively refused it..
Please ensure the engine service is running and accessible.
```

- Make sure Engine service is running by checking:
```
lsof -i :3080  # Linux/macOS
netstat -ano | findstr :3080  # Windows
```
- If there's no task/service running, we need to run it using Option 2 in [Installation Methods](#installation-methods)

---

## Support & Resources

**GitHub Issues**:
  - Engine: [github.com/koneksi-tech/koneksi-engine-updates/issues](https://github.com/koneksi-tech/koneksi-engine-updates/issues)
  - CLI: [github.com/koneksi-tech/koneksi-cli-updates/issues](https://github.com/koneksi-tech/koneksi-cli-updates/issues)
---

## License

Copyright © 2025 Koneksi Tech. All rights reserved.
