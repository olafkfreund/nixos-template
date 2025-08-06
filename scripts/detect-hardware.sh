#!/usr/bin/env bash

# Hardware Type Detection Script
# Detects whether the system is a laptop, desktop, or server

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Detection confidence levels
CONFIDENCE_HIGH=90
CONFIDENCE_MEDIUM=70
CONFIDENCE_LOW=50

print_info() {
    echo -e "${BLUE}INFO${NC} $1"
}

print_success() {
    echo -e "${GREEN}SUCCESS${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}WARNING${NC} $1"
}

print_error() {
    echo -e "${RED}ERROR${NC} $1"
}

# Initialize detection scores
laptop_score=0
desktop_score=0
server_score=0
workstation_score=0

# Hardware detection functions
detect_chassis() {
    local chassis_type=""
    local confidence=0
    
    # Method 1: DMI chassis information
    if [ -f /sys/class/dmi/id/chassis_type ]; then
        local chassis_id
        chassis_id=$(cat /sys/class/dmi/id/chassis_type 2>/dev/null || echo "")
        
        case "$chassis_id" in
            8|9|10|14)  # Portable, Laptop, Notebook, Sub Notebook
                chassis_type="laptop"
                laptop_score=$((laptop_score + 30))
                confidence=$CONFIDENCE_HIGH
                ;;
            3|4|6|7)    # Desktop, Low Profile Desktop, Mini Tower, Tower
                chassis_type="desktop" 
                desktop_score=$((desktop_score + 30))
                confidence=$CONFIDENCE_HIGH
                ;;
            17|23)      # Main Server Chassis, Rack Mount Chassis
                chassis_type="server"
                server_score=$((server_score + 30))
                confidence=$CONFIDENCE_HIGH
                ;;
            13)         # All in One
                chassis_type="desktop"
                desktop_score=$((desktop_score + 25))
                confidence=$CONFIDENCE_MEDIUM
                ;;
            *)
                confidence=$CONFIDENCE_LOW
                ;;
        esac
    fi
    
    # Method 2: Check product name for clues
    if [ -f /sys/class/dmi/id/product_name ]; then
        local product_name
        product_name=$(cat /sys/class/dmi/id/product_name 2>/dev/null | tr '[:upper:]' '[:lower:]' || echo "")
        
        if [[ $product_name =~ (laptop|notebook|thinkpad|elitebook|pavilion.*laptop|inspiron.*laptop) ]]; then
            laptop_score=$((laptop_score + 20))
        elif [[ $product_name =~ (server|poweredge|proliant|system.*x) ]]; then
            server_score=$((server_score + 25))
        elif [[ $product_name =~ (workstation|precision|z.*workstation) ]]; then
            workstation_score=$((workstation_score + 25))
        elif [[ $product_name =~ (desktop|optiplex|vostro.*desktop|inspiron.*desktop) ]]; then
            desktop_score=$((desktop_score + 20))
        fi
    fi
    
    echo "$chassis_type:$confidence"
}

