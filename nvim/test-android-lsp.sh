#!/bin/bash
# Android LSP Setup Verification Script

echo "════════════════════════════════════════════════"
echo "  Android LSP Setup Verification"
echo "════════════════════════════════════════════════"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check functions
check_ok() {
    echo -e "${GREEN}✓${NC} $1"
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# 1. Check Java installation
echo "1. Checking Java installation..."
if command -v java &> /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | head -1)
    check_ok "Java found: $JAVA_VERSION"
else
    check_fail "Java not found - JDTLS requires Java 17+"
    exit 1
fi
echo ""

# 2. Check Mason packages
echo "2. Checking Mason LSP servers..."
MASON_DIR="$HOME/.local/share/nvim/mason/packages"

if [ -d "$MASON_DIR/jdtls" ]; then
    check_ok "JDTLS installed"
else
    check_fail "JDTLS not found - run :Mason in nvim and install jdtls"
fi

if [ -d "$MASON_DIR/kotlin-language-server" ]; then
    check_ok "Kotlin Language Server installed"
else
    check_fail "Kotlin LSP not found - run :Mason in nvim and install kotlin-language-server"
fi
echo ""

# 3. Check JDTLS components
echo "3. Checking JDTLS components..."
JDTLS_LAUNCHER=$(find "$MASON_DIR/jdtls/plugins/" -name "org.eclipse.equinox.launcher_*.jar" 2>/dev/null | head -1)

if [ -n "$JDTLS_LAUNCHER" ]; then
    check_ok "JDTLS launcher found: $(basename $JDTLS_LAUNCHER)"
else
    check_fail "JDTLS launcher jar not found"
fi

if [ -d "$MASON_DIR/jdtls/config_linux" ]; then
    check_ok "JDTLS config_linux found"
else
    check_fail "JDTLS config_linux not found"
fi
echo ""

# 4. Check Android project
echo "4. Checking Android project..."
ANDROID_PROJECT="$HOME/Documents/Dev/Xionico/gev/ArcorGev5AndroidAppAS-develop/sources/workspace/ArcorGev5AndroidStudio"

if [ -d "$ANDROID_PROJECT" ]; then
    check_ok "Android project found"

    if [ -f "$ANDROID_PROJECT/settings.gradle" ]; then
        check_ok "settings.gradle found (root marker)"
    else
        check_warn "settings.gradle not found - might affect root detection"
    fi

    if [ -f "$ANDROID_PROJECT/gradlew" ]; then
        check_ok "gradlew found"
    else
        check_warn "gradlew not found"
    fi
else
    check_fail "Android project not found at: $ANDROID_PROJECT"
fi
echo ""

# 5. Check Neovim config
echo "5. Checking Neovim configuration..."
NVIM_CONFIG="$HOME/.config/konfig/nvim"

if [ -f "$NVIM_CONFIG/lua/plugins/lsp/lsp.lua" ]; then
    check_ok "LSP configuration found"

    # Check if using correct API
    if grep -q "root_markers.*settings.gradle" "$NVIM_CONFIG/lua/plugins/lsp/lsp.lua"; then
        check_ok "JDTLS using correct root_markers API"
    else
        check_warn "JDTLS might not have settings.gradle in root_markers"
    fi
else
    check_fail "LSP configuration not found"
fi

if [ -f "$NVIM_CONFIG/android-setup.md" ]; then
    check_ok "Android setup guide found"
else
    check_warn "Android setup guide not found"
fi
echo ""

# 6. Check workspace
echo "6. Checking JDTLS workspace..."
WORKSPACE_DIR="$HOME/.local/share/nvim/jdtls-workspace"

if [ -d "$WORKSPACE_DIR" ]; then
    WORKSPACE_SIZE=$(du -sh "$WORKSPACE_DIR" 2>/dev/null | cut -f1)
    check_ok "JDTLS workspace exists (size: $WORKSPACE_SIZE)"

    if [ -d "$WORKSPACE_DIR/ArcorGev5AndroidStudio" ]; then
        check_ok "ArcorGev5AndroidStudio workspace found"
    else
        check_warn "No workspace for ArcorGev5AndroidStudio yet (will be created on first open)"
    fi
else
    check_warn "JDTLS workspace directory doesn't exist yet (normal on first run)"
fi
echo ""

# Summary
echo "════════════════════════════════════════════════"
echo "  Summary"
echo "════════════════════════════════════════════════"
echo ""
echo "Next steps:"
echo "  1. Start Neovim from project root:"
echo "     cd $ANDROID_PROJECT"
echo "     nvim ."
echo ""
echo "  2. Open a Java file and check LSP:"
echo "     :LspInfo"
echo ""
echo "  3. Test LSP features:"
echo "     - Press 'gd' on a symbol to go to definition"
echo "     - Press 'K' to show documentation"
echo ""
echo "  4. Read the setup guide:"
echo "     cat $NVIM_CONFIG/android-setup.md"
echo ""
echo "════════════════════════════════════════════════"
