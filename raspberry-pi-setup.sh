#!/bin/bash

# Raspberry Pi 5 Automated Setup Script
# Version: 1.0.2

# Removed set -e to allow script to continue on individual failures

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Emoji characters
CHECK="✅"
CROSS="❌"
WARNING="⚠️"
INFO="ℹ️"
ROCKET="🚀"
GEAR="⚙️"
PACKAGE="📦"
NETWORK="🌐"
SECURITY="🔒"
DATABASE="🗄️"
MONITOR="📊"
TOOLS="🛠️"

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/tmp/raspberry-pi-setup.log"

# Function to print colored output
print_status() {
    local color=$1
    local emoji=$2
    local message=$3
    echo -e "${color}${emoji} ${message}${NC}"
}

print_success() {
    print_status "$GREEN" "$CHECK" "$1"
}

print_error() {
    print_status "$RED" "$CROSS" "$1"
}

print_warning() {
    print_status "$YELLOW" "$WARNING" "$1"
}

print_info() {
    print_status "$BLUE" "$INFO" "$1"
}

print_header() {
    echo -e "${PURPLE}${ROCKET} $1${NC}"
}

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to handle errors gracefully
handle_error() {
    local function_name=$1
    local error_message=$2
    print_error "Failed in $function_name: $error_message"
    log_message "ERROR in $function_name: $error_message"
    return 1
}

# Function to run command with error handling
run_command() {
    local command=$1
    local description=$2
    local function_name=$3
    
    print_info "$description..."
    if eval "$command" 2>>"$LOG_FILE"; then
        print_success "$description completed"
        log_message "SUCCESS: $description"
        return 0
    else
        handle_error "$function_name" "Failed to execute: $command"
        return 1
    fi
}

# Function to check if package exists
check_package_exists() {
    local package=$1
    if apt-cache search "^$package$" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to install package with error handling
install_package() {
    local package=$1
    local function_name=$2
    
    # Check if package exists first
    if ! check_package_exists "$package"; then
        print_warning "Package $package not found in repositories"
        return 1
    fi
    
    if run_command "sudo apt install -y $package" "Installing $package" "$function_name"; then
        return 0
    else
        print_warning "Failed to install $package, continuing with other packages..."
        return 1
    fi
}

# Function to validate service is running
validate_service() {
    local service_name=$1
    local max_attempts=5
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if systemctl is-active --quiet "$service_name"; then
            print_success "$service_name is running"
            return 0
        else
            print_info "Waiting for $service_name to start... (attempt $attempt/$max_attempts)"
            sleep 2
            ((attempt++))
        fi
    done
    
    print_warning "$service_name failed to start after $max_attempts attempts"
    return 1
}

# Function to display system information
display_system_info() {
    print_header "System Information"
    log_message "Displaying system information"
    
    # Get basic system info with error handling
    local hostname=$(hostname 2>/dev/null || echo "Unknown")
    local os_version=$(lsb_release -d 2>/dev/null | cut -f2 || echo "Unknown")
    local kernel=$(uname -r 2>/dev/null || echo "Unknown")
    local arch=$(uname -m 2>/dev/null || echo "Unknown")
    local uptime=$(uptime -p 2>/dev/null || uptime | awk '{print $3,$4}' | sed 's/,//' 2>/dev/null || echo "Unknown")
    
    # Get Raspberry Pi specific info with error handling
    local pi_model=$(cat /proc/device-tree/model 2>/dev/null | tr -d '\0' || echo "Unknown")
    local pi_revision=$(cat /proc/cpuinfo 2>/dev/null | grep "Revision" | awk '{print $3}' | head -1 || echo "Unknown")
    local pi_serial=$(cat /proc/cpuinfo 2>/dev/null | grep "Serial" | awk '{print $3}' | head -1 || echo "Unknown")
    
    # Get network information with error handling
    local primary_ip=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}' | head -1 || echo "Not connected")
    local primary_mac=$(ip link show 2>/dev/null | grep -A1 "state UP" | grep -o "..:..:..:..:..:.." | head -1 || echo "Unknown")
    
    # Get memory and storage info with error handling
    local total_mem=$(free -h 2>/dev/null | grep "Mem:" | awk '{print $2}' || echo "Unknown")
    local available_mem=$(free -h 2>/dev/null | grep "Mem:" | awk '{print $7}' || echo "Unknown")
    local disk_usage=$(df -h / 2>/dev/null | awk 'NR==2 {print $3 "/" $2 " (" $5 " used)"}' || echo "Unknown")
    
    # Get CPU info with error handling
    local cpu_info=$(cat /proc/cpuinfo 2>/dev/null | grep "model name" | head -1 | cut -d: -f2 | xargs || echo "ARM Processor")
    local cpu_cores=$(nproc 2>/dev/null || echo "Unknown")
    
    # Get temperature (if available)
    local temp=$(vcgencmd measure_temp 2>/dev/null | cut -d= -f2 || echo "N/A")
    
    echo -e "${CYAN}┌─ System Overview ─────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}Hostname:${NC} $hostname"
    echo -e "${CYAN}│${NC} ${WHITE}OS:${NC} $os_version"
    echo -e "${CYAN}│${NC} ${WHITE}Kernel:${NC} $kernel"
    echo -e "${CYAN}│${NC} ${WHITE}Architecture:${NC} $arch"
    echo -e "${CYAN}│${NC} ${WHITE}Uptime:${NC} $uptime"
    echo -e "${CYAN}└────────────────────────────────────────────────────────────┘${NC}"
    
    echo -e "${CYAN}┌─ Raspberry Pi Hardware ───────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}Model:${NC} $pi_model"
    echo -e "${CYAN}│${NC} ${WHITE}Revision:${NC} $pi_revision"
    echo -e "${CYAN}│${NC} ${WHITE}Serial:${NC} $pi_serial"
    echo -e "${CYAN}│${NC} ${WHITE}CPU:${NC} $cpu_info ($cpu_cores cores)"
    echo -e "${CYAN}│${NC} ${WHITE}Temperature:${NC} $temp"
    echo -e "${CYAN}└────────────────────────────────────────────────────────────┘${NC}"
    
    echo -e "${CYAN}┌─ Network Information ───────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}Primary IP:${NC} $primary_ip"
    echo -e "${CYAN}│${NC} ${WHITE}Primary MAC:${NC} $primary_mac"
    echo -e "${CYAN}└────────────────────────────────────────────────────────────┘${NC}"
    
    echo -e "${CYAN}┌─ System Resources ───────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}Memory:${NC} $available_mem available of $total_mem"
    echo -e "${CYAN}│${NC} ${WHITE}Disk Usage:${NC} $disk_usage"
    echo -e "${CYAN}└────────────────────────────────────────────────────────────┘${NC}"
    
    echo ""
}

