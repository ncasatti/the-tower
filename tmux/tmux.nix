{ pkgs, ... }:

{
  # 4. TMUX: Declarative tmux configuration via Home Manager
  programs.tmux = {
    enable = true;

    # --- Core settings ---
    terminal = "tmux-256color";
    shell = "${pkgs.fish}/bin/fish";
    prefix = "C-a";
    baseIndex = 1;
    escapeTime = 0;
    historyLimit = 1000000;
    mouse = true;
    keyMode = "vi";

    # --- Plugins ---
    plugins = with pkgs.tmuxPlugins; [
      sensible

      {
        plugin = yank;
        extraConfig = ''
          set -g @yank_selection_mouse 'clipboard'
          set -g @yank_action 'copy-pipe'
          set -g @override_copy_command 'wl-copy'
        '';
      }

      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-strategy-nvim 'session'
        '';
      }

      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'off'
        '';
      }

      {
        plugin = tmux-thumbs;
        extraConfig = ''
          set -g @thumbs-command 'echo -n {} | wl-copy'
          set -g @thumbs-upcase-command 'echo -n {} | wl-copy'
          set -g @thumbs-regexp-1 'https?://[^ ]+'
          set -g @thumbs-regexp-2 '\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b'
          set -g @thumbs-regexp-3 '[0-9a-f]{7,40}'
          set -g @thumbs-regexp-4 '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'
          set -g @thumbs-regexp-5 '[\w\-\.]+@[\w\-\.]+\.[\w]{2,}'
          set -g @thumbs-regexp-6 '\b[A-Z]{2,}_[A-Z_]+\b'
          set -g @thumbs-contrast 1
          set -g @thumbs-reverse enabled
          set -g @thumbs-unique enabled
        '';
      }

      {
        plugin = tmux-fzf;
        extraConfig = ''
          set-environment -g TMUX_FZF_OPTIONS "-p -w 80% -h 80%"
          unbind t
          bind w run-shell -b "${pkgs.tmuxPlugins.tmux-fzf}/share/tmux-plugins/tmux-fzf/scripts/window.sh"
          bind t run-shell -b "${pkgs.tmuxPlugins.tmux-fzf}/share/tmux-plugins/tmux-fzf/main.sh"
        '';
      }

      {
        plugin = tmux-sessionx;
        extraConfig = ''
          set -g @sessionx-bind 'o'
          set -g @sessionx-bind-zo-new-window 'ctrl-y'
          set -g @sessionx-auto-accept 'off'
          set -g @sessionx-custom-paths '/home'
          set -g @sessionx-x-path '~/.config/konfig'
          set -g @sessionx-window-height '85%'
          set -g @sessionx-window-width '75%'
          set -g @sessionx-zoxide-mode 'on'
          set -g @sessionx-custom-paths-subdirectories 'false'
          set -g @sessionx-filter-current 'false'
        '';
      }

      {
        plugin = tmux-floax;
        extraConfig = ''
          set -g @floax-width '80%'
          set -g @floax-height '80%'
          set -g @floax-border-color 'magenta'
          set -g @floax-text-color 'blue'
          set -g @floax-bind 'P'
          set -g @floax-change-path 'true'
        '';
      }

      {
        plugin = pkgs.tmuxPlugins.mkTmuxPlugin {
          pluginName = "oasis";
          version = "unstable-2024-01-01";
          src = pkgs.fetchFromGitHub {
            owner = "uhs-robert";
            repo = "tmux-oasis";
            rev = "4caf1674660ee8b9e7373cf183562679b70406c7";
            # Run: nix-prefetch-url --unpack https://github.com/uhs-robert/tmux-oasis/archive/4caf1674660ee8b9e7373cf183562679b70406c7.tar.gz
            sha256 = "sha256-Yz5zD3msNpzd6LMvjpL2J6zeTU2Kr4MYxOfQB2EuYSU=";
          };
          postInstall = ''
          chmod +x $target/*.tmux
          chmod +x $target/scripts/*.sh 2>/dev/null || true
          '';
          postPatch = ''
            cp ${./oasis_lagoon.conf} themes/oasis_lagoon.conf
          '';
        };
        extraConfig = ''
          set -g @oasis_flavor "lagoon"
        '';
      }
    ];

    # --- Extra configuration (settings without native HM options) ---
    extraConfig = ''
      # Terminal overrides for true color
      set-option -ga terminal-overrides ',xterm-256color:Tc'

      # Update environment variables for Wayland clipboard
      set-option -g update-environment "WAYLAND_DISPLAY"

      # Additional core settings
      set -g detach-on-destroy off
      set -g renumber-windows on
      set -g set-clipboard on
      set -g status-position top
      set -g status 2
      set -g "status-format[1]" ""
      set -g set-titles on
      set -g allow-passthrough on
      set -g pane-border-lines single
      set -g pane-border-status off

      setw -g automatic-rename on
      setw -g pane-base-index 1

      # Unbind defaults
      unbind C-b
      unbind C-n
      unbind C-i

      # Reload config
      unbind r
      bind r source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"

      # Split windows
      bind v split-window -v
      bind h split-window -h

      # Pane navigation (Colemak: n-e-u-i)
      bind -r n select-pane -L
      bind -r e select-pane -D
      bind -r u select-pane -U
      bind -r i select-pane -R

      # Pane resize
      bind -r C-n resize-pane -L 10
      bind -r C-e resize-pane -D 10
      bind -r C-u resize-pane -U 10
      bind -r Tab resize-pane -R 10

      # Swap panes
      bind > swap-pane -D
      bind < swap-pane -U

      # Copy mode (vi + Colemak)
      bind-key -T copy-mode-vi n send-keys -X cursor-left
      bind-key -T copy-mode-vi e send-keys -X cursor-down
      bind-key -T copy-mode-vi u send-keys -X cursor-up
      bind-key -T copy-mode-vi i send-keys -X cursor-right
      bind-key -T copy-mode-vi N send-keys -X previous-word
      bind-key -T copy-mode-vi I send-keys -X next-word-end
      bind-key -T copy-mode-vi E send-keys -X page-down
      bind-key -T copy-mode-vi U send-keys -X page-up

      # Paste buffers
      bind b list-buffers
      bind p paste-buffer
      bind P choose-buffer

      # Theme override (must be after plugin initialization)
      # Oasis theme uses pure black (#000000) which makes selection invisible
      set -g mode-style 'fg=#101825,bg=#6EB5FF,bold'
    '';
  };
}
