{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "engram";
  version = "1.14.13";

  src = fetchFromGitHub {
    owner = "Gentleman-Programming";
    repo = "engram";
    rev = "v${version}";
    hash = "sha256-HRrPBQXKV2eu9roRDVV956SFvxhqaAX7kU4r9n8ts2c=";
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
