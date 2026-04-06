{ lib, stdenv, fetchurl, nodejs, makeWrapper }:

stdenv.mkDerivation rec {
  pname = "gemini-cli";
  version = "0.36.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/@google/gemini-cli/-/gemini-cli-${version}.tgz";
    sha256 = "1vb27wdggqgdvvggpc076dz19fra0mhaig3wzj5kmyxdjh2i1mba";
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ nodejs ];

  sourceRoot = "package";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/node_modules/@google/gemini-cli
    cp -r . $out/lib/node_modules/@google/gemini-cli

    mkdir -p $out/bin
    makeWrapper ${nodejs}/bin/node $out/bin/gemini \
      --add-flags "$out/lib/node_modules/@google/gemini-cli/bundle/gemini.js"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Google Gemini CLI";
    homepage = "https://www.npmjs.com/package/@google/gemini-cli";
    license = licenses.asl20;
    maintainers = [ ];
  };
}