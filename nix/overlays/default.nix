{ inputs, ... }:

{
  additions = final: prev: {
    zen-browser = inputs.zen-browser.packages.${prev.stdenv.hostPlatform.system}.default;
    opencode = inputs.opencode-nix.packages.${prev.stdenv.hostPlatform.system}.default;
    clingy = inputs.clingy.packages.${prev.stdenv.hostPlatform.system}.default;
    claude-code = inputs.claude-code.packages.${prev.stdenv.hostPlatform.system}.default;
    herdr = inputs.herdr.packages.${prev.stdenv.hostPlatform.system}.default;
    engram = prev.callPackage ../packages/custom/engram.nix { };
    codebase-memory-mcp = prev.callPackage ../packages/custom/codebase-memory-mcp.nix { };
    pdf2md = prev.callPackage ../packages/custom/pdf2md.nix { };
    antigravity-cli = inputs.antigravity.packages.${prev.stdenv.hostPlatform.system}.antigravity-cli;
  };
}
