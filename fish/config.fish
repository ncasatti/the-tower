# ====================
# Fish Shell Configuration
# ====================
# Main configuration file - modular configs auto-load from conf.d/
# Functions auto-load from functions/

# opencode
fish_add_path /home/flyn/.opencode/bin

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

    # Tab → fzf completion. Re-asserted via an on-variable handler because
    # autopair (fishPlugins.autopair) rebinds \t to _autopair_tab through its
    # own `--on-variable fish_key_bindings` hook, which fires AFTER config.fish
    # and would otherwise clobber this. Ours registers later, so it wins.
    function _bind_tab_fzf --on-variable fish_key_bindings
        bind \t fzf_complete
        bind -M insert \t fzf_complete
    end
    _bind_tab_fzf

    # Right arrow: at end of line accept ONE word of the autosuggestion;
    # elsewhere move a single character (preserves in-line cursor navigation).
    function _accept_word_or_char
        if test (commandline -C) -ge (string length -- (commandline))
            commandline -f forward-word
        else
            commandline -f forward-char
        end
    end
    bind \e\[C _accept_word_or_char
    bind \eOC _accept_word_or_char
end
