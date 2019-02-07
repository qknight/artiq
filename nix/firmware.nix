# nix-build -I nixpkgs=./nixpkgs --option sandbox false -A firmware
let
  artiq-dev = import ./artiq-dev.nix {};
  pkgs = import <nixpkgs> {};
  buildenv = import ./artiq-dev.nix {
    extraProfile = ''
       export HOME=`pwd`
    '';
    runScript = "python -m artiq.gateware.targets.kasli -V satellite --no-compile-gateware";
  };
in
{ stdenv, fetchFromGitHub, fetchurl, runCommand, rustPlatform }:
  
rustPlatform.buildRustPackage rec {
  name = "firmware";
  buildPhase = ''
    export HOME=`pwd`
  '';

  src =
    let
      source = ../artiq/firmware;
    in
    runCommand "cargo-firmware-src" {} ''
      echo "hi 1"
      cp -R ${source} $out
      echo "hi 2"
      chmod +w $out
      echo "hi 3"
      ${buildenv + "/bin/artiq-dev"}
    '';

  cargoSha256 = "1xzjn9i4rkd9124v2gbdplsgsvp1hlx7czdgc58n316vsnrkbr86";

  meta = with stdenv.lib; {
    description = "asdf";
    license = with licenses; [ mit asl20 ];# probably wrong...
  };
}
