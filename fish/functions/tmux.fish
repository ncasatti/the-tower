# ====================
# Tmux wrapper function
# ====================
# Wraps tmux to provide automatic session naming based on current directory
# Usage:
#   tmux              - Create/attach to session named after current directory
#   tmux [args]       - Pass through to regular tmux command

function tmux
    # If arguments are provided, pass through to regular tmux
    if test (count $argv) -gt 0
        command tmux $argv
        return
    end

    # Check if we're already in tmux
    if set -q TMUX
        echo "Already in tmux session"
        return 1
    end

    # Generate session name based on current directory
    set session_name (basename (pwd) | tr . _)

    # Fallback to 'default' if session name is empty or just '/'
    if test -z "$session_name"; or test "$session_name" = "_"
        set session_name "default"
    end

    # Try to attach to existing session, or create new one
    if command tmux has-session -t "$session_name" 2>/dev/null
        echo "Attaching to existing session: $session_name"
        command tmux attach-session -t "$session_name"
    else
        echo "Creating new session: $session_name"
        command tmux new-session -s "$session_name"
    end
end
