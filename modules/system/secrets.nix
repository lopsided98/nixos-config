{ config, lib, ... }: let
  # Allow a secret attrset to be coerced to a string containing its path
  secrets = lib.mapAttrsRecursiveCond (as: !as ? path) (p: val: if val ? path
    then val // { __toString = secret: secret.path; }
    else val) (import ../../secrets).secrets;
in {
  _module.args = {
    secrets = rec {
      # Utility functions
      mkSecret = secret: options: {
        "${secret}" = {
          source = ../../secrets/. + "/${secret}";
        } // options;
      };

      getSecret = secret: "/etc/" + config.environment.secrets."${secret}".target;

      getBootSecret = secret: "/boot/secrets/" + config.boot.secrets."${secret}".target;
    } // secrets;
  };
}
