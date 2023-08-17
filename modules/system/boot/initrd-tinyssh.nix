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
        default = "/bin/sh";
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

  config = mkIf (config.boot.initrd.systemd.network.enable && cfg.enable) {
    assertions = [
      {
        assertion = config.boot.initrd.systemd.enable;
        message = "TinySSH is only supported with systemd in initrd";
      }
      {
        assertion = cfg.authorizedKeys != [];
        message = "You should specify at least one authorized key for initrd SSH";
      }
    ];

    boot.initrd = {
      secrets."/etc/tinyssh/sshkeydir/.ed25519.sk" = cfg.hostEd25519Key.privateKey;

      systemd = let
        shadow-minimal = pkgs.shadow.override {
          pam = null;
          withTcb = false;
        };
      in {
        contents = {
          # root home is hardcoded as /var/empty. Generally a bad idea to put
          # things in /var/empty, but in the initrd it's probably fine.
          "/var/empty/.ssh/authorized_keys".text = concatStringsSep "\n" cfg.authorizedKeys;
          "/etc/tinyssh/sshkeydir/ed25519.pk".source = cfg.hostEd25519Key.publicKey;
        };
        storePaths = [ "${shadow-minimal}/bin/chsh" "${pkgs.tinyssh}/bin/tinysshd" ];

        sockets.tinysshd = {
          description = "TinySSH Socket";
          wantedBy = [ "sockets.target" ];
          before = [ "sockets.target" ];

          unitConfig.DefaultDependencies = false;
          socketConfig = {
            ListenStream = cfg.port;
            Accept = true;
            KeepAlive = true;
            IPTOS = "low-delay";
          };
        };

        services."tinysshd@" = {
          description = "TinySSH Per-Connection Daemon";
          after = [ "initrd-nixos-copy-secrets.service" ];

          unitConfig.DefaultDependencies = false;
          serviceConfig = {
            # systemd initrd doesn't allow declaratively setting the shell, so
            # we have to do this dance
            ExecStartPre = [
              # chsh refuses to work on a symlink, even if the target is writable
              "/bin/mv /etc/passwd /etc/passwd.orig"
              "/bin/cp -L /etc/passwd.orig /etc/passwd"
              "/bin/chmod u+rw /etc/passwd"
              "${shadow-minimal}/bin/chsh --shell ${cfg.shell}"
            ];
            ExecStart = "${pkgs.tinyssh}/bin/tinysshd -v -- /etc/tinyssh/sshkeydir";
            StandardInput = "socket";
            StandardError = "journal";
          };
        };
      };
    };
  };

}
