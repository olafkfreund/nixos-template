# Network Configuration for macOS
# Manages network settings, DNS, and connectivity

{ config, pkgs, lib, ... }:

{
  # Network configuration
  networking = {
    # Computer name settings
    computerName = lib.mkDefault "nix-darwin";  # Computer name shown in System Preferences
    hostName = lib.mkDefault "nixos-darwin";    # Local hostname
    localHostName = lib.mkDefault "nixos-darwin";  # Bonjour/local network name

    # DNS configuration
    dns = [
      # Cloudflare DNS (fast and privacy-focused)
      "1.1.1.1"
      "1.0.0.1"
      
      # Quad9 DNS (security-focused, alternative)
      # "9.9.9.9"
      # "149.112.112.112"
      
      # Google DNS (fallback)
      "8.8.8.8"
      "8.8.4.4"
    ];

    # Search domains
    search = [ "local" ];

    # Network interface configuration
    # Note: macOS network interfaces are typically managed by the system
    # This section is for any additional configuration needed
  };

  # Firewall settings
  # Note: macOS firewall is typically managed through System Preferences
  # These settings complement the built-in firewall
  
  # Hosts file additions
  networking.knownNetworkServices = [
    "Wi-Fi"
    "Bluetooth PAN"
    "Thunderbolt Bridge"
    "Ethernet"  # If available
    "USB 10/100/1000 LAN"  # If using USB-to-Ethernet adapter
  ];

  # System-level network tools and utilities
  environment.systemPackages = with pkgs; [
    # Network diagnostic tools
    dig
    nmap
    traceroute
    iperf3
    curl
    wget
    
    # DNS tools
    dnsutils
    drill
    
    # Network monitoring
    iftop
    nethogs
    bandwhich
    
    # VPN and security tools
    wireguard-tools
    openvpn
    
    # Web development tools
    httpie
    jq
    
    # Network utilities
    (writeShellScriptBin "network-info" ''
      echo "🌐 Network Information"
      echo "===================="
      echo ""
      
      echo "📡 Network Interfaces:"
      ifconfig | grep -E "^[a-z]|inet " | sed 's/^/  /'
      echo ""
      
      echo "🔍 DNS Configuration:"
      cat /etc/resolv.conf | grep nameserver | sed 's/^/  /'
      echo ""
      
      echo "🏠 Default Gateway:"
      route -n get default | grep gateway | sed 's/^/  /'
      echo ""
      
      echo "🌍 External IP:"
      curl -s ifconfig.me && echo
      echo ""
      
      echo "📊 Wi-Fi Information:"
      /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I | sed 's/^/  /' || echo "  Wi-Fi information not available"
      echo ""
      
      echo "🔧 Network Quality:"
      networkQuality -s || echo "  Network quality test not available"
    '')
    
    (writeShellScriptBin "wifi-info" ''
      echo "📡 Wi-Fi Network Information"
      echo "============================"
      echo ""
      
      # Current Wi-Fi info
      echo "🔗 Current Connection:"
      /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I | sed 's/^/  /' || echo "  Not connected to Wi-Fi"
      echo ""
      
      # Available networks
      echo "📶 Available Networks:"
      /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport scan | head -20 | sed 's/^/  /'
      echo ""
      
      # Wi-Fi power status
      echo "⚡ Wi-Fi Power Status:"
      networksetup -getairportpower en0 | sed 's/^/  /'
    '')
    
    (writeShellScriptBin "network-speed-test" ''
      echo "🚀 Network Speed Test"
      echo "===================="
      echo ""
      
      if command -v networkQuality >/dev/null 2>&1; then
        echo "📊 Running macOS Network Quality test..."
        networkQuality
      else
        echo "📊 Running basic speed test..."
        echo "Download test:"
        curl -o /dev/null -s -w "  Speed: %{speed_download} bytes/sec\n  Time: %{time_total}s\n" http://speedtest.wdc01.softlayer.com/downloads/test10.zip
        
        echo ""
        echo "Upload test:"
        dd if=/dev/zero bs=1M count=1 2>/dev/null | curl -X POST --data-binary @- -s -w "  Speed: %{speed_upload} bytes/sec\n  Time: %{time_total}s\n" httpbin.org/post > /dev/null
      fi
    '')
    
    (writeShellScriptBin "dns-flush" ''
      echo "🔄 Flushing DNS cache..."
      sudo dscacheutil -flushcache
      sudo killall -HUP mDNSResponder
      echo "✅ DNS cache flushed!"
    '')
    
    (writeShellScriptBin "network-locations" ''
      echo "📍 Network Locations"
      echo "===================="
      echo ""
      
      echo "Current location:"
      networksetup -getcurrentlocation | sed 's/^/  /'
      echo ""
      
      echo "Available locations:"
      networksetup -listlocations | sed 's/^/  /'
    '')
  ];

  # Custom network configuration scripts
  system.activationScripts.extraActivation.text = ''
    # Set up custom DNS if needed
    # This is handled by the system, but we can add custom hosts entries
    
    # Create network utility scripts directory
    mkdir -p /usr/local/bin/network-utils 2>/dev/null || true
    
    echo "Network configuration applied"
  '';

  # Environment variables for network tools
  environment.variables = {
    # Set default DNS for development
    # DEVELOPMENT_DNS = "1.1.1.1";
    
    # Network debugging
    # NETWORK_DEBUG = "1";
    
    # Curl configuration
    CURL_CA_BUNDLE = "/etc/ssl/cert.pem";  # macOS certificate bundle
  };

  # LaunchDaemon for network monitoring (optional)
  # Uncomment if you want automated network health checks
  # launchd.daemons.network-monitor = {
  #   serviceConfig = {
  #     ProgramArguments = [
  #       "/bin/bash"
  #       "-c"
  #       "ping -c 1 1.1.1.1 > /dev/null && echo 'Network OK' || echo 'Network Issue' | logger"
  #     ];
  #     StartInterval = 300;  # Check every 5 minutes
  #     RunAtLoad = true;
  #   };
  # };
}