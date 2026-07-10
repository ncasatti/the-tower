# ============================================================
# Terminal multiplexers & session managers — tmux + herdr
# ============================================================
# Shell shortcuts for the two persistent-session tools. Both keep
# sessions alive in the background; you attach/detach at will.
#   tmux  — classic terminal multiplexer
#   herdr — agent-aware terminal workspace manager (tmux-like)
# The herdr verbs mirror tmux's: t/ta/tl <-> h/ha/hl.
# (`abbr t tmux` lives in 19-aliases-utils.fish.)

# --- tmux ---
abbr -a ta 'tmux attach-session'
abbr -a tl 'tmux list-sessions'

# --- herdr (mirrors the tmux verbs) ---
abbr -a h   'herdr'                  # launch/attach the default session
abbr -a ha  'herdr session attach'   # attach a named session
abbr -a hl  'herdr session list'     # list sessions
abbr -a hr  'herdr --remote'         # remote session
abbr -a hn  'herdr --session'        # new / enter a named session
abbr -a hs  'herdr session stop'     # stop a session
abbr -a hst 'herdr status'           # server/client status