detect_battery() {
    local has_battery=false
    local battery_count=0
    local confidence=0
    
    # Check for battery presence
    if [ -d /sys/class/power_supply ]; then
        for ps in /sys/class/power_supply/*/; do
            if [ -f "${ps}type" ]; then
                local type
                type=$(cat "${ps}type" 2>/dev/null || echo "")
                if [ "$type" = "Battery" ]; then
                    has_battery=true
                    battery_count=$((battery_count + 1))
                fi
            fi
        done
    fi
    
    # UPS systems can have batteries too, but laptops typically have 1-2 batteries
    if [ "$has_battery" = true ]; then
        if [ $battery_count -le 2 ]; then
            laptop_score=$((laptop_score + 25))
            confidence=$CONFIDENCE_HIGH
        else
            # Multiple batteries might indicate server UPS
            server_score=$((server_score + 10))
            confidence=$CONFIDENCE_MEDIUM
        fi
    else
        # No battery strongly suggests desktop or server
        desktop_score=$((desktop_score + 15))
        server_score=$((server_score + 10))
        confidence=$CONFIDENCE_MEDIUM
    fi
    
    echo "$has_battery:$battery_count:$confidence"
}

detect_display() {
    local has_builtin_display=false
    local external_displays=0
    local confidence=0
    
    # Check for built-in displays (laptops)
    if command -v xrandr >/dev/null 2>&1 && [ -n "${DISPLAY:-}" ]; then
        # Running in X11 environment
        local displays
        displays=$(xrandr --listmonitors 2>/dev/null | grep -c "^ " || echo "0")
        external_displays=$displays
        
        # Check for laptop-specific display names
        if xrandr 2>/dev/null | grep -q -E "(eDP|LVDS|DSI)"; then
            has_builtin_display=true
            laptop_score=$((laptop_score + 20))
            confidence=$CONFIDENCE_HIGH
        fi
    elif [ -d /sys/class/drm ]; then
        # Check DRM connectors
        for connector in /sys/class/drm/card*/; do
            if [ -f "${connector}status" ]; then
                local status
                status=$(cat "${connector}status" 2>/dev/null || echo "")
                if [ "$status" = "connected" ]; then
                    external_displays=$((external_displays + 1))
                fi
            fi
        done
        
        # Look for laptop display connectors
        for connector in /sys/class/drm/card*-{eDP,LVDS,DSI}*/; do
            if [ -d "$connector" ]; then
                has_builtin_display=true
                laptop_score=$((laptop_score + 20))
                confidence=$CONFIDENCE_HIGH
                break
            fi
        done
    fi
    
    # Multiple external displays suggest workstation/desktop
    if [ $external_displays -gt 1 ]; then
        desktop_score=$((desktop_score + 10))
        workstation_score=$((workstation_score + 15))
    elif [ $external_displays -eq 0 ]; then
        # No displays might indicate headless server
        server_score=$((server_score + 15))
    fi
    
    echo "$has_builtin_display:$external_displays:$confidence"
}

detect_network_interfaces() {
    local wired_count=0
    local wireless_count=0
    local confidence=0
    
    # Count network interfaces
    for iface in /sys/class/net/*/; do
        local iface_name
        iface_name=$(basename "$iface")
        
        # Skip loopback and virtual interfaces
        if [[ $iface_name =~ ^(lo|virbr|docker|veth|tun|tap) ]]; then
            continue
        fi
        
        # Check interface type
        if [ -f "${iface}wireless" ] || [[ $iface_name =~ ^(wl|wifi) ]]; then
            wireless_count=$((wireless_count + 1))
        elif [[ $iface_name =~ ^(en|eth) ]]; then
            wired_count=$((wired_count + 1))
        fi
    done
    
    # Wireless interface strongly suggests laptop
    if [ $wireless_count -gt 0 ]; then
        laptop_score=$((laptop_score + 20))
        confidence=$CONFIDENCE_HIGH
    fi
    
    # Multiple wired interfaces suggest server/workstation
    if [ $wired_count -gt 1 ]; then
        server_score=$((server_score + 15))
        workstation_score=$((workstation_score + 10))
        confidence=$CONFIDENCE_MEDIUM
    elif [ $wired_count -eq 1 ] && [ $wireless_count -eq 0 ]; then
        # Only wired, no wireless - likely desktop or server
        desktop_score=$((desktop_score + 10))
        server_score=$((server_score + 5))
        confidence=$CONFIDENCE_MEDIUM
    fi
    
    echo "$wired_count:$wireless_count:$confidence"
}

detect_audio_hardware() {
    local has_speakers=false
    local has_microphone=false
    local confidence=0
    
    # Check for audio devices
    if command -v pactl >/dev/null 2>&1; then
        # Check PulseAudio/PipeWire sinks (speakers/headphones)
        local sinks
        sinks=$(pactl list short sinks 2>/dev/null | wc -l || echo "0")
        if [ "$sinks" -gt 0 ]; then
            has_speakers=true
        fi
        
        # Check sources (microphones)
        local sources
        sources=$(pactl list short sources 2>/dev/null | grep -v monitor | wc -l || echo "0")
        if [ "$sources" -gt 0 ]; then
            has_microphone=true
        fi
    elif [ -d /proc/asound ]; then
        # Check ALSA devices
        if [ -n "$(ls -A /proc/asound/card*/pcm*p 2>/dev/null || true)" ]; then
            has_speakers=true
        fi
        if [ -n "$(ls -A /proc/asound/card*/pcm*c 2>/dev/null || true)" ]; then
            has_microphone=true
        fi
    fi
    
    # Built-in microphone suggests laptop
    if [ "$has_microphone" = true ]; then
        laptop_score=$((laptop_score + 10))
        confidence=$CONFIDENCE_MEDIUM
    fi
    
    # No audio hardware might suggest server
    if [ "$has_speakers" = false ] && [ "$has_microphone" = false ]; then
        server_score=$((server_score + 10))
        confidence=$CONFIDENCE_MEDIUM
    fi
    
    echo "$has_speakers:$has_microphone:$confidence"
}

