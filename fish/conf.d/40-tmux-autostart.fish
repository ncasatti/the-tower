# ====================
# Tmux Auto-start Configuration
# ====================
# Migrated from zsh tmux plugin configuration:
# - AUTOSTART_ONCE: Start tmux only once per session
# - AUTOCONNECT: Automatically connect to existing sessions
# - AUTOQUIT: Exit shell when tmux exits
# - AUTONAME_SESSION: Use automatic session naming

# Configuration variables (set to customize behavior)
set -g FISH_TMUX_AUTOSTART_ONCE false  # Disabled: Start tmux manually
set -g FISH_TMUX_AUTOCONNECT true
set -g FISH_TMUX_AUTOQUIT true
set -g FISH_TMUX_AUTONAME_SESSION true
abbr -a ta 'tmux attach-session'
abbr -a tl 'tmux list-sessions'

if status is-interactive
    and not set -q TMUX
    and command -q tmux

    # Skip autostart if disabled
    if test "$FISH_TMUX_AUTOSTART_ONCE" != true
        exit 0
    end

    # Check if we already autostarted (only once per terminal)
    if set -q TMUX_AUTOSTARTED
        # Already autostarted in this shell tree, skip
        exit 0
    end

    # Mark that we've autostarted
    set -gx TMUX_AUTOSTARTED 1

    # Determine session name
    if test "$FISH_TMUX_AUTONAME_SESSION" = true
        # Auto-generate session name based on directory or use 'default'
        set session_name (basename (pwd) | tr . _)
        if test -z "$session_name"
            set session_name default
        end
    else
        set session_name default
    end

    # Auto-connect logic
    if test "$FISH_TMUX_AUTOCONNECT" = true
        # Try to attach to existing session, or create new one
        if tmux has-session -t "$session_name" 2>/dev/null
            tmux attach-session -t "$session_name"
        else
            tmux new-session -s "$session_name"
        end
    else
        # Always create new session
        tmux new-session -s "$session_name"
    end

    # Auto-quit logic
    if test "$FISH_TMUX_AUTOQUIT" = true
        # Exit the shell after tmux exits
        exit 0
    end
end
