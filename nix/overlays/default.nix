{ inputs, ... }:

{
  additions = final: prev: {
    zen-browser = inputs.zen-browser.packages.${prev.stdenv.hostPlatform.system}.default;
    opencode = inputs.opencode-nix.packages.${prev.stdenv.hostPlatform.system}.default;
    clingy = inputs.clingy.packages.${prev.stdenv.hostPlatform.system}.default;
    pylon = inputs.pylon.packages.${prev.stdenv.hostPlatform.system}.default;
    claude-code = inputs.claude-code.packages.${prev.stdenv.hostPlatform.system}.default;
    herdr = inputs.herdr.packages.${prev.stdenv.hostPlatform.system}.default;

    # hyprshade 5.0.0 has two hyprctl bugs that only surface on Hyprland 0.56:
    #
    # 1. READ path (hyprctl.py:68) hardcodes `decoration.screen_shader` (dot),
    #    but hyprctl's `getoption` expects section:key (colon). Every state
    #    read returned "no such option", so `hyprshade ls`/`toggle` died
    #    with a bogus "invalid JSON / go bug Vaxry" message.
    #
    # 2. WRITE path (set_screen_shader) uses `hyprctl eval hl.config(...)`,
    #    which only exists under the LUA config manager. On a hyprlang
    #    config `hyprctl eval` prints "eval is only supported with the lua
    #    config manager" and exits 0 — so hyprshade reported success while
    #    the shader was never applied (`set: false`). We switch the write to
    #    `hyprctl keyword decoration:screen_shader <path>`, the hyprlang path
    #    that works on both config managers.
    #
    # Both bugs are still present in upstream main
    # (src/hyprshade/shader/hyprctl.py:75 and :92). Drop this override once a
    # release ships the fixes, or once we migrate to a hyprland.lua config —
    # at which point the write path can go back to `eval`.
    hyprshade = prev.hyprshade.overridePythonAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        python3 - <<'HYPRSHADE_PATCH_EOF'
        import pathlib

        p = pathlib.Path("src/hyprshade/shader/hyprctl.py")
        lines = p.read_text().split("\n")

        out, n_eval, n_cfg = [], 0, 0
        for ln in lines:
            if ln.strip() == '"eval",':
                out.append(ln.replace('"eval"', '"keyword"'))
                n_eval += 1
            elif "hl.config({{ decoration = {{ screen_shader" in ln:
                indent = ln[: len(ln) - len(ln.lstrip())]
                out.append(indent + '"decoration:screen_shader",')
                out.append(indent + "shader_path,")
                n_cfg += 1
            else:
                out.append(ln)

        # Fail the build if upstream ever reshapes these call sites, rather
        # than silently shipping an unpatched hyprshade.
        assert n_eval == 1, f"expected 1 hyprctl eval line, found {n_eval}"
        assert n_cfg == 1, f"expected 1 hl.config line, found {n_cfg}"

        txt = "\n".join(out).replace(
            '"decoration.screen_shader"', '"decoration:screen_shader"'
        )
        p.write_text(txt)
        print("hyprshade: hyprctl read+write paths patched")
        HYPRSHADE_PATCH_EOF
      '';
    });
    # `minimal` (not `.default` = full): the from-source build stays small.
    # Dependency groups (anthropic, voice, ...) are added per-phase in
    # nix/modules/hermes.nix via .override. The HM module is not a package and
    # cannot be aliased here — it is imported there directly from the input.
    hermes-agent = inputs.hermes-agent.packages.${prev.stdenv.hostPlatform.system}.minimal.overrideAttrs (old: {
      # Patch discord/opus.py to load libopus from the Nix store at import time.
      #
      # Why this works while LD_LIBRARY_PATH does not:
      #   - ctypes.util.find_library('opus') DOES resolve libopus.so.0 when
      #     LD_LIBRARY_PATH is set.
      #   - discord.opus._load_default() runs that lookup exactly ONCE at
      #     first import, caches the result in the module-level _lib global.
      #   - If find_library returns None on that first call (e.g. when the
      #     Hermes env was constructed before libopus was in the store), the
      #     cache is poisoned for the whole process.
      #   - Replacing find_library('opus') with the absolute store path makes
      #     the lookup succeed unconditionally — no cache poisoning possible.
      postFixup = (old.postFixup or "") + ''
        OPUS_FILE="$out/lib/python3.12/site-packages/discord/opus.py"
        if [ ! -f "$OPUS_FILE" ]; then
          OPUS_FILE=$(find "$out" -path '*/site-packages/discord/opus.py' | head -1)
        fi
        if [ -f "$OPUS_FILE" ]; then
          chmod +w "$OPUS_FILE"
          substituteInPlace "$OPUS_FILE" --replace-fail \
            "ctypes.util.find_library('opus')" \
            "'${prev.libopus}/lib/libopus.so.0'"
        else
          echo "WARNING: discord/opus.py not found in $out; voice will not work" >&2
        fi
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
