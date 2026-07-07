{ lib, stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "codebase-memory-mcp";
  version = "0.8.1";

  # "ui" variant (embedded 3D graph UI) + "portable" (statically linked)
  src = fetchurl {
    url = "https://github.com/DeusData/codebase-memory-mcp/releases/download/v${version}/codebase-memory-mcp-ui-linux-amd64-portable.tar.gz";
    hash = "sha256-dO1j468thb/ZjLzOcZEpVTbQpUsITLwLho1p8ichcto=";
  };

  sourceRoot = ".";

  dontBuild = true;
  dontFixup = true; # static binary, nothing to patch

  installPhase = ''
    runHook preInstall

    install -Dm755 codebase-memory-mcp $out/bin/codebase-memory-mcp

    runHook postInstall
  '';

  meta = with lib; {
    description = "Code intelligence MCP server: tree-sitter knowledge graph of codebases";
    homepage = "https://github.com/DeusData/codebase-memory-mcp";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "codebase-memory-mcp";
  };
}
