{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.environment.secrets;
in {

  options = {
  
    environment = {
      secrets-key = mkOption {
        default = "/etc/secrets/key";
        type = types.str;
        description = "Key used to decrypt secret files";
      };
      
      secrets = mkOption {
        default = {};
        
        type = types.attrsOf (types.submodule ({ name, config, ... }: {
          options = {
            enable = mkOption {
              type = types.bool;
              default = true;
              description = ''
                Whether this secret should be decrypted.
              '';
            };

            target = mkOption {
              type = types.str;
              description = ''
                Name of secret file (relative to
                <filename>/etc/secrets</filename>).  Defaults to the attribute
                name.
              '';
            };

            source = mkOption {
              type = types.path;
              description = "Path of the source file.";
            };
            
            mode = mkOption {
              type = types.str;
              default = "0400";
              example = "0600";
              description = ''
                The mode of the copied secret file.
              '';
            };

            uid = mkOption {
              default = 0;
              type = types.int;
              description = ''
                UID of decrypted secret file.
              '';
            };

            gid = mkOption {
              default = 0;
              type = types.int;
              description = ''
                GID of decrypted secret file.
              '';
            };

            user = mkOption {
              default = "+${toString config.uid}";
              type = types.str;
              description = ''
                User name of decrypted secret file.
              '';
            };

            group = mkOption {
              default = "+${toString config.gid}";
              type = types.str;
              description = ''
                Group name of decrypted secret file.
              '';
            };
          };
          config = {
            target = mkDefault name;
          };
        }));
      };
    };
  };

  config = mkIf (cfg != {}) {
    
    assertions = mapAttrsToList (n: v: {
      assertion = (builtins.match "0[0-7]{3}" v.mode) != null;
      message = "Invalid secret file mode (must be 3 digit octal number)";
    }) cfg;
    
    environment.etc = mapAttrs (n: v: {
      inherit (v) enable source mode user group;
      target = "secrets/${v.target}";
    }) cfg;
  
    system.activationScripts.secrets = stringAfter [ "etc" ] ''
      secrets=(
        ${concatMapStringsSep "\n" (s: "\"${s.value.target}\"") (mapAttrsToList nameValuePair cfg)}
      )
      echo "decrypting secrets..."
      
      for secret in "''${secrets[@]}"; do
        # Add temporary decrypted secret to list of files to be cleaned up
        echo "secrets/$secret.dec" >> /etc/.clean
        
        # Set umask so gpg does not create a world readable file
        orig_umask=$(umask)
        umask 0377
        ${pkgs.gnupg}/bin/gpg --decrypt --batch --passphrase-file "${config.environment.secrets-key}" -o "/etc/secrets/$secret.dec" "/etc/secrets/$secret"
        umask $orig_umask
        
        # Copy permissions of encrypted secret to decrypted file
        chown --reference="/etc/secrets/$secret" "/etc/secrets/$secret.dec"
        chmod --reference="/etc/secrets/$secret" "/etc/secrets/$secret.dec"
        
        # Move decrypted file over encrypted file
        mv "/etc/secrets/$secret.dec" "/etc/secrets/$secret"
        
        # Remove temporary file from .clean
        head -n -1 /etc/.clean > /etc/.clean.tmp
        mv /etc/.clean.tmp /etc/.clean
      done
    '';
  };
}
