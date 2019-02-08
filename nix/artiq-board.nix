# run with:
# nix-build --option sandbox false artiq-board.nix
#   also add nix.trustedUsers = ["root" "joachim"];
#
# sandbox disabling is needed by:
# 1) Vivado (installed in /opt, bypassing nix) - will likely keep needing it
# 2) cargo - can be improved after carnix becomes less buggy, or by looking into buildRustPackage

let 
  pkgs = import <nixpkgs> {};
  fetchcargo = import <nixpkgs/pkgs/build-support/rust/fetchcargo.nix> {
    inherit (pkgs) stdenv cacert git rust cargo-vendor;
  };
  myVendoredSrcFetchCargo = fetchcargo rec {
    name = "myVendoredSrcFetchCargo";
    sourceRoot = null;
    srcs = null;
    src = ../artiq/firmware;
    cargoUpdateHook = "";
    patches = [];
    sha256 = "1jsb5f5m8p00ikw231sl0i6jg2ilpc2wv1yzi47dgpb54z3gjx3g";
  };

  myVendoredSrc = pkgs.stdenv.mkDerivation {
    name = "myVendoredSrc";
    src = myVendoredSrcFetchCargo;
    phases = [ "unpackPhase" "installPhase" ];
    installPhase = ''
      mkdir -p $out/.cargo/registry
      cat > $out/.cargo/config <<-EOF
        [source.crates-io]
        registry = 'https://github.com/rust-lang/crates.io-index'
        replace-with = 'vendored-sources'

        [source.vendored-sources]
        directory = '$out/.cargo/registry'
      EOF
      cat $out/.cargo/config

      cp -R * $out/.cargo/registry
    '';
  };

  # qknight: code below made the artiq targets (firmware) build!
  #          however, it is hardcoded and needs to be implemented by fetchcargo instead
  #myVendoredSrc = pkgs.stdenv.mkDerivation {
  #  name = "myVendoredSrc";
  #  src = /home/joachim/cargo;
  #  phases = [ "unpackPhase" "installPhase" ];
  #  installPhase = ''
  #    mkdir -p $out/.cargo
  #    cp -R registry $out/.cargo
  #  '';
  #};

  buildenv = import ./artiq-dev.nix {
    extraProfile = ''
      export HOME=${myVendoredSrc}
    '';
    # --no-compile-gateware to disable vivado build
    runScript = "python -m artiq.gateware.targets.kasli -V satellite --no-compile-gateware";
  };
#in myVendoredSrc2
in pkgs.stdenv.mkDerivation {
  name = "artiq-board";
  src = null;
  #buildInputs = [ strace ];
  phases = [ "buildPhase" "installPhase" ];
  buildPhase = buildenv + "/bin/artiq-dev";
    #cp artiq_kasli/satellite/gateware/top.bit $out
  installPhase = ''
    mkdir $out
    cp artiq_kasli/satellite/software/bootloader/bootloader.bin $out
    cp artiq_kasli/satellite/software/satman/satman.{elf,fbi} $out
  '';
}
