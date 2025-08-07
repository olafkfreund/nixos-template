# Modules Default Import
# Central module registry including the new presets system
{ ... }:

{
  imports = [
    ./core
    ./desktop
    ./development
    ./gaming
    ./hardware
    ./installer
    ./presets # New preset system
    ./security
    ./virtualization
  ];
}
