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

  # --- PLUGIN PATHS (system-wide, propagates to GUI sessions) ---
  # Audio plugins (LV2/LADSPA/DSSI/VST/VST3) live under the per-user profile
  # directory because Home Manager installs them. Without these vars exported
  # at the system level, GUI apps started by Hyprland/greetd inherit an empty
  # $LV2_PATH and miss mda, Calf, etc. The double-quoted Nix strings expand
  # `$USER` and `$HOME` lazily at shell-source time (Nix strings don't
  # interpolate `$USER` because it's not followed by `{`).
  environment.sessionVariables = {
    LV2_PATH    = "/etc/profiles/per-user/$USER/lib/lv2:$HOME/.local/share/lv2";
    LADSPA_PATH = "/etc/profiles/per-user/$USER/lib/ladspa";
    DSSI_PATH   = "/etc/profiles/per-user/$USER/lib/dssi";
    VST_PATH    = "/etc/profiles/per-user/$USER/lib/vst";
    VST3_PATH   = "/etc/profiles/per-user/$USER/lib/vst3";
  };

  # --- REALTIME AUDIO LIMITS ---
  # Required for low-latency operation with Focusrite interface.
  security.pam.loginLimits = [
    { domain = "@audio"; item = "memlock"; type = "-"; value = "unlimited"; }
    { domain = "@audio"; item = "rtprio";  type = "-"; value = "99"; }
    { domain = "@audio"; item = "nice";    type = "-"; value = "-19"; }
  ];
}
