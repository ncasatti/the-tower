# Android Development Setup in Neovim

This guide will help you set up and verify Android development in Neovim with JDTLS and Kotlin LSP.

## Quick Start

### 1. Open Your Android Project

```bash
cd ~/Documents/Dev/Xionico/gev/ArcorGev5AndroidAppAS-develop/sources/workspace/ArcorGev5AndroidStudio
nvim .
```

**Important**: Open Neovim from the **root of the Gradle project** (where `settings.gradle` is located).

### 2. Verify LSP Installation

Open a Java or Kotlin file in your project and run:

```vim
:LspInfo
```

You should see:
- `jdtls` attached to Java files
- `kotlin_language_server` attached to Kotlin files

### 3. Test LSP Features

Try these keybindings:
- `gd` - Go to definition
- `K` - Show documentation
- `<leader>ca` - Code actions
- `<leader>rn` - Rename symbol
- `[d` / `]d` - Previous/next diagnostic

## Configuration Changes Made

### Fixed Issues

1. **API Mismatch**: Changed from `root_dir` (lspconfig API) to `root_markers` (native vim.lsp.config API)
2. **Root Detection**: Added Android-specific markers (`settings.gradle`, `settings.gradle.kts`)
3. **File Type Detection**: Added explicit `filetypes = { 'java' }` for JDTLS

### Configuration Location

`~/.config/konfig/nvim/lua/plugins/lsp/lsp.lua`

## Common Issues & Solutions

### Issue 1: LSP Not Attaching

**Symptom**: `:LspInfo` shows no clients attached

**Solution**:
1. Make sure you opened nvim from the Gradle project root
2. Check the file has correct extension (`.java` or `.kt`)
3. Restart nvim: `:qa` then reopen

### Issue 2: JDTLS Workspace Errors

**Symptom**: Errors about workspace or configuration

**Solution**:
1. Clean workspace: `rm -rf ~/.local/share/nvim/jdtls-workspace/*`
2. Restart Neovim
3. Let JDTLS rebuild the workspace (takes 1-2 minutes)

### Issue 3: Java Version Compatibility

**Symptom**: JDTLS fails to start with module errors

**Current Java**: OpenJDK 25 (you have this)
**JDTLS Requirement**: Java 17+

Your Java version is compatible!

### Issue 4: Kotlin LSP Slow to Start

**Symptom**: Kotlin files have no LSP for 30+ seconds

**Solution**: This is normal on first start. Kotlin LSP needs to index the project.

## Debugging LSP Issues

### Check LSP Logs

```vim
:lua vim.cmd('e '..vim.lsp.get_log_path())
```

### Check Mason Installation

```vim
:Mason
```

Verify both are installed:
- ✓ jdtls
- ✓ kotlin-language-server

### Manual LSP Start (for debugging)

If LSP doesn't auto-start, try:

```vim
:lua vim.lsp.start({name='jdtls'})
```

## Android-Specific Tips

### 1. Working with Gradle

Use the nvim-gradle plugin (already configured):

```vim
:GradleExec tasks              " List available tasks
:GradleExec assembleDebug      " Build debug APK
:GradleExec installDebug       " Install on device
```

### 2. Navigating Android Project Structure

Your project structure:
```
ArcorGev5AndroidStudio/          ← Open nvim here!
├── settings.gradle              ← Root marker
├── build.gradle
├── ArcorGev5AndroidApp/         ← Main module
│   ├── src/
│   │   └── main/
│   │       ├── java/            ← Java sources
│   │       └── kotlin/          ← Kotlin sources
│   └── build.gradle
└── app-debug/                   ← Debug module
```

### 3. Java + Kotlin Coexistence

JDTLS handles Java files, Kotlin LSP handles Kotlin files. Both work simultaneously.

### 4. Android SDK Path

If you see Android SDK errors, set in `~/.bashrc` or `~/.zshrc`:

```bash
export ANDROID_HOME=~/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools
```

## Performance Tips

### 1. First Launch is Slow

- JDTLS indexes the entire project (1-3 minutes for large projects)
- Kotlin LSP also indexes (30-60 seconds)
- Be patient on first open!

### 2. Workspace Size

Your workspace: `~/.local/share/nvim/jdtls-workspace/ArcorGev5AndroidStudio`

To clean: `rm -rf ~/.local/share/nvim/jdtls-workspace/ArcorGev5AndroidStudio`

### 3. Memory Usage

JDTLS is configured with `-Xms1g` (1GB initial heap).

If you have memory issues, edit `lua/plugins/lsp/lsp.lua` line 167:
- Reduce to `-Xms512m` for lower memory
- Increase to `-Xms2g` for faster indexing

## Debugging Android Apps

This configuration includes full debugging support via DAP (Debug Adapter Protocol).

