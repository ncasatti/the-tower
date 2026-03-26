# ====================
# Environment Variables
# ====================
# Core environment setup - loaded first to ensure all other configs have access

# Editor and browser
set -gx EDITOR nvim
set -gx BROWSER zen-browser

# Development tools
set -gx DOTNET_ROOT $HOME/.dotnet
set -gx BUN_INSTALL $HOME/.bun
set -gx JAVA_HOME /home/ncasatti/.jdks/jbr-17.0.12

# Configuration paths
set -gx BAT_CONFIG_PATH ~/.config/bat/config.conf

# Terminal settings
set -gx TERM xterm-256color

# NVM directory
set -gx NVM_DIR $HOME/.nvm