# Function to check if running on Raspberry Pi
check_raspberry_pi() {
    if [[ ! -f /proc/device-tree/model ]] || ! grep -q "Raspberry Pi" /proc/device-tree/model; then
        print_error "This script is designed for Raspberry Pi devices only!"
        exit 1
    fi
    
    local model=$(cat /proc/device-tree/model 2>/dev/null | tr -d '\0' || echo "Unknown")
    print_success "Detected: $model"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_warning "Running as root. Some operations may not work as expected."
        print_info "Consider running as regular user with sudo privileges."
    fi
}

# Function to check network connectivity
check_network() {
    print_info "Checking network connectivity..."
    
    local test_urls=("8.8.8.8" "1.1.1.1" "google.com")
    local connected=false
    
    for url in "${test_urls[@]}"; do
        if ping -c 1 -W 5 "$url" >/dev/null 2>&1; then
            print_success "Network connectivity confirmed via $url"
            connected=true
            break
        fi
    done
    
    if [[ "$connected" == false ]]; then
        print_error "No network connectivity detected!"
        print_warning "Some installations may fail without internet access."
        read -p "Continue anyway? (y/N): " continue_choice
        if [[ ! $continue_choice =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Function to check and install prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check for required commands
    local required_commands=("curl" "wget" "sudo" "systemctl")
    local missing_commands=()
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        print_warning "Missing required commands: ${missing_commands[*]}"
        print_info "Installing missing prerequisites..."
        
        for cmd in "${missing_commands[@]}"; do
            case $cmd in
                "curl"|"wget")
                    if run_command "sudo apt update && sudo apt install -y $cmd" "Installing $cmd" "check_prerequisites"; then
                        print_success "$cmd installed"
                    fi
                    ;;
                "sudo")
                    print_error "sudo is required but not available. Please install it manually."
                    exit 1
                    ;;
                "systemctl")
                    print_error "systemctl is required but not available. This may not be a systemd system."
                    exit 1
                    ;;
            esac
        done
    else
        print_success "All prerequisites are available"
    fi
}

