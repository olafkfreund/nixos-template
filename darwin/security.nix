# Security Configuration for macOS
# Manages security settings, certificates, and privacy controls

{ pkgs, ... }:

{
  # PAM (Pluggable Authentication Modules) configuration
  security.pam = {
    # Enable Touch ID for sudo authentication
    enableSudoTouchIdAuth = true;
  };

  # System security packages and tools
  environment.systemPackages = with pkgs; [
    # Security scanning and analysis
    nmap # Network security scanner
    wireshark # Network protocol analyzer
    tcpdump # Network packet analyzer

    # Cryptography and certificates
    gnupg # GNU Privacy Guard
    openssl # SSL/TLS toolkit
    age # Modern encryption tool
    sops # Secrets management

    # Password and secrets management
    pass # Command-line password manager
    bitwarden-cli # Bitwarden CLI

    # System security tools
    lynis # Security auditing tool
    rkhunter # Rootkit scanner

    # File integrity and encryption
    rhash # Hash calculator

    # Security utilities and scripts
    (writeShellScriptBin "security-audit" ''
      echo "🔒 macOS Security Audit"
      echo "======================"
      echo ""

      echo "🛡️ System Integrity Protection (SIP) Status:"
      csrutil status | sed 's/^/  /'
      echo ""

      echo "🔐 FileVault Status:"
      fdesetup status | sed 's/^/  /'
      echo ""

      echo "🚫 Gatekeeper Status:"
      spctl --status | sed 's/^/  /'
      echo ""

      echo "🔥 Firewall Status:"
      /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate | sed 's/^/  /'
      echo ""

      echo "👤 Current User Security:"
      echo "  User: $(whoami)"
      echo "  Groups: $(groups)"
      echo "  Admin: $(dseditgroup -o checkmember -m $(whoami) admin && echo 'Yes' || echo 'No')"
      echo ""

      echo "🔑 Keychain Status:"
      security list-keychains | head -5 | sed 's/^/  /'
      echo ""

      echo "🌐 Network Security:"
      echo "  Active connections:"
      netstat -an | grep LISTEN | wc -l | sed 's/^/    /'
      echo "  Open ports:"
      lsof -i -P | grep LISTEN | head -10 | awk '{print "    " $9}' | sort -u
      echo ""

      echo "🔍 Recent Security Events:"
      log show --last 1h --predicate 'category == "security"' | head -10 | sed 's/^/  /' 2>/dev/null || echo "  Security logs not accessible"
    '')

    (writeShellScriptBin "privacy-check" ''
      echo "🔐 Privacy Settings Check"
      echo "========================="
      echo ""

      echo "📍 Location Services:"
      /usr/bin/defaults read com.apple.locationd LocationServicesEnabled | sed 's/^/  Status: /'
      echo ""

      echo "📷 Camera Access:"
      echo "  Recent camera access:"
      log show --last 24h --predicate 'subsystem == "com.apple.TCC" and category == "access"' | grep camera | wc -l | sed 's/^/    Events: /'
      echo ""

      echo "🎤 Microphone Access:"
      echo "  Recent microphone access:"
      log show --last 24h --predicate 'subsystem == "com.apple.TCC" and category == "access"' | grep microphone | wc -l | sed 's/^/    Events: /'
      echo ""

      echo "📱 Screen Recording Permissions:"
      tccutil dump | grep kTCCServiceScreenCapture | wc -l | sed 's/^/  Authorized apps: /'
      echo ""

      echo "🔒 Full Disk Access:"
      tccutil dump | grep kTCCServiceSystemPolicyAllFiles | wc -l | sed 's/^/  Authorized apps: /'
      echo ""

      echo "📊 Analytics & Diagnostics:"
      /usr/bin/defaults read /Library/Application\ Support/CrashReporter/DiagnosticMessagesHistory.plist AutoSubmit 2>/dev/null | sed 's/^/  Auto-submit: /' || echo "  Status: Unknown"
    '')

    (writeShellScriptBin "secure-cleanup" ''
      echo "🧹 Secure System Cleanup"
      echo "========================"
      echo ""

      echo "🗑️ Clearing temporary files securely..."
      find /tmp -type f -name ".*" -delete 2>/dev/null || true
      find ~/Library/Caches -type f -name "*.tmp" -delete 2>/dev/null || true
      echo "  Temporary files cleared"
      echo ""

      echo "📋 Clearing clipboard history..."
      pbcopy < /dev/null
      echo "  Clipboard cleared"
      echo ""

      echo "🕰️ Clearing shell history..."
      history -c 2>/dev/null || true
      > ~/.zsh_history 2>/dev/null || true
      > ~/.bash_history 2>/dev/null || true
      echo "  Shell history cleared"
      echo ""

      echo "🔍 Clearing Spotlight metadata cache..."
      sudo mdutil -E / 2>/dev/null || echo "  Requires sudo privileges"
      echo ""

      echo "🌐 Clearing DNS cache..."
      sudo dscacheutil -flushcache 2>/dev/null || echo "  Requires sudo privileges"
      sudo killall -HUP mDNSResponder 2>/dev/null || true
      echo "  DNS cache cleared"
      echo ""

      echo "✅ Secure cleanup completed!"
    '')

    (writeShellScriptBin "cert-info" ''
      echo "🔐 Certificate Information"
      echo "========================="
      echo ""

      echo "🏪 System Root Certificates:"
      security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain | grep -c "BEGIN CERTIFICATE" | sed 's/^/  Count: /'
      echo ""

      echo "🔑 Login Keychain Certificates:"
      security find-certificate -a -p ~/Library/Keychains/login.keychain-db 2>/dev/null | grep -c "BEGIN CERTIFICATE" | sed 's/^/  Count: /' || echo "  Login keychain not accessible"
      echo ""

      echo "🌐 SSL Certificate Test:"
      echo "  Testing connection to github.com..."
      openssl s_client -connect github.com:443 -servername github.com </dev/null 2>/dev/null | openssl x509 -noout -subject -dates | sed 's/^/    /' || echo "    Connection test failed"
      echo ""

      echo "🔒 Code Signing Verification:"
      echo "  Checking system applications..."
      codesign --verify --verbose /Applications/Safari.app 2>&1 | head -3 | sed 's/^/    /' || echo "    Verification not available"
    '')

    (writeShellScriptBin "firewall-status" ''
      echo "🔥 Firewall Configuration"
      echo "========================="
      echo ""

      echo "🛡️ Application Firewall Status:"
      /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate | sed 's/^/  /'
      echo ""

      echo "📋 Firewall Rules:"
      /usr/libexec/ApplicationFirewall/socketfilterfw --list | sed 's/^/  /'
      echo ""

      echo "🚫 Stealth Mode:"
      /usr/libexec/ApplicationFirewall/socketfilterfw --getstealthmode | sed 's/^/  /'
      echo ""

      echo "🔍 Logging Status:"
      /usr/libexec/ApplicationFirewall/socketfilterfw --getloggingmode | sed 's/^/  /'
      echo ""

      echo "ℹ️ Firewall Management:"
      echo "  Enable:  sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on"
      echo "  Disable: sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate off"
      echo "  Stealth: sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on"
    '')
  ];

  # Security-focused environment variables
  environment.variables = {
    # GPG configuration
    GNUPGHOME = "$HOME/.gnupg";

    # Security-focused defaults
    SOPS_AGE_KEY_FILE = "$HOME/.config/sops/age/keys.txt";

    # Disable potentially unsafe operations
    # DISABLE_AUTO_UPDATE = "1";  # Disable automatic updates if needed
  };

  # System security settings via activation scripts
  system.activationScripts.extraActivation.text = ''
        # Create secure directories
        mkdir -p "$HOME/.gnupg" 2>/dev/null || true
        chmod 700 "$HOME/.gnupg" 2>/dev/null || true

        mkdir -p "$HOME/.config/sops/age" 2>/dev/null || true
        chmod 700 "$HOME/.config/sops" 2>/dev/null || true
        chmod 700 "$HOME/.config/sops/age" 2>/dev/null || true

        # Set up GPG configuration if it doesn't exist
        if [ ! -f "$HOME/.gnupg/gpg.conf" ]; then
          cat > "$HOME/.gnupg/gpg.conf" << 'EOF'
    # GPG Configuration for enhanced security
    use-agent
    charset utf-8
    no-greeting
    no-permission-warning
    keyserver hkps://keys.openpgp.org
    keyserver-options auto-key-retrieve
    personal-cipher-preferences AES256 AES192 AES CAST5
    personal-digest-preferences SHA512 SHA384 SHA256 SHA224
    cert-digest-algo SHA512
    default-preference-list SHA512 SHA384 SHA256 SHA224 AES256 AES192 AES CAST5 ZLIB BZIP2 ZIP Uncompressed
    EOF
        fi

        echo "Security configuration applied"
  '';

  # Additional security-related system defaults
  system.defaults = {
    # Security-related finder settings
    finder = {
      AppleShowAllExtensions = true; # Show all file extensions (security)
      FXEnableExtensionChangeWarning = true; # Warn on extension changes
    };

    # Login window security
    loginwindow = {
      GuestEnabled = false; # Disable guest user
      SHOWFULLNAME = false; # Show usernames, not full names
      DisableConsoleAccess = true; # Disable console access at login
    };

    # Screen saver security
    screensaver = {
      askForPassword = true; # Require password after screensaver
      askForPasswordDelay = 5; # Delay before asking for password (seconds)
    };

    # Global security settings
    NSGlobalDomain = {
      # Disable automatic login
      # This is handled by macOS System Preferences
    };
  };
}
