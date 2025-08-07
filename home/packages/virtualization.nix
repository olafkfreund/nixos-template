# Virtualization and container tools
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # QEMU and VM utilities
    qemu-utils
    virt-manager
    libvirt

    # Container tools
    docker
    docker-compose
    podman
    buildah

    # Cloud tools
    terraform
    kubectl
    helm

    # System utilities for VMs
    spice-vdagent
    qemu-guest-agent
  ];
}