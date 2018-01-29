{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

import <nixpkgs/pkgs/os-specific/linux/kernel/generic.nix> (args // rec {
  version = "4.15-rc3";
  modDirVersion = "4.15.0-rc3";
  extraMeta.branch = "4.15";

  src = fetchFromGitHub {
    owner = "ayufan-rock64";
    repo = "linux-mainline-kernel";
    rev = "a69162ebcb4d142b11bafbeed822b135d77664cf";
    sha256 = "06pnphxw8lgi3jpad3czqz3fm4pc2liwin1w4v2gqqn985hhv1nb";
  };

} // (args.argsOverride or {}))
