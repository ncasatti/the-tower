{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "engram";
  version = "1.17.0";

  src = fetchFromGitHub {
    owner = "Gentleman-Programming";
    repo = "engram";
    rev = "v${version}";
    hash = "sha256-qC/8QWmbr6of/s8YiLEYRMWBGVO+IAlvmNVVWOFaY6k=";
  };

  vendorHash = "sha256-O+pC4x4DKNUWr7Sx9iZOjK6a64wrQA4/lnjvkNLBX64=";

  doCheck = false;

  meta = with lib; {
    description = "Persistent memory system for AI coding agents (MCP)";
    homepage = "https://github.com/Gentleman-Programming/engram";
    license = licenses.mit;
    mainProgram = "engram";
  };
}
