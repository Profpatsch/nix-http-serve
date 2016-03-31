{ stdenv, haskellPackages, pandoc, gzip }:
rec {
  name = "nix-http-serve";
  deps = haskellPackages.ghcWithPackages (h: with h;
    [ MissingH extra wai wai-app-static warp unix ]);

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

  "${name}" =
    stdenv.mkDerivation rec {
      src = ./.;
      inherit buildInputs buildPhase installPhase name;
    };
}