### Setup Debug Session

1. **Build and install your app in debug mode**:
   ```vim
   <leader>aDb
   ```
   This builds, installs, and starts your app in debug mode on port 5005.

2. **Set breakpoints**:
   - Press `F9` to toggle breakpoint on current line
   - Or use `<leader>db`

3. **Start debugging**:
   - Press `F5` to attach debugger
   - Select "Debug (Attach) - Android Device"

4. **Debug controls**:
   - `F5` - Continue execution
   - `F6` - Pause execution
   - `F9` - Toggle breakpoint
   - `F10` - Step over
   - `F11` - Step into
   - `F12` - Step out
   - `<leader>dt` - Terminate debug session
   - `<leader>du` - Toggle debug UI

### Manual Debug Workflow (Alternative)

If you want more control:

1. **Start app with debugging enabled**:
   ```bash
   adb shell am start -D -n your.package.name/.MainActivity
   adb forward tcp:5005 jdwp:$(adb shell pidof -s your.package.name)
   ```

2. **Or use the helper**:
   ```vim
   <leader>adb
   ```

3. **Attach debugger**: Press `F5` and select debug configuration

### Debug UI

The debug UI opens automatically when debugging starts and shows:
- **Scopes**: Local variables and their values
- **Breakpoints**: All set breakpoints
- **Stack**: Call stack
- **Watches**: Watch expressions
- **REPL**: Interactive console
- **Console**: Debug output

Use colemak navigation (`u/e/i/n`) in the debug UI windows.

### Troubleshooting Debugging

**Issue**: Debugger won't attach
- Verify app is running: `adb shell pidof -s your.package.name`
- Check port forwarding: `adb forward tcp:5005 jdwp:$(adb shell pidof -s your.package.name)`
- Ensure app was started with `-D` flag for debug mode

**Issue**: Breakpoints not hitting
- Make sure you built with debug variant (`assembleDebug`)
- Check ProGuard/R8 isn't stripping debug info
- Verify source file matches installed APK version

## Android Utilities

This configuration includes comprehensive Android development utilities.

### Logcat Viewer

View Android logs directly in Neovim:

- `<leader>al` - View all logcat output
- `<leader>ae` - View errors only
- `<leader>aw` - View warnings and above
- `<leader>ap` - View logs for current package
- `<leader>af` - Custom filter (e.g., "MyTag:D")
- `<leader>ac` - Clear logcat buffer

Logcat opens in a floating terminal. Press `q` or `Esc` to close.

### ADB Helpers

Device and app management:

- `<leader>ad` - List connected devices
- `<leader>ai` - Install APK (prompts for path)
- `<leader>au` - Uninstall current app
- `<leader>aD` - Clear app data
- `<leader>as` - Start current app
- `<leader>aS` - Stop current app
- `<leader>ar` - Restart current app
- `<leader>adb` - Enable debug mode (for debugging)

### Build Helpers

Quick build and deploy workflows:

- `<leader>ab` - Build debug APK
- `<leader>aB` - Build release APK
- `<leader>aI` - Build and install debug
- `<leader>aR` - Build, install, and run debug
- `<leader>aDb` - Build, install, and enable debugging
- `<leader>aq` - Quick rebuild (clean + build)
- `<leader>ax` - Install existing debug APK
- `<leader>aX` - Run existing app (without rebuild)

### Gradle Integration

Execute Gradle tasks:

- `<leader>gb` - Gradle build
- `<leader>gc` - Gradle clean
- `<leader>gr` - Install & run debug (installDebug)
- `<leader>gt` - Gradle test
- `<leader>gd` - Assemble debug
- `<leader>gR` - Assemble release
- `<leader>gi` - Install debug
- `<leader>gI` - Install release
- `<leader>gu` - Uninstall debug
- `<leader>gU` - Uninstall release
- `<leader>gs` - Show all Gradle tasks
- `<leader>gx` - Execute custom Gradle task

### Quick Development Workflow

**Typical workflow for development**:

1. Make code changes
2. Press `<leader>aR` - Build, install, and run
3. View logs with `<leader>al` or `<leader>ap`
4. If something breaks, `<leader>ac` to clear logs and try again

**Debugging workflow**:

1. Make code changes
2. Set breakpoints with `F9`
3. Press `<leader>aDb` - Build, install, and start in debug mode
4. Press `F5` - Attach debugger
5. Step through code with `F10/F11/F12`

## Keybindings Quick Reference

Remember: This config uses **Colemak navigation** (see CLAUDE.md)!

### LSP Actions (work in both Java and Kotlin)
- `gd` - Go to definition
- `gD` - Go to declaration
- `gI` - Go to implementation
- `gr` - Go to references (Snacks picker)
- `K` - Hover documentation
- `Ctrl-k` - Signature help

