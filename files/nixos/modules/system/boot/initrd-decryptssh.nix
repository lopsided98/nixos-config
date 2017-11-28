{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.boot.initrd.network.decryptssh;
  
  openCommand = { name, device, header, keyFile, keyFileSize, allowDiscards, ... }: ''
    echo luksOpen ${device} ${name} ${optionalString allowDiscards "--allow-discards"} \
      ${optionalString (header != null) "--header=${header}"} \
      ${optionalString (keyFile != null) "--key-file=${keyFile} ${optionalString (keyFileSize != null) "--keyfile-size=${toString keyFileSize}"}"} \
      > /.luksopen_args
    cryptsetup-askpass
    rm /.luksopen_args
  '';

in {
  options = {
    boot.initrd.network.decryptssh.enable = mkEnableOption "LUKS decryption over SSH using TinySSH";
  };

  config = mkIf cfg.enable {
    boot.initrd = {
      network.tinyssh = {
        enable = true;
        shell = "/bin/decrypt-ssh";
      };
      extraUtilsCommands = ''
        cat << EOF > "$out/bin/decrypt-ssh"
        #!$out/bin/sh
        export LD_LIBRARY_PATH="$out/lib"
        ${concatMapStrings openCommand (attrValues config.boot.initrd.luks.devices)}
        EOF
        chmod +x "$out/bin/decrypt-ssh"
      '';
    };
  };
}
