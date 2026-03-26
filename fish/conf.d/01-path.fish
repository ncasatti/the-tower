# ====================
# PATH Modifications
# ====================
# Add directories to PATH - fish_add_path automatically deduplicates

# System paths
fish_add_path -g /snap/bin

# Development tools
fish_add_path -gP $HOME/.emacs.d/bin
fish_add_path -g $DOTNET_ROOT
fish_add_path -g $DOTNET_ROOT/tools
fish_add_path -g $BUN_INSTALL/bin

# Mobile development
fish_add_path -g $HOME/.local/share/Uts/.sdk/flutter-sdk3/bin

# AI tools
fish_add_path -g /home/ncasatti/.lmstudio/bin
