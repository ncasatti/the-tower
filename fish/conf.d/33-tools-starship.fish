# ====================
# Starship Prompt
# ====================
# Cross-shell customizable prompt - replaces oh-my-zsh themes

if status is-interactive
    and command -q starship
    starship init fish | source
end
