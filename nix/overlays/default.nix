{ inputs, ... }:

{
  additions = final: prev: {
    zen-browser = inputs.zen-browser.packages.${prev.stdenv.hostPlatform.system}.default;
    opencode = inputs.opencode-nix.packages.${prev.stdenv.hostPlatform.system}.default;
    clingy = inputs.clingy.packages.${prev.stdenv.hostPlatform.system}.default;
    claude-code = inputs.claude-code.packages.${prev.stdenv.hostPlatform.system}.default;
    herdr = inputs.herdr.packages.${prev.stdenv.hostPlatform.system}.default;
    # `minimal` (not `.default` = full): the from-source build stays small.
    # Dependency groups (anthropic, voice, ...) are added per-phase in
    # nix/modules/hermes.nix via .override. The HM module is not a package and
    # cannot be aliased here — it is imported there directly from the input.
    hermes-agent = inputs.hermes-agent.packages.${prev.stdenv.hostPlatform.system}.minimal.overrideAttrs (old: {
      # Add libopus to the wrapper's LD_LIBRARY_PATH so discord.py's
      # ctypes.util.find_library('opus') can resolve it.
      # Without this, Discord voice bubbles fail with "Opus codec not found".
      postFixup = (old.postFixup or "") + ''
        wrapProgram $out/bin/hermes \
          --prefix LD_LIBRARY_PATH : "${prev.libopus}/lib"
      '';
    });
    engram = prev.callPackage ../packages/custom/engram.nix { };
    codebase-memory-mcp = prev.callPackage ../packages/custom/codebase-memory-mcp.nix { };
    pdf2md = prev.callPackage ../packages/custom/pdf2md.nix { };
    antigravity-cli = inputs.antigravity.packages.${prev.stdenv.hostPlatform.system}.antigravity-cli;

    # VST3/VST2 RPATH fix for decent-sampler.
    #
    # pkgs.decent-sampler is NOT the binary derivation -- it is a buildFHSEnv
    # (bwrap) wrapper. The real binary lives in an inner derivation; the
    # wrapper just `cp -r`s its lib/ and share/ into $out. The standalone app
    # therefore works (it runs inside the FHS sandbox, where expat exists),
    # but the plugin does not: an external host (Ardour, Reaper, Carla) calls
    # dlopen() on the bare .so outside the sandbox, and the shipped binary
    # carries no RPATH -> "libexpat.so.1: cannot open shared object file".
    #
    # GOTCHA: do NOT use postFixup here. buildFHSEnv builds via
    # runCommandLocal, so the derivation sets `buildCommand`, and stdenv's
    # genericBuild runs buildCommand *instead of* the standard phases --
    # fixupPhase (and hence postFixup) never executes. Appending to
    # buildCommand is the only hook that actually runs.
    #
    # `ldd` reports exactly two unresolved deps (libexpat.so.1, libasound.so.2),
    # so the rpath stays minimal rather than pulling the full FHS closure.
    decent-sampler = prev.decent-sampler.overrideAttrs (old: {
      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ prev.patchelf ];
      buildCommand = (old.buildCommand or "") + ''
        # Files arrive from `cp -r` of a read-only store path.
        chmod -R u+w $out/lib

        for so in \
          "$out/lib/vst3/DecentSampler.vst3/Contents/x86_64-linux/DecentSampler.so" \
          "$out/lib/vst/DecentSampler.so"; do
          if [ -f "$so" ]; then
            patchelf --set-rpath "${prev.expat}/lib:${prev.alsa-lib}/lib" "$so"
          fi
        done
      '';
    });
  };
}
