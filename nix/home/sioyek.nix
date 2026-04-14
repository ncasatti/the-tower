# nix/home/sioyek.nix
# Sioyek PDF viewer configuration via Home Manager.

{ ... }:

{
  xdg.configFile."sioyek/prefs_user.config".text = ''
    # Sioyek Preferences
    default_dark_mode 1
    font_size 12
    should_use_multiple_monitors 0
  '';

  xdg.configFile."sioyek/keys_user.config".text = ''
    # Colemak-friendly navigation
    n scroll_down
    e scroll_up
    i goto_definition
    o next_page
    u previous_page
    
    # Standard navigation
    <C-u> previous_page
    <C-e> next_page
  '';
}
