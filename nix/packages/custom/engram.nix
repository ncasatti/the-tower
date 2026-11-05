{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "engram";
  version = "3.6.2";

  src = fetchFromGitHub {
    owner = "Gentleman-Programming";
    repo = "engram";
    rev = "v${version}";
    hash = "sha256-JANo2rwSFBdbtovLRob4GmESEJ/uS3pUVMZAfwV4+60=";
  };

  # proxyVendor: the go.mod patch below breaks vendor/modules.txt consistency.
  proxyVendor = true;
  vendorHash = "sha256-uNoFAUJfu3SFU9OqT1AJvHKKN6t6oPo6nC6GEbYhYJs=";

  # go.mod pins the patch release (go 1.26.10); nixpkgs ships the same minor.
  postPatch = ''
    sed -i -E 's/^go 1\.26\.[0-9]+$/go 1.26/' go.mod
  '';

  subPackages = [ "cmd/engram" ];
  env.CGO_ENABLED = 0;
  ldflags = [ "-s" "-w" "-X main.version=${version}" ];

  doCheck = false;

  meta = with lib; {
    description = "Persistent memory system for AI coding agents (MCP)";
    homepage = "https://github.com/Gentleman-Programming/engram";
    license = licenses.mit;
    mainProgram = "engram";
  };
}
