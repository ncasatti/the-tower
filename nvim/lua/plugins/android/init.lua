-- Android development utilities
-- This init.lua loads all Android helper modules

-- Load utility modules
require("plugins.android.gradle")
require("plugins.android.android-adb")
require("plugins.android.android-build")
require("plugins.android.android-logcat")

-- Return empty table to satisfy Lazy.nvim
-- (these are utility modules, not plugin specs)
return {}
