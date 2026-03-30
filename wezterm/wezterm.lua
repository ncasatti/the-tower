-- WezTerm Configuration - The Grid Edition
-- Replicating Retro6.json aesthetic from cool-retro-term

local wezterm = require 'wezterm'
local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- 1. FONT (IBM 3270 / Retro Vibes)
config.font = wezterm.font('3270 Nerd Font Mono', { weight = 'Regular' })
config.font_size = 14.0

-- 2. COLORS (Based on Retro6.json)
-- backgroundColor: #000000
-- fontColor: #4a8fba
config.colors = {
  foreground = '#4a8fba',
  background = '#000000',
  cursor_bg = '#4a8fba',
  cursor_fg = '#000000',
  selection_bg = '#4a8fba',
  selection_fg = '#000000',
  
  -- ANSI palette (Ayu-like but with CRT glow feel)
  ansi = {
    '#000000', '#F07178', '#AAD94C', '#E6B450',
    '#39BAE6', '#D2A6FF', '#95E6CB', '#BFBDB6',
  },
  brights = {
    '#575c61', '#F07178', '#AAD94C', '#E6B450',
    '#39BAE6', '#D2A6FF', '#95E6CB', '#FFFFFF',
  },
}

-- 3. RETRO EFFECTS (The Grid Soul)
-- windowOpacity: 0.7506
config.window_background_opacity = 0.75
config.text_background_opacity = 1.0

-- Bloom and Glow simulation
-- WezTerm doesn't have a direct "bloom" slider, but we can use 
-- front_end = "WebGpu" and custom shaders for advanced effects.
-- For now, we use high-quality text rendering.
config.front_end = "WebGpu"

-- 4. WINDOW DECORATIONS
config.window_padding = {
  left = 15,
  right = 15,
  top = 15,
  bottom = 15,
}
config.window_decorations = "RESIZE"
config.enable_tab_bar = false

-- 5. CURSOR
config.default_cursor_style = 'BlinkingBlock'
config.cursor_blink_rate = 500

-- 6. SHELL
config.default_prog = { '/usr/bin/env', 'fish' }

-- 7. IMAGE SUPPORT (Kitty Protocol)
-- Enabled by default in WezTerm

return config
