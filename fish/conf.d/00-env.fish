# ~/.config/fish/conf.d/00-env.fish
# Session env vars. Sourced BEFORE 01-path.fish (alphabetical order).
set -gx EDITOR      nvim
set -gx BROWSER     zen
set -gx BUN_INSTALL $HOME/.bun
set -gx VAULT_PATH  $HOME/.local/share/the-grid
