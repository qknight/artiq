# run with:
# nix-build --option sandbox false artiq-board.nix
#   also add nix.trustedUsers = ["root" "joachim"];
#
# sandbox disabling is needed by:
# 1) Vivado (installed in /opt, bypassing nix) - will likely keep needing it
# 2) cargo - can be improved after carnix becomes less buggy, or by looking into buildRustPackage

let 
  pkgs = import <nixpkgs> {};
  buildenv = import ./artiq-dev.nix {
    extraProfile = ''
       export HOME=`pwd`
    '';
    # --no-compile-gateware to disable vivado build
    runScript = "python -m artiq.gateware.targets.kasli -V satellite --no-compile-gateware";
  };
in pkgs.stdenv.mkDerivation {
  name = "artiq-board";
  src = null;
  buildInputs = [ strace ];
  phases = [ "buildPhase" "installPhase" ];
  buildPhase = buildenv + "/bin/artiq-dev";
  installPhase = ''
    mkdir $out
    cp artiq_kasli/satellite/gateware/top.bit $out
    cp artiq_kasli/satellite/software/bootloader/bootloader.bin $out
    cp artiq_kasli/satellite/software/satman/satman.{elf,fbi} $out
  '';
}
