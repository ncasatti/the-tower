# ====================
# FZF Integration
# ====================
# Fuzzy finder for command history, file search, etc.

if status is-interactive
    and command -q fzf
    fzf --fish | source
end
