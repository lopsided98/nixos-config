{
  description = "Packages, modules and configurations for my NixOS machines";

  inputs = {
    nixpkgs-unstable-custom.url = "github:lopsided98/nixpkgs/unstable-custom";
    nixpkgs-master-custom.url = "github:lopsided98/nixpkgs/master-custom";
    nixos-secrets.url = "github:lopsided98/nixos-secrets";
    secrets.url = "git+ssh://git@github.com/lopsided98/nixos-config-secrets.git";
    nix-ros-overlay.url = "github:lopsided98/nix-ros-overlay/staging";
    ros-sailing.url = "git+ssh://git@gitlab.com/dartmouthrobotics/ros_sailing.git";
  };

  outputs = { self, nixpkgs-unstable-custom, nixpkgs-master-custom
            , nixos-secrets, secrets, nix-ros-overlay, ... }@inputs:
    with nixpkgs-unstable-custom.lib;
  {
    nixosConfigurations = let
      importMachines = nixpkgs: hostSystems: (import ./machines {
        inherit (nixpkgs) lib;
        inherit hostSystems;
        # Allow modules to access flake inputs
        modules = [
          {
            _module.args.inputs = inputs // {
              # Add fake nixpkgs input that selects the right branch for the
              # machine
              inherit nixpkgs;
            };
          }
          nixos-secrets.nixosModule
          secrets.nixosModule
          nix-ros-overlay.nixosModule
        ];
      });
    in importMachines nixpkgs-unstable-custom [ "x86_64-linux" "aarch64-linux" ] //
       importMachines nixpkgs-master-custom [ "armv7l-linux" "armv6l-linux" "armv5tel-linux" ];

    hydraJobs = foldr recursiveUpdate {} (mapAttrsToList (name: config: {
      ${config.config.local.system.buildSystem.system}.${name} = config.config.system.build.toplevel;
    }) self.nixosConfigurations);
  };
}
