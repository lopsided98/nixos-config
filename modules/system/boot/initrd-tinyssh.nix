{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.boot.initrd.network.tinyssh;

in {

  options = {

    boot.initrd.network.tinyssh.enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Start TinySSH service during initrd boot. It can be used to debug 
        failing boot on a remote server, enter pasphrase for an encrypted 
        partition etc. Service is killed when stage-1 boot is finished.
      '';
    };

    boot.initrd.network.tinyssh.port = mkOption {
      type = types.int;
      default = 22;
      description = ''
        Port on which TinySSH initrd service should listen.
      '';
    };

    boot.initrd.network.tinyssh.shell = mkOption {
      type = types.str;
      default = "/bin/ash";
      description = ''
        Login shell of the remote user. Can be used to limit actions user can do.
      '';
    };

    boot.initrd.network.tinyssh.hostEd25519Key = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Ed25519 SSH private key file in the OpenSSH format.
        WARNING: Unless your bootloader supports initrd secrets, this key is
        contained insecurely in the global Nix store. Do NOT use your regular
        SSH host private keys for this purpose or you'll expose them to
        regular users!
      '';
    };

    boot.initrd.network.tinyssh.authorizedKeys = mkOption {
      type = types.listOf types.str;
      default = config.users.extraUsers.root.openssh.authorizedKeys.keys;
      description = ''
        Authorized keys for the root user on initrd.
      '';
    };

  };

  config = mkIf (config.boot.initrd.network.enable && cfg.enable) {
    assertions = [
      { assertion = cfg.hostEd25519Key != null;
        message = "You need to specify a host key for initrd SSH";
      }
      { assertion = cfg.authorizedKeys != [];
        message = "You should specify at least one authorized key for initrd SSH";
      }
    ];

    boot.initrd.extraUtilsCommands = ''
      copy_bin_and_libs ${pkgs.tinyssh}/bin/tinysshd
      copy_bin_and_libs ${pkgs.ucspi-tcp}/bin/tcpserver
      copy_bin_and_libs ${pkgs.tinyssh-convert}/bin/tinyssh-convert
      
      cp -pv ${pkgs.glibc.out}/lib/libnss_files.so.* $out/lib
    '';

    boot.initrd.extraUtilsCommandsTest = ''
      $out/bin/tinysshd || [ $? -eq 100 ]
      $out/bin/tcpserver || [ $? -eq 100 ]
    '';

    boot.initrd.network.postCommands = ''
      echo '${cfg.shell}' > /etc/shells
      echo 'root:x:0:0:root:/root:${cfg.shell}' > /etc/passwd
      echo 'passwd: files' > /etc/nsswitch.conf

      mkdir -p /etc/tinyssh/sshkeydir
      mkdir -p /root/.ssh
      
      tinyssh-convert -f /etc/tinyssh/ssh_host_ed25519_key -d /etc/tinyssh/sshkeydir
      
      ${concatStrings (map (key: ''
        echo ${escapeShellArg key} >> /root/.ssh/authorized_keys
      '') cfg.authorizedKeys)}

      tcpserver -HRDl0 0.0.0.0 ${toString cfg.port} tinysshd -v /etc/tinyssh/sshkeydir &
    '';

    boot.initrd.secrets =
     (optionalAttrs (cfg.hostEd25519Key != null) { "/etc/tinyssh/ssh_host_ed25519_key" = cfg.hostEd25519Key; });

  };

}
