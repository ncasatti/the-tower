# ====================
# Node Version Manager
# ====================
# Manage multiple Node.js versions

if status is-interactive
    # Option 1: Use fnm (Fast Node Manager - Rust-based, fish-native)
    # Recommended: Install fnm and uncomment below
    if command -q fnm
        fnm env --use-on-cd | source
    end

    # Option 2: Use fisher nvm.fish plugin
    # Install with: fisher install jorgebucaran/nvm.fish

    # Option 3: Use traditional nvm with bass wrapper
    # Install bass with: fisher install edc/bass
    # Then uncomment below:
    # if test -d $NVM_DIR
    #     function nvm
    #         bass source $NVM_DIR/nvm.sh --no-use ';' nvm $argv
    #     end
    # end

    # Option 4: Load nvm if available (traditional method)
    if test -s "$NVM_DIR/nvm.sh"
        # Note: This may be slow. Consider using fnm or fisher plugin instead
        # bass source "$NVM_DIR/nvm.sh" --no-use
    end
end
