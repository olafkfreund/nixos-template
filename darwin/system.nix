# macOS System Configuration
# System-level settings and preferences for nix-darwin

{ lib, ... }:

{
  # System preferences
  system = {
    defaults = {
      # Dock settings
      dock = {
        autohide = true;
        autohide-delay = 0.0;
        autohide-time-modifier = 0.2;
        expose-animation-duration = 0.1;
        launchanim = false;
        mineffect = "genie";
        minimize-to-application = true;
        mru-spaces = false;
        orientation = "bottom";
        show-recents = false;
        static-only = true;
        tilesize = 48;
        wvous-bl-corner = 1; # Bottom-left corner: disabled
        wvous-br-corner = 1; # Bottom-right corner: disabled
        wvous-tl-corner = 2; # Top-left corner: Mission Control
        wvous-tr-corner = 4; # Top-right corner: Desktop
      };

      # Finder settings
      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = false;
        CreateDesktop = false; # Don't show icons on desktop
        FXDefaultSearchScope = "SCcf"; # Search current folder by default
        FXEnableExtensionChangeWarning = false;
        FXPreferredViewStyle = "Nlsv"; # List view by default
        QuitMenuItem = true; # Allow quitting Finder
        ShowPathbar = true;
        ShowStatusBar = true;
        _FXShowPosixPathInTitle = true; # Show full path in title bar
        _FXSortFoldersFirst = true;
      };

      # Trackpad settings
      trackpad = {
        ActuationStrength = 0; # Silent clicking
        Clicking = true; # Enable tap to click
        Dragging = false;
        FirstClickThreshold = 1;
        ForceSuppressed = true;
        SecondClickThreshold = 1;
        TrackpadCornerSecondaryClick = 2; # Bottom-right corner right click
        TrackpadRightClick = true;
        TrackpadThreeFingerDrag = false;
        TrackpadThreeFingerTapGesture = 2; # Three-finger tap for lookup
      };

      # Mouse settings
      NSGlobalDomain = {
        # Key repeat settings
        KeyRepeat = 2; # Fast key repeat
        InitialKeyRepeat = 15; # Short initial delay

        # Mouse and trackpad
        "com.apple.mouse.tapBehavior" = 1; # Tap to click
        "com.apple.trackpad.enableSecondaryClick" = true;

        # Appearance
        AppleInterfaceStyle = "Dark"; # Dark mode
        AppleShowAllExtensions = true;
        AppleShowScrollBars = "WhenScrolling";

        # Behavior
        ApplePressAndHoldEnabled = false; # Disable press-and-hold for accents
        AppleKeyboardUIMode = 3; # Full keyboard access
        AppleTemperatureUnit = "Celsius";
        AppleMeasurementUnits = "Centimeters";
        AppleMetricUnits = 1;

        # Auto-correct and text
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
        NSNavPanelExpandedStateForSaveMode = true;
        NSNavPanelExpandedStateForSaveMode2 = true;

        # Window management
        NSWindowResizeTime = 0.001; # Fast window resize

        # Menu and function keys
        _HIHideMenuBar = false; # Show menu bar
        "com.apple.keyboard.fnState" = false; # F1, F2, etc. behave as standard function keys
      };

      # Login window settings
      loginwindow = {
        GuestEnabled = false; # Disable guest user
        SHOWFULLNAME = false; # Show usernames instead of full names
      };

      # Screen capture settings
      screencapture = {
        location = "~/Pictures/Screenshots";
        type = "png";
        disable-shadow = false;
      };

      # Activity Monitor settings
      ActivityMonitor = {
        IconType = 2; # Show CPU usage in dock icon
        OpenMainWindow = true;
        ShowCategory = 100; # Show all processes
        SortColumn = "CPUUsage";
        SortDirection = 0;
      };

      # Menu extras (system menu items)
      menuExtrasMigratedMojavePref = true;

      # Spaces (Mission Control)
      spaces.spans-displays = false; # Displays have separate spaces

      # Other system settings
      SoftwareUpdate.AutomaticallyInstallMacOSUpdates = false; # Don't auto-install macOS updates
    };

    # Keyboard configuration
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToEscape = true; # Caps Lock becomes Escape (useful for developers)
    };

    # System startup settings
    startup.chime = false; # Disable startup chime
  };

  # Security settings
  security = {
    pam.enableSudoTouchIdAuth = true; # Enable Touch ID for sudo
  };

  # Time settings
  time.timeZone = lib.mkDefault "UTC"; # Can be overridden per host

  # Enable location services (needed for automatic timezone)
  location.enable = true;

  # macOS version compatibility
  # This ensures compatibility with the running macOS version
  system.checks.verifyNixPath = false;

  # Custom activation scripts for macOS-specific setup
  system.activationScripts.postUserActivation.text = ''
    # Reload Dock to apply settings
    /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u || true

    # Restart Finder to apply settings
    killall Finder || true

    # Create Screenshots directory if it doesn't exist
    mkdir -p "$HOME/Pictures/Screenshots" || true

    echo "macOS system settings applied!"
  '';

  # Spotlight settings (disable indexing of certain locations)
  # This is done through defaults write commands in activation scripts
  system.activationScripts.extraActivation.text = ''
    # Disable Spotlight indexing of /nix to prevent slowdowns
    sudo mdutil -i off -d /nix || true 2>/dev/null

    # Add /nix to Spotlight privacy list
    defaults write com.apple.Spotlight orderedPrivacyNames -array-add "/nix"
    defaults write com.apple.Spotlight orderedPrivacyPaths -array-add "/nix"

    # Restart Spotlight to apply changes
    sudo killall mds || true 2>/dev/null
    sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.metadata.mds.plist || true 2>/dev/null
    sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.metadata.mds.plist || true 2>/dev/null
  '';
}
