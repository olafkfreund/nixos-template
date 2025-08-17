# NixOS VM Builder Docker Image
# Enables Windows users to build NixOS VMs without installing Nix locally
FROM nixos/nix:latest

# Set environment variables
ENV NIX_CONF_DIR=/root/.config/nix

# Enable experimental features for flakes support
RUN mkdir -p $NIX_CONF_DIR && \
    echo "experimental-features = nix-command flakes" > $NIX_CONF_DIR/nix.conf && \
    echo "substituters = https://cache.nixos.org https://nix-community.cachix.org" >> $NIX_CONF_DIR/nix.conf && \
    echo "trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" >> $NIX_CONF_DIR/nix.conf

# Install nixos-generators and required tools using latest version
RUN nix profile install github:nix-community/nixos-generators && \
    nix profile install nixpkgs#jq --priority 4 && \
    nix profile install nixpkgs#git --priority 4 && \
    nix profile install nixpkgs#curl --priority 4

# Create directories
RUN mkdir -p /scripts /workspace /templates /output

# Copy build scripts
COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh

# Copy default templates
COPY templates/ /templates/

# Set working directory
WORKDIR /workspace

# Default entrypoint
ENTRYPOINT ["/scripts/build-vm.sh"]
CMD ["--help"]
