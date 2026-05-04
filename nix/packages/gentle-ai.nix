{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "gentle-ai";
  version = "1.25.4";

  src = fetchFromGitHub {
    owner = "Gentleman-Programming";
    repo = "gentle-ai";
    rev = "v${version}";
    sha256 = "0adiz013ll3wxsq2la99f2ji6a8663nzy1qhya6sa9daxwsqn5gl";
  };

  vendorHash = "sha256-g886XpkhuCJlh+K8SPJWDbKl+Y/w0pk38fkpBb9kNC8=";

  doCheck = false;

  meta = with lib; {
    description = "AI Gentle Stack";
    homepage = "https://github.com/Gentleman-Programming/gentle-ai";
    license = licenses.mit;
    mainProgram = "gentle-ai";
  };
}