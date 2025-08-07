{ config, lib, pkgs, ... }:

let
  cfg = config.modules.desktop.audio;
in
{
  options.modules.desktop.audio = {
    enable = lib.mkEnableOption "audio support";
    pipewire = lib.mkEnableOption "PipeWire audio server" // { default = true; };
    lowLatency = lib.mkEnableOption "low latency audio configuration";
  };

  config = lib.mkIf cfg.enable {
    # PipeWire configuration (modern replacement for PulseAudio)
    # Note: rtkit is auto-enabled by PipeWire

    services.pipewire = lib.mkIf cfg.pipewire {
      enable = true;
      audio.enable = true;
      pulse.enable = true; # PulseAudio compatibility
      jack.enable = true; # JACK compatibility

      # Low latency configuration
      extraConfig.pipewire = lib.mkIf cfg.lowLatency {
        "92-low-latency" = {
          "context.properties" = {
            "default.clock.rate" = 48000;
            "default.clock.quantum" = 32;
            "default.clock.min-quantum" = 32;
            "default.clock.max-quantum" = 32;
          };
        };
      };
    };

    # ALSA support (sound.enable is deprecated)
    # sound.enable = false;  # Disabled when using PipeWire

    # Additional audio packages
    environment.systemPackages = with pkgs; [
      pavucontrol # PulseAudio volume control
      playerctl # Media player control
      pulseaudio # For pactl command
    ];
  };
}