### Code Actions
- `<leader>ca` - Code actions menu
- `<leader>rn` - Rename symbol
- `<leader>ll` / `:Format` - Format buffer

### Diagnostics
- `[d` - Previous diagnostic
- `]d` - Next diagnostic
- `<leader>le` - Show diagnostic float
- `<leader>lq` - Set location list

### Document/Workspace
- `<leader>ds` - Document symbols
- `<leader>ws` - Workspace symbols
- `<leader>wa` - Add workspace folder
- `<leader>wr` - Remove workspace folder

### Debug Controls (F-keys)
- `F5` - Continue/Start debugging
- `F6` - Pause execution
- `F9` - Toggle breakpoint
- `F10` - Step over
- `F11` - Step into
- `F12` - Step out

### Debug Controls (Leader prefix)
- `<leader>db` - Toggle breakpoint
- `<leader>dB` - Set conditional breakpoint
- `<leader>dc` - Continue
- `<leader>dC` - Run to cursor
- `<leader>di` - Step into
- `<leader>do` - Step over
- `<leader>dO` - Step out
- `<leader>dr` - Toggle REPL
- `<leader>dt` - Terminate debug session
- `<leader>du` - Toggle debug UI
- `<leader>de` - Evaluate expression
- `<leader>dh` - Hover variables
- `<leader>dp` - Preview

### Android Utilities
- `<leader>al` - Logcat (all)
- `<leader>ae` - Logcat (errors)
- `<leader>aw` - Logcat (warnings)
- `<leader>ap` - Logcat (package)
- `<leader>af` - Logcat (custom filter)
- `<leader>ac` - Clear logcat
- `<leader>ad` - List devices
- `<leader>ai` - Install APK
- `<leader>au` - Uninstall app
- `<leader>aD` - Clear app data
- `<leader>as` - Start app
- `<leader>aS` - Stop app
- `<leader>ar` - Restart app
- `<leader>adb` - Enable debug mode
- `<leader>ab` - Build debug
- `<leader>aB` - Build release
- `<leader>aI` - Build & install
- `<leader>aR` - Build, install & run
- `<leader>aDb` - Build, install & debug
- `<leader>aq` - Quick rebuild
- `<leader>ax` - Install existing APK
- `<leader>aX` - Run existing app

### Gradle Tasks
- `<leader>gb` - Build
- `<leader>gc` - Clean
- `<leader>gr` - Install & run debug
- `<leader>gt` - Test
- `<leader>gd` - Assemble debug
- `<leader>gR` - Assemble release
- `<leader>gi` - Install debug
- `<leader>gI` - Install release
- `<leader>gu` - Uninstall debug
- `<leader>gU` - Uninstall release
- `<leader>gs` - Show tasks
- `<leader>gx` - Execute custom task

## Testing Your Setup

### Test 1: Java File

1. Open: `nvim ArcorGev5AndroidApp/src/main/java/com/emser/arcorgevandroid/bl/clientes/Cliente.java`
2. Run: `:LspInfo`
3. Expected: See `jdtls` client attached
4. Put cursor on a method name
5. Press `gd` - should jump to definition

### Test 2: Kotlin File

1. Find a `.kt` file in your project
2. Open with nvim
3. Run: `:LspInfo`
4. Expected: See `kotlin_language_server` client attached
5. Press `K` on a symbol - should show documentation

### Test 3: Gradle Integration

1. From project root: `:GradleExec tasks`
2. Expected: See list of available Gradle tasks

## Next Steps

1. **Learn the keybindings** - Print the quick reference above
2. **Be patient on first launch** - Indexing takes time
3. **Check `:LspInfo` regularly** - Verify LSP is attached
4. **Read TASKNOTES.md** - If you want task management in nvim
5. **Explore Snacks.picker** - Modern fuzzy finder (better than Telescope)

## Getting Help

If something doesn't work:

1. Check `:LspInfo` - Is the LSP attached?
2. Check `:checkhealth` - Are there any errors?
3. Check LSP logs: `:lua vim.cmd('e '..vim.lsp.get_log_path())`
4. Check this file for common issues above

---

**Last Updated**: November 20, 2025
**Your Neovim Config**: `~/.config/konfig/nvim/`
**Android Project**: `~/Documents/Dev/Xionico/gev/ArcorGev5AndroidAppAS-develop/`

## New Features (November 2025)

✨ **Full debugging support** with DAP (Debug Adapter Protocol)
✨ **Logcat viewer** with filtering capabilities
✨ **ADB helpers** for device and app management
✨ **Build helpers** for quick build/install/run workflows
✨ **Enhanced Gradle integration** with comprehensive keybindings

This configuration now provides a complete Android development environment!
