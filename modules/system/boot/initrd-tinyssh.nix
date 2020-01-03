{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.boot.initrd.network.tinyssh;

in {

  options = {

    boot.initrd.network.tinyssh = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Start TinySSH service during initrd boot. It can be used to debug
          failing boot on a remote server, enter the passphrase for an encrypted
          partition, etc. Service is killed when stage-1 boot is finished.
        '';
      };

      port = mkOption {
        type = types.int;
        default = 22;
        description = ''
          Port on which TinySSH initrd service should listen.
        '';
      };

      shell = mkOption {
        type = types.str;
        default = "/bin/ash";
        description = ''
          Login shell of the remote user. Can be used to limit actions user can do.
        '';
      };

      hostEd25519Key = mkOption {
        type = types.submodule ({ options = {
          publicKey = mkOption {
            type = types.path;
            description = ''
              Ed25519 SSH public host key file in the TinySSH format.
            '';
          };
          privateKey = mkOption {
            type = types.path;
            description = ''
            Ed25519 SSH private host key file in the TinySSH format.
            WARNING: Unless your bootloader supports initrd secrets, this key is
            contained insecurely in the global Nix store. Do NOT use your regular
            SSH host private keys for this purpose or you'll expose them to
            regular users!
          '';
          };
        }; });
        description = "Ed25519 SSH host key configuration.";
      };

      authorizedKeys = mkOption {
        type = types.listOf types.str;
        default = config.users.extraUsers.root.openssh.authorizedKeys.keys;
        description = ''
          Authorized keys for the root user on initrd.
        '';
      };
    };
  };

  config = mkIf (config.boot.initrd.network.enable && cfg.enable) {
    assertions = [
      { assertion = cfg.authorizedKeys != [];
        message = "You should specify at least one authorized key for initrd SSH";
      }
    ];

    boot.initrd = {
      extraUtilsCommands = ''
        copy_bin_and_libs ${pkgs.tinyssh}/bin/tinysshd
        copy_bin_and_libs ${pkgs.ucspi-tcp}/bin/tcpserver

        cp -pv ${pkgs.glibc.out}/lib/libnss_files.so.* $out/lib
      '';

      extraUtilsCommandsTest = ''
        $out/bin/tinysshd || [ $? -eq 100 ]
        $out/bin/tcpserver || [ $? -eq 100 ]
      '';

      network.postCommands = ''
        echo '${cfg.shell}' > /etc/shells
        echo 'root:x:0:0:root:/root:${cfg.shell}' > /etc/passwd
        echo 'passwd: files' > /etc/nsswitch.conf

        mkdir -p /root/.ssh

        ${concatStrings (map (key: ''
          echo ${escapeShellArg key} >> /root/.ssh/authorized_keys
        '') cfg.authorizedKeys)}

        tcpserver -HRDl0 0.0.0.0 ${toString cfg.port} tinysshd -v /etc/tinyssh/sshkeydir &
      '';

      secrets = {
        # Not a secret, but there seems to be no other way to include it.
        "/etc/tinyssh/sshkeydir/ed25519.pk" = cfg.hostEd25519Key.publicKey;
        "/etc/tinyssh/sshkeydir/.ed25519.sk" = cfg.hostEd25519Key.privateKey;
      };
    };
  };

}