# Function to check disk space
check_disk_space() {
    print_info "Checking available disk space..."
    
    local available_space=$(df / | awk 'NR==2 {print $4}')
    local required_space=2097152  # 2GB in KB
    
    if [[ $available_space -lt $required_space ]]; then
        print_warning "Low disk space detected: $(($available_space / 1024 / 1024))GB available"
        print_warning "Recommended: At least 2GB free space"
        read -p "Continue anyway? (y/N): " continue_choice
        if [[ ! $continue_choice =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        print_success "Sufficient disk space available: $(($available_space / 1024 / 1024))GB"
    fi
}

# Function to update system
update_system() {
    print_header "System Update"
    local success_count=0
    local total_operations=4
    
    if run_command "sudo apt update -y" "Updating package lists" "update_system"; then
        ((success_count++))
    fi
    
    if run_command "sudo apt upgrade -y" "Upgrading system packages" "update_system"; then
        ((success_count++))
    fi
    
    if run_command "sudo apt autoremove -y" "Removing unused packages" "update_system"; then
        ((success_count++))
    fi
    
    if run_command "sudo apt autoclean" "Cleaning package cache" "update_system"; then
        ((success_count++))
    fi
    
    if [[ $success_count -eq $total_operations ]]; then
        print_success "System update completed successfully!"
    else
        print_warning "System update completed with $((total_operations - success_count)) failures"
    fi
}

# Function to install essential packages
install_essentials() {
    print_header "Essential Packages Installation"
    
    local packages=(
        "curl"
        "wget"
        "git"
        "htop"
        "nano"
        "vim"
        "tree"
        "unzip"
        "zip"
        "jq"
        "dialog"
        "whiptail"
    )
    
    local success_count=0
    local total_packages=${#packages[@]}
    
    print_info "Installing essential packages..."
    for package in "${packages[@]}"; do
        if install_package "$package" "install_essentials"; then
            ((success_count++))
        fi
    done
    
    if [[ $success_count -eq $total_packages ]]; then
        print_success "All essential packages installed successfully!"
    else
        print_warning "Essential packages installation completed with $((total_packages - success_count)) failures"
    fi
}

# Function to configure system settings
configure_system() {
    print_header "System Configuration"
    
    local success_count=0
    local total_operations=4
    
    if run_command "sudo raspi-config nonint do_expand_rootfs" "Expanding filesystem" "configure_system"; then
        ((success_count++))
    fi
    
    if run_command "sudo raspi-config nonint do_wifi_country AU" "Setting WiFi region to AU" "configure_system"; then
        ((success_count++))
    fi
    
    if run_command "sudo raspi-config nonint do_vnc 0" "Enabling VNC server" "configure_system"; then
        ((success_count++))
    fi
    
    if run_command "sudo raspi-config nonint do_ssh 0" "Enabling SSH" "configure_system"; then
        ((success_count++))
    fi
    
    if [[ $success_count -eq $total_operations ]]; then
        print_success "System configuration completed successfully!"
    else
        print_warning "System configuration completed with $((total_operations - success_count)) failures"
    fi
}

# Function to add repository with modern method
add_repository() {
    local repo_name=$1
    local gpg_url=$2
    local repo_url=$3
    local repo_dist=$4
    
    print_info "Adding $repo_name repository..."
    
    # Create temporary directory for GPG key
    local temp_dir=$(mktemp -d)
    
    # Download and add GPG key using modern method
    if run_command "wget -qO- '$gpg_url' | gpg --dearmor -o '$temp_dir/$repo_name.gpg'" "Downloading $repo_name GPG key" "add_repository"; then
        if run_command "sudo mv '$temp_dir/$repo_name.gpg' '/etc/apt/keyrings/$repo_name.gpg'" "Installing $repo_name GPG key" "add_repository"; then
            if run_command "echo 'deb [signed-by=/etc/apt/keyrings/$repo_name.gpg] $repo_url $repo_dist main' | sudo tee '/etc/apt/sources.list.d/$repo_name.list'" "Adding $repo_name repository" "add_repository"; then
                print_success "$repo_name repository added successfully"
                rm -rf "$temp_dir"
                return 0
            fi
        fi
    fi
    
    rm -rf "$temp_dir"
    return 1
}

# Function to install monitoring stack
install_monitoring_stack() {
    print_header "Monitoring Stack Installation"
    
    local success_count=0
    local total_operations=4
    
    # Try to detect the correct Debian version
    local debian_codename=$(lsb_release -cs 2>/dev/null || echo "bullseye")
    print_info "Detected Debian codename: $debian_codename"
    
    # Install InfluxDB
    print_info "Setting up InfluxDB..."
    if add_repository "influxdb" "https://repos.influxdata.com/influxdb.key" "https://repos.influxdata.com/debian" "$debian_codename"; then
        if run_command "sudo apt update && sudo apt install -y influxdb" "Installing InfluxDB" "install_monitoring_stack"; then
            if run_command "sudo systemctl enable influxdb && sudo systemctl start influxdb" "Starting InfluxDB service" "install_monitoring_stack"; then
                if validate_service "influxdb"; then
                    ((success_count++))
                fi
            fi
        fi
    fi
    
    # Install Grafana
    print_info "Setting up Grafana..."
    if add_repository "grafana" "https://packages.grafana.com/gpg.key" "https://packages.grafana.com/oss/deb" "stable"; then
        if run_command "sudo apt update && sudo apt install -y grafana" "Installing Grafana" "install_monitoring_stack"; then
            if run_command "sudo systemctl enable grafana-server && sudo systemctl start grafana-server" "Starting Grafana service" "install_monitoring_stack"; then
                if validate_service "grafana-server"; then
                    ((success_count++))
                fi
            fi
        fi
    fi
    
    # Provide access information
    if [[ $success_count -ge 1 ]]; then
        print_success "Monitoring stack installation completed!"
        print_info "InfluxDB: http://localhost:8086"
        print_info "Grafana: http://localhost:3000 (admin/admin)"
    else
        print_warning "Monitoring stack installation completed with failures"
        print_info "You may need to install these services manually"
    fi
}

# Function to install network tools
install_network_tools() {
    print_header "Network Tools Installation"
    
    local packages=(
        "kismet"
        "bettercap"
        "aircrack-ng"
        "nmap"
        "tcpdump"
        "wireshark-common"
        "tshark"
        "netcat"
        "netcat-openbsd"
        "netdiscover"
        "masscan"
        "zmap"
    )
    
    local success_count=0
    local total_packages=${#packages[@]}
    
    print_info "Installing network security tools..."
    for package in "${packages[@]}"; do
        if install_package "$package" "install_network_tools"; then
            ((success_count++))
        fi
    done
    
    if [[ $success_count -eq $total_packages ]]; then
        print_success "All network tools installed successfully!"
    else
        print_warning "Network tools installation completed with $((total_packages - success_count)) failures"
    fi
}

# Function to install database
install_database() {
    print_header "Database Installation"
    
    local success_count=0
    local total_operations=2
    
    if run_command "sudo apt install -y postgresql postgresql-contrib" "Installing PostgreSQL" "install_database"; then
        ((success_count++))
    fi
    
    if run_command "sudo systemctl enable postgresql && sudo systemctl start postgresql" "Starting PostgreSQL service" "install_database"; then
        ((success_count++))
    fi
    
    if [[ $success_count -eq $total_operations ]]; then
        print_success "Database installation completed successfully!"
    else
        print_warning "Database installation completed with $((total_operations - success_count)) failures"
    fi
}

# Function to install GPS tools
install_gps_tools() {
    print_header "GPS Tools Installation"
    
    local success_count=0
    local total_operations=2
    
    if run_command "sudo apt install -y gpsd gpsd-clients gpsd-tools" "Installing GPSD and related tools" "install_gps_tools"; then
        ((success_count++))
    fi
    
    if run_command "sudo systemctl enable gpsd && sudo systemctl start gpsd" "Configuring and starting GPSD" "install_gps_tools"; then
        ((success_count++))
    fi
    
    if [[ $success_count -eq $total_operations ]]; then
        print_success "GPS tools installed and configured successfully!"
    else
        print_warning "GPS tools installation completed with $((total_operations - success_count)) failures"
    fi
}

# Function to create interactive menu
show_menu() {
    while true; do
        clear
        echo -e "${PURPLE}${ROCKET} Raspberry Pi 5 Automated Setup${NC}"
        echo -e "${PURPLE}===========================================${NC}"
        echo ""
        echo -e "${WHITE}Select installation options:${NC}"
        echo ""
        echo -e "${GREEN}1)${NC} ${PACKAGE} Install All (Recommended)"
        echo -e "${GREEN}2)${NC} ${GEAR} System Configuration Only"
        echo -e "${GREEN}3)${NC} ${MONITOR} Monitoring Stack (Grafana + InfluxDB)"
        echo -e "${GREEN}4)${NC} ${SECURITY} Network Security Tools"
        echo -e "${GREEN}5)${NC} ${DATABASE} Database (PostgreSQL)"
        echo -e "${GREEN}6)${NC} ${NETWORK} GPS Tools"
        echo -e "${GREEN}7)${NC} ${TOOLS} Essential Packages Only"
        echo -e "${GREEN}8)${NC} Custom Selection"
        echo -e "${GREEN}9)${NC} Exit"
        echo ""
        read -p "Enter your choice [1-9]: " choice
        
        case $choice in
            1)
                print_info "Installing everything..."
                update_system
                install_essentials
                configure_system
                install_monitoring_stack
                install_network_tools
                install_database
                install_gps_tools
                print_success "Complete installation finished!"
                break
                ;;
            2)
                configure_system
                break
                ;;
            3)
                install_monitoring_stack
                break
                ;;
            4)
                install_network_tools
                break
                ;;
            5)
                install_database
                break
                ;;
            6)
                install_gps_tools
                break
                ;;
            7)
                install_essentials
                break
                ;;
            8)
                show_custom_menu
                break
                ;;
            9)
                print_info "Exiting..."
                exit 0
                ;;
            *)
                print_error "Invalid option. Please try again."
                sleep 2
                ;;
        esac
    done
}

