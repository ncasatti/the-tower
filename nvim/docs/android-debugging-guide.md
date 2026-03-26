# Android Debugging Guide

Complete guide for debugging Android applications in Neovim with DAP (Debug Adapter Protocol).

---

## 🐛 Quick Start: Debug Your Android App

### Prerequisites

1. **Android device connected**:
   ```bash
   adb devices  # Verify device shows as "device" (not "unauthorized")
   ```

2. **Project built at least once**:
   ```vim
   <leader>gb  # Gradle build
   ```

### Basic Debugging Workflow

1. **Open your Java/Kotlin file** in Neovim
2. **Set breakpoints**: Press `F9` on lines where you want to pause
3. **Build, install, and debug**: Press `<leader>aDb`
4. **Attach debugger**: Press `F5` and select "Debug (Attach) - Android Device"
5. **Step through code**: Use `F10/F11/F12` to navigate

---

## 📋 Complete Debugging Workflow

### Method 1: Automated (Recommended)

**Step 1: Connect Device**
```bash
adb devices
```

Output should show:
```
List of devices attached
ABC123XYZ    device
```

**Step 2: Open Source File**
```bash
cd ~/path/to/ArcorGev5AndroidStudio
nvim app/src/main/java/com/yourapp/MainActivity.java
```

**Step 3: Set Breakpoints**
- Navigate to the line where you want to break (e.g., `onCreate()` method)
- Press `F9` to toggle breakpoint
- You'll see a red dot `🔴` in the gutter
- Set multiple breakpoints as needed

**Step 4: Build, Install & Start in Debug Mode**
```vim
<leader>aDb
```

This command will:
1. Execute `./gradlew installDebug`
2. Stop the app if running
3. Start app with debug flag (`-D`)
4. Forward port 5005 for debugging
5. Show message: `Ready to attach debugger. Press F5 to start debugging.`

**Step 5: Attach Debugger**
```vim
F5  # Or <leader>dc
```

Select from the menu:
- **Debug (Attach) - Android Device** (port 5005)
- Debug (Attach) - Custom Port (if using different port)

**Step 6: Debug UI Opens Automatically**

The debug interface shows:
- **Left panel**: Scopes (local variables, fields)
- **Breakpoints**: List of all breakpoints
- **Stack**: Call stack trace
- **Watches**: Custom watch expressions
- **Bottom panel**: REPL console and output

**Step 7: Interact with Your App**

Use your app on the device. When execution hits a breakpoint:
- Neovim highlights the current line
- Variables update in the Scopes panel
- Call stack shows the execution path

**Step 8: Step Through Code**

| Key | Action | Description |
|-----|--------|-------------|
| `F5` | Continue | Run until next breakpoint |
| `F10` | Step Over | Execute current line, don't enter functions |
| `F11` | Step Into | Enter function calls |
| `F12` | Step Out | Exit current function |

**Step 9: Inspect Variables**

Navigate to the Scopes panel:
- Use `u/e` (up/down) to browse variables
- Press `<CR>` to expand objects
- Hover over variables in code: `<leader>dh`

**Step 10: Evaluate Expressions**
```vim
<leader>de  # In normal or visual mode
```

Type expression:
```java
user.getName() + " - " + user.getId()
```

**Step 11: Stop Debugging**
```vim
<leader>dt  # Terminate debug session
```

---

### Method 2: Manual (More Control)

For fine-grained control over each step:

**Step 1: Build APK**
```vim
<leader>gd  # Assemble debug APK
```

**Step 2: Install APK**
```vim
<leader>gi  # Install debug APK
```

**Step 3: Set Breakpoints**
```vim
F9  # On desired lines
```

**Step 4: Start App in Debug Mode**
```vim
<leader>adb  # Enable debug mode
```

Or manually:
```bash
# Stop app if running
adb shell am force-stop com.your.package.name

# Start with debug flag
adb shell am start -D -n com.your.package.name/.MainActivity

# Forward debug port
adb forward tcp:5005 jdwp:$(adb shell pidof -s com.your.package.name)
```

**Step 5: Attach Debugger**
```vim
F5
```

**Step 6: Debug as usual**

---

## 🎯 Example Debugging Session

### Scenario: Debug User Login

**1. Open MainActivity.java**
```bash
nvim app/src/main/java/com/example/myapp/MainActivity.java
```

**2. Set Breakpoint in onCreate()**
```java
@Override
protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_main);  // <-- Press F9 here

    Button loginButton = findViewById(R.id.loginButton);
    loginButton.setOnClickListener(v -> handleLogin());  // <-- And F9 here
}
```

**3. Build and Debug**
```vim
<leader>aDb
```

**4. Wait for Installation**
```
Building and installing debug APK...
[Process output showing Gradle build]
App started in debug mode. Connect debugger to localhost:5005
Ready to attach debugger. Press F5 to start debugging.
```

**5. Attach**
```vim
F5
```

**6. App Opens on Device**

The app launches and immediately pauses at `onCreate()` breakpoint.

**7. Inspect savedInstanceState**

