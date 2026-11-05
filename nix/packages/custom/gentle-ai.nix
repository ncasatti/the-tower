{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "gentle-ai";
  version = "4.3.1";

  src = fetchFromGitHub {
    owner = "Gentleman-Programming";
    repo = "gentle-ai";
    rev = "v${version}";
    hash = "sha256-/CjKb/FFdE5Lm8fxqQ/csDgsdfySc5EpMeoYWj5oDDg=";
  };

  proxyVendor = true;
  vendorHash = "sha256-A7iVL8Xu6tj6hpU7Xo9D9xhIOKze4H1K5LdQekJ+/oc=";

  subPackages = [ "cmd/gentle-ai" ];
  env.CGO_ENABLED = 0;
  # Release minisign keys are left unset on purpose: `gentle-ai upgrade`
  # must not self-update a Nix store binary; bump this file instead.
  ldflags = [ "-s" "-w" "-X main.version=${version}" ];

  doCheck = false;

  meta = with lib; {
    description = "Configures AI coding agents: ODD workflow, skills, MCP, personas, bounded review";
    homepage = "https://github.com/Gentleman-Programming/gentle-ai";
    license = licenses.mit;
    mainProgram = "gentle-ai";
  };
}
