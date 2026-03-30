# nix/hosts/notebook/audio.nix
# PipeWire audio subsystem + pro audio packages + realtime PAM limits

{ config, pkgs, inputs, ... }:

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

  # --- PRO AUDIO PACKAGES ---
  environment.systemPackages = with pkgs; [
    # --- DAWs & Hosts ---
    ardour          # Professional DAW
    carla           # Plugin host (LV2, VST, SF2, SFZ)
    qjackctl        # JACK control GUI
    qpwgraph        # PipeWire graph GUI

    # --- LV2/LADSPA Plugins ---
    calf            # LV2 plugin suite (EQ, compressors, reverbs)
    x42-plugins     # Professional meters, EQ, analyzers
    gxplugins-lv2   # Guitarix LV2 plugins (amp sims, effects)

    # --- Libraries & Engines ---
    fluidsynth      # SoundFont synthesizer (used by Carla for SF2)
    lilv            # LV2 plugin host library
    lv2             # LV2 plugin standard
    aubio           # Audio analysis (pitch detection, onset)

    # --- Audio Utilities ---
    pavucontrol     # PipeWire/PulseAudio volume control GUI
    pamixer         # CLI mixer
  ];

  # --- REALTIME AUDIO LIMITS ---
  # Required for low-latency operation with Focusrite interface.
  security.pam.loginLimits = [
    { domain = "@audio"; item = "memlock"; type = "-"; value = "unlimited"; }
    { domain = "@audio"; item = "rtprio";  type = "-"; value = "99"; }
    { domain = "@audio"; item = "nice";    type = "-"; value = "-19"; }
  ];
}
