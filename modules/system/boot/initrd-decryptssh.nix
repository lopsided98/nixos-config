{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.boot.initrd.network.decryptssh;

in {
  options = {
    boot.initrd.network.decryptssh.enable = mkEnableOption "LUKS decryption over SSH using TinySSH";
  };

  config = mkIf cfg.enable {
    boot.initrd = {
      network.tinyssh = {
        enable = true;
        shell = "/bin/cryptsetup-askpass";
      };
    };
  };
}
