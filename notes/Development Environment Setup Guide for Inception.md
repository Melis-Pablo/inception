## Overview
This guide documents the complete setup process for the Inception project development environment, using Ubuntu Server in UTM on Apple Silicon Mac, with a focus on local development and VM testing.

## Table of Contents
1. [Required Software](#required-software)
2. [VM Setup in UTM](#vm-setup-in-utm)
3. [Ubuntu Server Installation](#ubuntu-server-installation)
4. [SSH Configuration](#ssh-configuration)
5. [Development Environment Configuration](#development-environment-configuration)
6. [Project Structure Setup](#project-structure-setup)
7. [Git Configuration](#git-configuration)

## Required Software

### On Mac
- UTM (for VM management)
- Ubuntu Server ISO (download latest LTS version)
- Git
- Your preferred code editor

## VM Setup in UTM

1. Open UTM and click "Create New VM"
2. Select options:
   - Choose "Virtualize"
   - Select "Linux"
   - Ensure "Skip ISO boot" is unchecked
3. Configure hardware:
   - Select your Ubuntu Server ISO
   - Enable "Use Apple Virtualization"
   - CPU: 2-4 cores
   - Memory: 4GB (4096 MB)
   - Storage: 20-30GB

## Ubuntu Server Installation

### Initial Setup
1. Boot the VM
2. Language Selection:
   - Select English
   - Press Enter

3. Installer Update:
   - Select "Continue without updating"

4. Keyboard Configuration:
   - Select appropriate layout
   - Default US keyboard is fine for most users

5. Installation Type:
   - Select "Ubuntu Server"
   - NOT "Ubuntu Server minimized"

### Network and Storage
1. Network Configuration:
   - Accept default DHCP settings
   - Press Enter

2. Proxy Configuration:
   - Leave blank
   - Press Enter

3. Mirror Location:
   - Accept default mirror
   - Press Enter

4. Storage Configuration:
   - Select "Use an entire disk"
   - Do not select LVM or encryption
   - Confirm partitioning summary

### User Setup
1. Profile Setup:
    - Full name: {Your full name}
    - Server name: 'inception' (or preferred name)
    - Username: {Your username}
    - Password: {Strong password}

2. SSH Setup:
    - Select "Install OpenSSH server"
    - Do not import SSH identity

3. Skip "Popular snaps" selection
    - Tab to "Done"
    - Press Enter

4. Wait for installation to complete and reboot

## SSH Configuration

### In VM
1. Log in with your credentials
2. Check IP address:
   ```bash
   ip addr show
   ```
3. Verify SSH service:
   ```bash
   sudo systemctl status ssh
   ```
- Should show "active (running)" in green
   - If not running:
   ```bash
   sudo systemctl start ssh
   sudo systemctl enable ssh  # Makes it start on boot
   ```

### On Mac
1. Create SSH config:
   ```bash
   mkdir -p ~/.ssh
   nano ~/.ssh/config
   ```
2. Add configuration:
   ```
   Host inception
     HostName [VM_IP_ADDRESS]
     User [VM_USERNAME]
     Port 22
   ```
3. Setup SSH key:
   ```bash
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ssh-copy-id inception
   ```
4. Test connection:
   ```bash
   ssh inception
   ```

## Development Environment Configuration

### In VM
1. Update system:
   ```bash
   sudo apt update
   sudo apt upgrade
   ```

2. Install Docker:
   ```bash
   sudo apt install docker.io
   sudo usermod -aG docker $USER
   sudo apt install docker-compose
   ```

3. Install additional tools:
   ```bash
   sudo apt install make git curl
   ```

### Git Setup in VM
1. Generate SSH key for Git:
   ```bash
   ssh-keygen -t ed25519 -C "your@email.com"
   cat ~/.ssh/id_ed25519.pub
   ```
2. Add the key to your GitHub/GitLab account
3. Configure Git:
   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your@email.com"
   ```

## Project Structure Setup

### In VM
```bash
mkdir -p ~/inception/srcs
```
- If git repository already created
```bash
git clone git@github.com:{USERNAME}/inception.git
```
### On Mac
```bash
mkdir -p ~/Developer/inception
cd ~/Developer/inception
git init
```
- If git repository already created
```bash
mkdir -p ~/Developer
cd Developer
git clone git@github.com:{USERNAME}/inception.git
cd inception
```

Create `.gitignore`:
```bash
echo ".env" >> .gitignore
echo ".DS_Store" >> .gitignore
```

### Minimal Browser

To install
```
sudo apt install -y firefox xorg openbox
```

Then you can start Firefox with:
```
startx
```
### Directory Structure

```
   Local Mac:
   /Developer/inception/        # Your development directory
   ├── srcs/                  # Source files
   ├── Makefile              # Main Makefile
   └── .git/                 # Git repository

   VM:
   /home/your_login/inception/  # Mounted project directory
   └── data/                    # Docker volumes
```

## Development Workflow

1. Develop and edit code on Mac
2. Commit changes locally
3. In VM:
   ```bash
   cd inception
   git pull
   ```
4. Test changes in VM
5. If needed, make quick fixes in VM and commit directly

## Best Practices

1. Always pull latest changes before testing in VM
2. Keep VM updated regularly
3. Make frequent, atomic commits
4. Test Docker changes only in VM
5. Maintain separate Git credentials for Mac and VM for flexibility

## Troubleshooting

### Common Issues
1. SSH Connection Failed
   - Verify VM IP address
   - Check SSH service status in VM
   - Confirm SSH config on Mac

2. Git Authentication Issues
   - Verify SSH keys are properly added
   - Check Git configuration
   - Ensure proper repository permissions

3. Docker Permission Issues
   - Verify user is in docker group
   - Logout and login again after group changes
   ```bash
   su - $USER
   ```
