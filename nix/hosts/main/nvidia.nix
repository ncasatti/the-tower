# nix/hosts/main/nvidia.nix
# NVIDIA proprietary driver for GeForce GTX 1660 Super (Turing).

{ config, ... }:

{
  # --- NVIDIA DRIVER ---
  hardware.nvidia = {
    modesetting.enable = true;  # Required for Wayland/Hyprland
    open = false;               # Turing works best with proprietary
    nvidiaSettings = true;      # nvidia-settings GUI
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # --- XSERVER VIDEO DRIVER ---
  services.xserver.videoDrivers = [ "nvidia" ];

  # --- ENVIRONMENT: Wayland + NVIDIA ---
  environment.sessionVariables = {
    # Force GBM backend for Wayland (required for NVIDIA on Hyprland)
    GBM_BACKEND             = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    WLR_NO_HARDWARE_CURSORS = "1";
  };
}
