# ====================
# Audio — JACK via PipeWire
# ====================

# Launched bare, Ardour's JACK backend does not reach PipeWire's JACK
# emulation and fails with "Could not reconnect to Audio/MIDI engine".
# `pw-jack` (from pipewire.jack, installed in nix/packages/audio.nix) prepends
# PipeWire's libjack to LD_LIBRARY_PATH and execs the app, so the client talks
# to the running PipeWire daemon instead of looking for a jackd.
#
# nixpkgs' ardour ships only the versioned binary (ardour9), no `ardour`.

function ardour --description 'Launch Ardour through the PipeWire JACK emulation'
    if not command -q pw-jack
        echo "ardour: pw-jack not in PATH (pipewire.jack missing from home.packages?)" >&2
        return 1
    end
    command pw-jack ardour9 $argv
end
