# Android

All Android tooling under `<leader>x*`. Gradle under `<leader>xg*`.

## ADB (device & app)

- `<leader>xd` — List devices
- `<leader>xi` — Install APK
- `<leader>xu` — Uninstall app
- `<leader>xD` — Clear app data
- `<leader>xs` — Start app
- `<leader>xS` — Stop app
- `<leader>xr` — Restart app
- `<leader>xdb` — Enable debug mode (port 5005)

## Build (APK)

- `<leader>xb` — Build debug
- `<leader>xB` — Build release
- `<leader>xI` — Build & install debug
- `<leader>xR` — Build, install & run
- `<leader>xDb` — Build, install & debug
- `<leader>xq` — Quick rebuild (clean + build)
- `<leader>xx` — Install existing APK
- `<leader>xX` — Run existing app

## Logcat

- `<leader>xl` — All logs
- `<leader>xe` — Error logs (`*:E`)
- `<leader>xw` — Warning logs (`*:W`)
- `<leader>xc` — Clear logcat
- `<leader>xp` — Current package logs
- `<leader>xf` — Custom filter

## Gradle

- `<leader>xgb` — Build
- `<leader>xgc` — Clean
- `<leader>xgr` — Install & run debug
- `<leader>xgt` — Test
- `<leader>xgd` — Assemble debug
- `<leader>xgR` — Assemble release
- `<leader>xgi` / `<leader>xgI` — Install debug / release
- `<leader>xgu` / `<leader>xgU` — Uninstall debug / release
- `<leader>xgs` — Show all tasks
- `<leader>xgx` — Execute custom task

## Commands

- `:GradleExec <task>` — Run any Gradle task
- `:GradleTasks` — Show all tasks
- `:GradleFixPermissions` — `chmod +x gradlew`
- `:GradleWhich` — Print Gradle root + executable