detect_usb_devices() {
    local keyboard_count=0
    local mouse_count=0
    local webcam_count=0
    local confidence=0
    
    # Check USB devices
    if command -v lsusb >/dev/null 2>&1; then
        # Count input devices
        keyboard_count=$(lsusb 2>/dev/null | grep -i keyboard | wc -l || echo "0")
        mouse_count=$(lsusb 2>/dev/null | grep -i mouse | wc -l || echo "0")
        webcam_count=$(lsusb 2>/dev/null | grep -iE "(camera|webcam)" | wc -l || echo "0")
        
        confidence=$CONFIDENCE_MEDIUM
    fi
    
    # External keyboard/mouse suggests desktop setup
    if [ $keyboard_count -gt 0 ] || [ $mouse_count -gt 0 ]; then
        desktop_score=$((desktop_score + 5))
        workstation_score=$((workstation_score + 5))
    fi
    
    # Webcam suggests laptop or workstation
    if [ $webcam_count -gt 0 ]; then
        laptop_score=$((laptop_score + 10))
        workstation_score=$((workstation_score + 5))
    fi
    
    echo "$keyboard_count:$mouse_count:$webcam_count:$confidence"
}

detect_cpu_memory() {
    local cpu_cores=0
    local total_memory_gb=0
    local confidence=0
    
    # Get CPU core count
    cpu_cores=$(nproc 2>/dev/null || echo "1")
    
    # Get total memory in GB
    if [ -f /proc/meminfo ]; then
        local total_memory_kb
        total_memory_kb=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
        total_memory_gb=$((total_memory_kb / 1024 / 1024))
    fi
    
    confidence=$CONFIDENCE_HIGH
    
    # High-end specs suggest workstation or server
    if [ $cpu_cores -ge 16 ] || [ $total_memory_gb -ge 32 ]; then
        server_score=$((server_score + 15))
        workstation_score=$((workstation_score + 20))
    elif [ $cpu_cores -ge 8 ] || [ $total_memory_gb -ge 16 ]; then
        desktop_score=$((desktop_score + 10))
        workstation_score=$((workstation_score + 15))
    elif [ $cpu_cores -le 4 ] && [ $total_memory_gb -le 8 ]; then
        # Lower-end specs might suggest laptop
        laptop_score=$((laptop_score + 5))
    fi
    
    echo "$cpu_cores:$total_memory_gb:$confidence"
}

