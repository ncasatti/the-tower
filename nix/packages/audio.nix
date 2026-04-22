# nix/packages/audio.nix
# Audio-related packages for Home Manager
# Note: System-level services (PipeWire, PAM) must be managed by Arch Linux.

{ pkgs, ... }:

{
  # --- PLUGIN DISCOVERY PATHS ---
  # Required for Carla and other hosts to find Nix-managed plugins.
  home.sessionVariables = {
    LV2_PATH    = "$HOME/.nix-profile/lib/lv2";
    LADSPA_PATH = "$HOME/.nix-profile/lib/ladspa";
    DSSI_PATH   = "$HOME/.nix-profile/lib/dssi";
    VST_PATH    = "$HOME/.nix-profile/lib/vst";
    VST3_PATH   = "$HOME/.nix-profile/lib/vst3";
  };

  home.packages = with pkgs; [
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
}
