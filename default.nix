{ stdenv, haskellPackages, pandoc, gzip }:

let
  deps = haskellPackages.ghcWithPackages (h: with h;
    [ MissingH extra wai wai-app-static warp ]);

in
stdenv.mkDerivation rec {
  name = "nix-http-serve";
  version = "0.1.0.0";
  src = ./.;

  buildInputs = [ deps pandoc gzip ];
  buildPhase = ''
    ghc -O2 ${name}.hs
    mkdir -p man/man1
    pandoc -s -t man README.md | gzip > man/man1/${name}.1.gz
  '';

  installPhase = ''
    mkdir -p $out/bin
    mv nix-http-serve $out/bin
    mv man $out/man
  '';

  meta = {
    description = "Serves the result of a nix build as static http files";
    license = stdenv.lib.licenses.gpl3;
  };

}
