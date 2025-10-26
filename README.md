# Raspberry Pi 5 Automated Setup Script

A comprehensive automation script for setting up Raspberry Pi 5 devices with monitoring, security tools, and system configuration. Inspired by the Proxmox VE Helper Scripts style with beautiful colored output and emoji indicators.

## 🚀 Features

### **System Information Display**
- Complete hardware overview (model, revision, serial, temperature)
- Network details (IP, MAC address)
- System resources (memory, disk usage)
- OS and kernel information

### **Software Installation**
- **Monitoring Stack**: Grafana + InfluxDB with modern repository setup
- **Network Security Tools**: Kismet, Bettercap, Aircrack-ng, nmap, tcpdump, wireshark
- **Database**: PostgreSQL with contrib packages
- **GPS Tools**: GPSD with clients and tools
- **Essential Packages**: curl, wget, git, htop, nano, vim, tree, jq, dialog

### **System Configuration**
- Filesystem expansion
- WiFi region setting (AU)
- VNC server enablement
- SSH enablement
- GPU memory split configuration

### **Error Handling & Resilience**
- Continues on individual failures
- Network connectivity validation
- Package availability checks
- Service health verification
- Comprehensive logging
- Clear success/failure reporting

## 🎯 Quick Start

### **One-Line Installation**
```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/raspberry-pi-setup/main/raspberry-pi-setup.sh | bash
```

### **Manual Installation**
```bash
wget https://raw.githubusercontent.com/YOUR_USERNAME/raspberry-pi-setup/main/raspberry-pi-setup.sh
chmod +x raspberry-pi-setup.sh
./raspberry-pi-setup.sh
```

## 📋 Requirements

- **Hardware**: Raspberry Pi 5 (or compatible)
- **OS**: Raspberry Pi OS 64-bit (Trixie/Bookworm)
- **Network**: Internet connectivity
- **Privileges**: sudo access
- **Storage**: At least 2GB free space

## 🎛️ Installation Options

The script provides a flexible menu system:

1. **📦 Install All** (Recommended) - Complete setup
2. **⚙️ System Configuration Only** - raspi-config settings
3. **📊 Monitoring Stack** - Grafana + InfluxDB
4. **🔒 Network Security Tools** - Security utilities
5. **🗄️ Database** - PostgreSQL
6. **🌐 GPS Tools** - GPSD setup
7. **🛠️ Essential Packages Only** - Basic tools
8. **Custom Selection** - Multi-select dialog
9. **Exit**

## 🛡️ Security Features

- **No UFW required** for home/private networks
- **Services bind to localhost** by default
- **Router NAT protection** recommended
- **SSH key authentication** supported
- **Minimal attack surface**

## 📊 Example Output

```
🚀 System Information
┌─ System Overview ─────────────────────────────────────────┐
│ Hostname: raspberrypi
│ OS: Raspberry Pi OS GNU/Linux 12 (bookworm)
│ Kernel: 6.1.0-rpi7-rpi-v8
│ Architecture: aarch64
│ Uptime: 2 hours, 15 minutes
└────────────────────────────────────────────────────────────┘

┌─ Raspberry Pi Hardware ───────────────────────────────────┐
│ Model: Raspberry Pi 5 Model B Rev 1.0
│ Revision: d04170
│ Serial: 10000000a1b2c3d4
│ CPU: ARM Processor (4 cores)
│ Temperature: 45.2'C
└────────────────────────────────────────────────────────────┘
```

## 🔧 Customization

The script is designed for easy modification:

### **Adding New Software Categories**
```bash
# Add new function
install_development_tools() {
    local packages=(
        "python3-pip"
        "nodejs"
        "docker.io"
    )
    # ... installation logic
}
```

### **Adding raspi-config Options**
```bash
# Add to configure_system() function
if run_command "sudo raspi-config nonint do_camera 0" "Enabling camera" "configure_system"; then
    ((success_count++))
fi
```

### **Modifying Package Lists**
```bash
# Edit the packages array in any install function
local packages=(
    "curl"
    "wget"
    # "git"        # Comment out to remove
    "nano"
)
```

## 📝 Logging

All operations are logged to `/tmp/raspberry-pi-setup.log` with timestamps and detailed error information.

## 🚨 Troubleshooting

### **Network Connectivity Issues**
- Script tests multiple endpoints (8.8.8.8, 1.1.1.1, google.com)
- Continues with warnings if network is unavailable
- User can choose to proceed without internet

### **Package Installation Failures**
- Checks package availability before installation
- Continues with other packages if one fails
- Provides clear feedback on what succeeded/failed

### **Service Startup Issues**
- Validates services are actually running
- Waits up to 10 seconds for service startup
- Reports service health status

## 📋 Service Access Information

After installation, services are available at:

- **Grafana**: http://localhost:3000 (admin/admin)
- **InfluxDB**: http://localhost:8086
- **PostgreSQL**: localhost:5432
- **VNC**: Port 5900 (if enabled)

## 🤝 Contributing

This script is designed to be easily customizable and extensible. Feel free to:

- Add new software categories
- Modify existing configurations
- Improve error handling
- Add new raspi-config options

## 📄 License

MIT License - Feel free to use, modify, and distribute.

## 🙏 Acknowledgments


---

**Note**: This script is designed for home/private network use. For internet-exposed Pi devices, consider additional security measures like UFW firewall configuration.