# Function to show custom selection menu
show_custom_menu() {
    print_header "Custom Selection"
    
    local options=(
        "System Update" "on"
        "Essential Packages" "on"
        "System Configuration" "on"
        "Monitoring Stack" "off"
        "Network Tools" "off"
        "Database" "off"
        "GPS Tools" "off"
    )
    
    local selections=()
    for ((i=0; i<${#options[@]}; i+=2)); do
        selections+=("${options[i]}")
        selections+=("${options[i+1]}")
    done
    
    # Use dialog for multi-select
    local choices=$(dialog --checklist "Select components to install:" 20 60 10 "${selections[@]}" 2>&1 >/dev/tty)
    
    if [[ -n "$choices" ]]; then
        for choice in $choices; do
            case $choice in
                "System Update")
                    update_system
                    ;;
                "Essential Packages")
                    install_essentials
                    ;;
                "System Configuration")
                    configure_system
                    ;;
                "Monitoring Stack")
                    install_monitoring_stack
                    ;;
                "Network Tools")
                    install_network_tools
                    ;;
                "Database")
                    install_database
                    ;;
                "GPS Tools")
                    install_gps_tools
                    ;;
            esac
        done
        print_success "Custom installation completed!"
    else
        print_info "No components selected."
    fi
}

# Main execution
main() {
    clear
    print_header "Raspberry Pi 5 Automated Setup Script"
    print_info "Starting setup process..."
    
    # Create log file first
    touch "$LOG_FILE"
    log_message "Starting Raspberry Pi setup script"
    
    # Check prerequisites
    check_raspberry_pi
    check_root
    check_network
    check_prerequisites
    check_disk_space
    
    # Display system information
    echo ""
    print_info "Displaying system information..."
    display_system_info
    
    # Pause to let user see the information
    read -p "Press Enter to continue to the main menu..."
    
    # Show main menu
    show_menu
    
    print_success "Setup process completed!"
    print_info "Log file saved to: $LOG_FILE"
    print_info "You may need to reboot for some changes to take effect."
    
    # Show summary of what was attempted
    print_header "Installation Summary"
    print_info "Check the log file for detailed information about what succeeded and what failed."
    print_info "Log file location: $LOG_FILE"
    
    read -p "Would you like to reboot now? (y/N): " reboot_choice
    if [[ $reboot_choice =~ ^[Yy]$ ]]; then
        print_info "Rebooting in 5 seconds..."
        sleep 5
        sudo reboot
    fi
}

# Run main function
main "$@"
