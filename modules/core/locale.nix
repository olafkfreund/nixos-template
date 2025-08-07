{ lib, ... }:

{
  # Internationalization (en_US.UTF-8 is NixOS default)
  i18n.defaultLocale = "en_US.UTF-8";

  # Time zone (users should set this in host config)
  time.timeZone = lib.mkDefault "UTC";

  # Console uses X keyboard config by default
  console.useXkbConfig = true;

  # Keyboard layout defaults to "us" - no need to explicitly set
}