In the Scopes panel, you see:
```
▾ Local variables
  ▸ this = MainActivity@12345
  ▸ savedInstanceState = null
```

**8. Continue to Next Breakpoint**
```vim
F5  # Continue
```

**9. Click Login Button on Device**

Execution pauses at the `handleLogin()` call.

**10. Step Into handleLogin()**
```vim
F11  # Step into
```

Now you're inside the `handleLogin()` method.

**11. Evaluate Username**
```vim
<leader>de
```
Type: `usernameEditText.getText().toString()`

Result shows: `"testuser"`

**12. Set Conditional Breakpoint**

Navigate to login validation line:
```vim
<leader>dB
```
Enter condition: `username.length() < 3`

Now it only breaks when username is too short.

**13. Finish Debugging**
```vim
<leader>dt  # Terminate
```

---

## 🔧 Debug Keybindings Reference

### F-Keys (Primary Debug Controls)

| Key | Mode | Action |
|-----|------|--------|
| `F9` | n | Toggle breakpoint on current line |
| `F5` | n | Continue execution / Start debugging |
| `F6` | n | Pause execution |
| `F10` | n | Step over (next line) |
| `F11` | n | Step into (enter function) |
| `F12` | n | Step out (exit function) |

### Leader Keys (Advanced Controls)

| Key | Mode | Action |
|-----|------|--------|
| `<leader>db` | n | Toggle breakpoint |
| `<leader>dB` | n | Set conditional breakpoint |
| `<leader>dc` | n | Continue execution |
| `<leader>dC` | n | Run to cursor position |
| `<leader>di` | n | Step into |
| `<leader>do` | n | Step over |
| `<leader>dO` | n | Step out |
| `<leader>dr` | n | Toggle REPL console |
| `<leader>dl` | n | Run last debug configuration |
| `<leader>dt` | n | Terminate debug session |
| `<leader>du` | n | Toggle debug UI manually |
| `<leader>de` | n/v | Evaluate expression under cursor/selection |
| `<leader>dh` | n | Hover variables (show values) |
| `<leader>dp` | n | Preview variables |

### Android-Specific Keys

| Key | Mode | Action |
|-----|------|--------|
| `<leader>aDb` | n | Build, install, and start in debug mode |
| `<leader>adb` | n | Enable debug mode (manual) |
| `<leader>aR` | n | Build, install, and run (no debug) |

---

## 🎨 Debug UI Navigation

The debug UI opens automatically when debugging starts.

### Layout

```
┌─────────────────────────────────────────────────────────────┐
│                     Your Code Here                          │
│  Breakpoint →  🔴  protected void onCreate(...) {           │
│                    Current line highlighted ▶               │
│                }                                            │
├──────────────────────┬──────────────────────────────────────┤
│ Scopes               │ Breakpoints                          │
│ ▾ Local variables    │ 🔴 MainActivity.java:42              │
│   ▸ this             │ 🔴 LoginActivity.java:78             │
│   ▸ savedInstance... │                                      │
│                      │                                      │
│ Stacks               │ Watches                              │
│ ▸ onCreate()         │ user.name                            │
│ ▸ main()             │ isLoggedIn                           │
├──────────────────────┴──────────────────────────────────────┤
│ REPL Console                                                │
│ > user.getName()                                            │
│ "John Doe"                                                  │
└─────────────────────────────────────────────────────────────┘
```

### UI Controls (Colemak Navigation)

| Key | Action |
|-----|--------|
| `u/e` | Navigate up/down in panels |
| `i/n` | Navigate right/left between panels |
| `<CR>` | Expand/collapse items |
| `o` | Open item details |
| `d` | Remove item (breakpoint/watch) |
| `l` | Edit item (enter insert mode) |
| `t` | Toggle item |
| `q` or `<Esc>` | Close floating windows |

---

## 🔍 Advanced Debugging Features

### Conditional Breakpoints

Break only when a condition is true:

1. Navigate to desired line
2. Press `<leader>dB`
3. Enter condition:
   ```java
   userId == 42
   username.equals("admin")
   items.size() > 10
   ```

The debugger will only pause when the condition evaluates to `true`.

### Watch Expressions

Monitor variables continuously:

1. Open debug UI: `<leader>du`
2. Navigate to Watches panel
3. Add expression to watch
4. Values update automatically as you step through code

### REPL Console

Interactive Java REPL during debugging:

```vim
<leader>dr  # Toggle REPL
```

Type expressions:
```java
> user.getName()
"John Doe"

> items.stream().filter(i -> i.price > 100).count()
5

> this.findViewById(R.id.button).getText()
"Login"
```

### Logcat Integration

View logs while debugging:

```vim
<leader>ap  # Open logcat for your package
```

Split your screen:
- Left: Stepping through code
- Right: Watching log output

---

## 🚀 Debugging Workflows

### Quick Restart Cycle

After making code changes:

```vim
<leader>dt   # Stop current debug session
<leader>aDb  # Rebuild, reinstall, start debug
F5           # Attach debugger again
```

