# nix/packages/ai.nix
# AI tooling: coding agents, MCP servers, and supporting CLIs.
# Import only on hosts that do AI-assisted development (main, notebook).
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    claude-code
    opencode
    clingy
    engram # persistent memory MCP
    codebase-memory-mcp # code intelligence MCP (knowledge graph + UI)
    antigravity-cli
    # ollama    # local embedding server CLI (gbrain backend)
    # litellm   # proxy for MiniMax-M3 / M2.7-highspeed
  ];
}
