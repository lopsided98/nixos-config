{ config, ... }: {
  _module.args = {
    secrets = {
      # Utility functions
      mkSecret = name: options: {
        "${name}" = {
          source = ../../secrets/. + "/${name}";
        } // options;
      };

      getSecret = name: "/etc/" + config.environment.secrets."${name}".target;

      getBootSecret = name: "/boot/secrets/" + config.boot.secrets."${name}".target;
    } // (import ../../secrets);
  };
}
