{ lib, stdenvNoCC, fetchFromGitHub, makeWrapper
, bash, coreutils, gnused, gnugrep, findutils, git, curl, python3 }:

stdenvNoCC.mkDerivation rec {
  pname = "gga";
  version = "2.10.1";

  src = fetchFromGitHub {
    owner = "Gentleman-Programming";
    repo = "gentleman-guardian-angel";
    rev = "v${version}";
    hash = "sha256-hZSgjEI9Nkni6wCG6ou8GyB7BfQtAP4ZJZvS7qEiJq8=";
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ bash ];

  dontBuild = true;

  # bin/gga resolves its libraries from <prefix>/lib (resolve_lib_dir).
  installPhase = ''
    runHook preInstall
    install -Dm755 bin/gga $out/bin/gga
    install -Dm644 -t $out/lib lib/providers.sh lib/cache.sh lib/pr_mode.sh
    patchShebangs $out/bin
    wrapProgram $out/bin/gga \
      --set-default GGA_VERSION ${version} \
      --prefix PATH : ${lib.makeBinPath [ coreutils gnused gnugrep findutils git curl python3 ]}
    runHook postInstall
  '';

  meta = with lib; {
    description = "Gentleman Guardian Angel: provider-agnostic AI code review git hook";
    homepage = "https://github.com/Gentleman-Programming/gentleman-guardian-angel";
    license = licenses.mit;
    mainProgram = "gga";
  };
}
