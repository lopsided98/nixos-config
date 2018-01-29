{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

import <nixpkgs/pkgs/os-specific/linux/kernel/generic.nix> (args // rec {
  version = "4.14.11-97";
  modDirVersion = "4.14.11";
  extraMeta.branch = "4.14";

  src = fetchFromGitHub {
    owner = "hardkernel";
    repo = "linux";
    rev = version;
    sha256 = "0jj8l8ma3yhhi6xb7a8l9kmmrw22fbcl70ycx83kh2n8vijdif0x";
  };

} // (args.argsOverride or {}))
