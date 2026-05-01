# ====================
# Fish Shell Configuration
# ====================
# Main configuration file - modular configs auto-load from conf.d/
# Functions auto-load from functions/

# opencode
fish_add_path /home/ncasatti/.opencode/bin

if status is-interactive
    # Direnv integration (if available)
    command -q direnv && direnv hook fish | source

    # Load custom color scheme (if available)
    # Disabled for pure black background
    # test -f ~/.local/state/caelestia/sequences.txt && cat ~/.local/state/caelestia/sequences.txt 2>/dev/null

    # Custom greeting (empty for clean prompt)
    function fish_greeting
        # Empty - no greeting message
    end

    # Foot terminal: Mark prompt start for jumping between prompts
    function mark_prompt_start --on-event fish_prompt
        echo -en "\e]133;A\e\\"
    end

    # Force pager on first tab
    bind \t fzf_complete
end
