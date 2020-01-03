{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.boot.initrd.network.decryptssh;
in {
  options = {
    boot.initrd.network.decryptssh.enable = mkEnableOption "LUKS decryption over SSH using TinySSH";
  };

  config = mkIf cfg.enable {
    boot.initrd.network.tinyssh = {
      enable = true;
      shell = "/bin/cryptsetup-askpass";
    };

    # Bring down all network interfaces after mounting so that systemd can
    # assign them predictable names.
    boot.initrd.postMountCommands = ''
      awk 'BEGIN { FS=":"; RS=" "; ORS="\0" } $1 ~ /^ip=/ { print $6 }' /proc/cmdline | \
        xargs -r0 -I{} ip link set dev {} down
    '';
  };
}