# Main detection function
detect_hardware_type() {
    print_info "Starting hardware type detection..."
    echo
    
    # Run all detection methods
    print_info "Checking chassis type..."
    local chassis_result
    chassis_result=$(detect_chassis)
    IFS=':' read -r chassis_type chassis_confidence <<< "$chassis_result"
    [ -n "$chassis_type" ] && print_info "Chassis type: $chassis_type (confidence: $chassis_confidence%)"
    
    print_info "Checking for battery..."
    local battery_result
    battery_result=$(detect_battery)
    IFS=':' read -r has_battery battery_count battery_confidence <<< "$battery_result"
    print_info "Battery: $has_battery, count: $battery_count (confidence: $battery_confidence%)"
    
    print_info "Checking display configuration..."
    local display_result
    display_result=$(detect_display)
    IFS=':' read -r has_builtin external_displays display_confidence <<< "$display_result"
    print_info "Built-in display: $has_builtin, external displays: $external_displays (confidence: $display_confidence%)"
    
    print_info "Checking network interfaces..."
    local network_result
    network_result=$(detect_network_interfaces)
    IFS=':' read -r wired_count wireless_count network_confidence <<< "$network_result"
    print_info "Wired interfaces: $wired_count, wireless: $wireless_count (confidence: $network_confidence%)"
    
    print_info "Checking audio hardware..."
    local audio_result
    audio_result=$(detect_audio_hardware)
    IFS=':' read -r has_speakers has_microphone audio_confidence <<< "$audio_result"
    print_info "Speakers: $has_speakers, microphone: $has_microphone (confidence: $audio_confidence%)"
    
    print_info "Checking USB devices..."
    local usb_result
    usb_result=$(detect_usb_devices)
    IFS=':' read -r keyboard_count mouse_count webcam_count usb_confidence <<< "$usb_result"
    print_info "USB keyboards: $keyboard_count, mice: $mouse_count, webcams: $webcam_count (confidence: $usb_confidence%)"
    
    print_info "Checking CPU and memory..."
    local cpu_memory_result
    cpu_memory_result=$(detect_cpu_memory)
    IFS=':' read -r cpu_cores total_memory_gb cpu_memory_confidence <<< "$cpu_memory_result"
    print_info "CPU cores: $cpu_cores, memory: ${total_memory_gb}GB (confidence: $cpu_memory_confidence%)"
    
    echo
    print_info "Detection scores:"
    echo "  Laptop: $laptop_score"
    echo "  Desktop: $desktop_score"
    echo "  Workstation: $workstation_score"
    echo "  Server: $server_score"
    echo
    
    # Determine hardware type
    local hardware_type="desktop"  # Default
    local max_score=$desktop_score
    local confidence_level="medium"
    
    if [ $laptop_score -gt $max_score ]; then
        hardware_type="laptop"
        max_score=$laptop_score
    fi
    
    if [ $workstation_score -gt $max_score ]; then
        hardware_type="workstation"
        max_score=$workstation_score
    fi
    
    if [ $server_score -gt $max_score ]; then
        hardware_type="server"
        max_score=$server_score
    fi
    
    # Determine confidence level
    if [ $max_score -ge 60 ]; then
        confidence_level="high"
    elif [ $max_score -ge 30 ]; then
        confidence_level="medium"
    else
        confidence_level="low"
    fi
    
    # Output results
    print_success "Hardware type detected: $hardware_type"
    print_info "Confidence level: $confidence_level ($max_score points)"
    echo
    
    # Provide recommendations
    print_info "Recommended configuration:"
    case "$hardware_type" in
        laptop)
            echo "  - Power profile: laptop"
            echo "  - Battery optimization: enabled"
            echo "  - TLP power management: enabled"
            echo "  - Desktop environment: GNOME (with power management)"
            echo "  - WiFi power saving: enabled"
            ;;
        desktop)
            echo "  - Power profile: desktop"
            echo "  - Performance mode: enabled"
            echo "  - USB autosuspend: disabled (better for peripherals)"
            echo "  - Desktop environment: GNOME or KDE"
            echo "  - Gaming optimizations: optional"
            ;;
        workstation)
            echo "  - Power profile: workstation"
            echo "  - Performance mode: enabled"
            echo "  - Multi-monitor support: enabled"
            echo "  - Professional applications: enabled"
            echo "  - Development tools: full suite"
            ;;
        server)
            echo "  - Power profile: server"
            echo "  - Headless operation: enabled"
            echo "  - SSH server: enabled with hardening"
            echo "  - Monitoring: Prometheus + Grafana"
            echo "  - Security: Fail2Ban, AppArmor"
            ;;
    esac
    
    echo
    
    # Export results for other scripts
    echo "HARDWARE_TYPE=$hardware_type"
    echo "CONFIDENCE_LEVEL=$confidence_level"
    echo "CONFIDENCE_SCORE=$max_score"
    echo "HAS_BATTERY=$has_battery"
    echo "HAS_WIRELESS=$( [ $wireless_count -gt 0 ] && echo true || echo false )"
    echo "CPU_CORES=$cpu_cores"
    echo "MEMORY_GB=$total_memory_gb"
}

# Command line interface
main() {
    case "${1:-detect}" in
        "detect"|"")
            detect_hardware_type
            ;;
        "type")
            # Just output the hardware type
            local result
            result=$(detect_hardware_type 2>/dev/null | grep "HARDWARE_TYPE=" | cut -d= -f2)
            echo "${result:-desktop}"
            ;;
        "profile")
            # Output suitable power management profile
            local result
            result=$(detect_hardware_type 2>/dev/null | grep "HARDWARE_TYPE=" | cut -d= -f2)
            echo "${result:-desktop}"
            ;;
        "help"|"-h"|"--help")
            echo "Hardware Detection Script"
            echo ""
            echo "Usage: $0 [COMMAND]"
            echo ""
            echo "Commands:"
            echo "  detect    Full hardware detection with recommendations (default)"
            echo "  type      Output detected hardware type only"
            echo "  profile   Output suitable power management profile"
            echo "  help      Show this help message"
            ;;
        *)
            print_error "Unknown command: $1"
            echo "Use '$0 help' for usage information."
            exit 1
            ;;
    esac
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi