{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "engram";
  version = "0.1.9";

  src = fetchFromGitHub {
    owner = "Gentleman-Programming";
    repo = "engram";
    rev = "v${version}";
    hash = "sha256-klH6OlgMd5X1Y83db2dcoxYqW6LgxCsvWw3pGZWhh7Y=";
  };

  vendorHash = "sha256-hR1PS0oQcUMbsRcfd6rk2uqlXGT8wcll0H8qU09aYg0=";

  doCheck = false;

  meta = with lib; {
    description = "Persistent memory system for AI coding agents (MCP)";
    homepage = "https://github.com/Gentleman-Programming/engram";
    license = licenses.mit;
    mainProgram = "engram";
  };
}
