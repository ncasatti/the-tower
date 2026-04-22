# nix/modules/audio.nix
# PipeWire audio subsystem + realtime PAM limits (system-level).
# Audio packages are managed in nix/packages/audio.nix via Home Manager.

{ ... }:

{
  # --- AUDIO SUBSYSTEM (PipeWire) ---
  # Replaces PulseAudio and JACK. Provides ultra-low latency for Focusrite & Carla.
  security.rtkit.enable = true;
  services.pipewire = {
    enable          = true;
    alsa.enable     = true;
    alsa.support32Bit = true;
    pulse.enable    = true;
    # CRITICAL: Emulates JACK server natively for Carla
    jack.enable     = true;
  };

  # --- REALTIME AUDIO LIMITS ---
  # Required for low-latency operation with Focusrite interface.
  security.pam.loginLimits = [
    { domain = "@audio"; item = "memlock"; type = "-"; value = "unlimited"; }
    { domain = "@audio"; item = "rtprio";  type = "-"; value = "99"; }
    { domain = "@audio"; item = "nice";    type = "-"; value = "-19"; }
  ];
}
