# nix-build -I nixpkgs=./nixpkgs --option sandbox false -A firmware
let
  artiq-dev = import ./artiq-dev.nix {};
  artiqpkgs = import ./default.nix { inherit pkgs; };
  pkgs = import <nixpkgs> {};
  buildenv = import ./artiq-dev.nix {
    #extraProfile = ''
    #  export HOME=`pwd`
    #'';
    runScript = "python -m artiq.gateware.targets.kasli -V satellite --no-compile-gateware";
  };
  myVendoredSrc = pkgs.stdenv.mkDerivation {
    name = "myVendoredSrc";
    src = /home/joachim/cargo;
    phases = [ "unpackPhase" "installPhase" ];
    #buildInputs = with artiqpkgs; [ cargo rustc ];
    #fetchPhase = ''
    #  echo "hi"
    #  cd $src
    #  mkdir $src/foo
    #  ls $src
    #  export HOME=$src
    #  echo "pre-populate the cargo cache, see https://users.rust-lang.org/t/pre-caching-cargo-index-and-crates/18561"
    #  cargo search whatever
    #'';
    installPhase = ''
      mkdir -p $out/.cargo
      cp -R registry $out/.cargo
    '';
  };
in
{ stdenv, fetchFromGitHub, fetchurl, runCommand, rustPlatform }:
  
rustPlatform.buildRustPackage rec {
  name = "firmware";
  #fetchPhase = ''
  #  export HOME=`pwd`
  #'';
  #buildPhase = ''
  #  echo "tut23"
  #  exit 1
  #'';

  src =
    let
      source = ../artiq/firmware;
    in
      #du -a ${myVendoredSrc}
    runCommand "cargo-firmware-src" {} ''
      export HOME=${myVendoredSrc}
      cp -R ${source} $out
      chmod +w $out
      ${buildenv + "/bin/artiq-dev"}
    '';

  cargoSha256 = "1jsb5f5m8p00ikw231sl0i6jg2ilpc2wv1yzi47dgpb54z3gjx3g";

  meta = with stdenv.lib; {
    description = "asdf";
    license = with licenses; [ mit asl20 ];# probably wrong...
  };
}