### Debug Specific Scenario

To debug only a specific user action:

1. Set breakpoint in the handler
2. Start app normally: `<leader>aR`
3. Enable debug mode: `<leader>adb`
4. Attach debugger: `F5`
5. Perform action on device
6. Breakpoint hits

### Debug App Startup

To debug code that runs on app start:

```vim
<leader>aDb  # Starts app with -D flag (waits for debugger)
F5           # App will start when debugger attaches
```

### Remote Debugging (Different Port)

If port 5005 is in use:

```bash
adb forward tcp:8000 jdwp:$(adb shell pidof -s com.your.app)
```

In Neovim:
```vim
F5  # Select "Debug (Attach) - Custom Port"
# Enter: 8000
```

---

## ⚠️ Troubleshooting

### Debugger Won't Attach

**Check app is running in debug mode:**
```bash
adb shell pidof -s com.your.package.name
```

Should return a process ID. If not, app isn't running.

**Check port forwarding:**
```bash
adb forward --list
```

Should show:
```
ABC123XYZ tcp:5005 jdwp:12345
```

**Manually reconnect:**
```bash
adb forward tcp:5005 jdwp:$(adb shell pidof -s com.your.package.name)
```

### Breakpoints Not Hitting

**Ensure debug build:**
```vim
<leader>gd  # Assemble debug (not release)
```

**Check app was started with -D flag:**
```vim
<leader>adb  # Use this instead of <leader>as
```

**Verify source file matches APK:**
- Rebuild and reinstall if you made changes
- Check you're debugging the right variant (debug, not release)

**ProGuard/R8 stripping debug info:**

Edit `app/build.gradle`:
```gradle
buildTypes {
    debug {
        minifyEnabled false
        debuggable true
    }
}
```

### App Crashes When Debugger Attached

**Increase timeout in app:**

Some apps have watchdog timers that kill the app if startup is too slow.

**Start app first, then attach:**
```vim
<leader>as   # Start app normally
<leader>adb  # Enable debug after it's running
F5           # Attach
```

### No Device Connected

**Check USB debugging enabled:**
- On device: Settings → Developer Options → USB Debugging

**Check ADB recognizes device:**
```bash
adb devices
```

If shows "unauthorized":
- Check device screen for authorization prompt
- Accept the connection

**Restart ADB:**
```bash
adb kill-server
adb start-server
adb devices
```

### JDTLS Errors

**Check LSP is running:**
```vim
:LspInfo
```

Should show `jdtls` attached to Java files.

**Restart LSP:**
```vim
:LspRestart
```

**Clear workspace and restart:**
```bash
rm -rf ~/.local/share/nvim/jdtls-workspace/*
```

Then restart Neovim.

---

## 💡 Pro Tips

### 1. Debug Multiple Devices

Forward different ports for each device:
```bash
adb -s DEVICE1 forward tcp:5005 jdwp:...
adb -s DEVICE2 forward tcp:5006 jdwp:...
```

### 2. Save Debug Configurations

Create custom launch configs in JDTLS settings for:
- Different ports
- Different devices
- Different entry points

### 3. Use Log Breakpoints

Set breakpoint and add logpoint instead:
```vim
<leader>dB
# Enter: log("User ID: " + userId)
```

Logs message without pausing execution.

### 4. Thread Debugging

View all threads in the Threads panel:
- Main thread
- Background workers
- AsyncTask threads

Switch between threads to see their state.

### 5. Exception Breakpoints

Break when exception is thrown:
```vim
# In DAP config, add:
exceptionBreakpoints = { "uncaught", "caught" }
```

### 6. Keyboard-Only Debugging

No mouse needed:
1. `F9` to set breakpoints while reading code
2. `<leader>aDb` to start
3. `F5` to attach
4. `F10/F11/F12` to navigate
5. `<leader>de` to inspect
6. `<leader>dt` to stop

All from keyboard! 🎹

---

## 📚 Related Documentation

- [android-setup.md](android-setup.md) - Complete Android development setup
- [KEYBINDINGS.md](KEYBINDINGS.md) - All Neovim keybindings
- [CLAUDE.md](../CLAUDE.md) - Project overview

---

## 🎓 Learning Path

### Beginner
1. Set simple breakpoints with `F9`
2. Use `<leader>aDb` to start debugging
3. Step through with `F10` (step over)
4. Inspect variables in Scopes panel
5. Stop with `<leader>dt`

### Intermediate
1. Use `F11` (step into) to enter methods
2. Evaluate expressions with `<leader>de`
3. Set conditional breakpoints
4. Use REPL console
5. Watch expressions

### Advanced
1. Debug multithreaded code
2. Remote debugging
3. Exception breakpoints
4. Log breakpoints
5. Custom DAP configurations

---

**Last Updated**: November 20, 2025
**Neovim Config**: `~/.config/konfig/nvim/`
**Android Project**: `~/Documents/Dev/Xionico/gev/ArcorGev5AndroidAppAS-develop/`

---

Happy Debugging! 🐛🔍🚀
