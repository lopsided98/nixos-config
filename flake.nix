{
  description = "Packages, modules and configurations for my NixOS machines";

  inputs = {
    nixpkgs-unstable-custom.url = "github:lopsided98/nixpkgs/unstable-custom";
    nixpkgs-master-custom.url = "github:lopsided98/nixpkgs/master-custom";
    nixos-secrets.url = "github:lopsided98/nixos-secrets";
    secrets.url = "git+ssh://git@github.com/lopsided98/nixos-config-secrets.git";
    zeus-audio.url = "github:lopsided98/zeus_audio";
    nix-ros-overlay.url = "github:lopsided98/nix-ros-overlay/staging";
    ros-sailing.url = "git+ssh://git@gitlab.com/dartmouthrobotics/ros_sailing.git";
    hydra.url = "github:NixOS/hydra/5c90edd19f1787141ae3d9751f567b4df11fc0fa";
    freefb.url = "git+ssh://git@github.com/lopsided98/freefb.git";
    nix-sdr.url = "github:lopsided98/nix-sdr";
    radonpy.url = "github:lopsided98/radonpy";
    water-level-monitor.url = "github:lopsided98/WaterLevelMonitor";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs:
  with inputs;
  with nixpkgs-unstable-custom.lib;
  with flake-utils.lib;
  let
    systems = [
      "x86_64-linux"
      "aarch64-linux"
      "armv7l-linux"
      "armv6l-linux"
      "armv5tel-linux"
    ];

    nixpkgsSystemsAttrs = nixpkgs: systems:
      listToAttrs (map (system: nameValuePair system (import nixpkgs {
        inherit system;
        overlays = [
          self.overlay
          nixos-secrets.overlay
        ];
      })) systems);

    nixpkgsBySystem =
      (nixpkgsSystemsAttrs nixpkgs-unstable-custom [
        "x86_64-linux"
        "aarch64-linux"
      ]) //
      (nixpkgsSystemsAttrs nixpkgs-master-custom [
        "armv7l-linux"
        "armv6l-linux"
        "armv5tel-linux"
      ]);
  in eachSystem systems (system: let
    pkgs = nixpkgsBySystem.${system};
  in {
    packages = with pkgs; {
      inherit dnsupdate;
    };

    apps = {
      deploy = {
        type = "app";
        program = with pkgs; (runCommand "deploy" {
          inherit runtimeShell;
          nixosRoot = "/home/ben/nixos";
          secretsRoot = "/home/ben/nixos/secrets";
          path = lib.makeBinPath [ nix nixos-secrets coreutils openssh git rsync jq curl ];
        } ''
          substituteAll ${./deploy.sh} "$out"
          chmod +x "$out"
        '').outPath;
      };
    };

    defaultApp = self.apps.${system}.deploy;
  }) // {
    overlay = import ./pkgs;

    nixosModule = import ./modules;

    nixosConfigurations = let
      importMachines = nixpkgs: hostSystems: (import ./machines {
        inherit (nixpkgs) lib;
        inherit hostSystems;
        modules = [
          {
            # Allow modules to access flake inputs
            _module.args.inputs = inputs // {
              # Add fake nixpkgs input that selects the right branch for the
              # machine
              inherit nixpkgs;
            };
          }
          nixos-secrets.nixosModule
          secrets.nixosModule
          zeus-audio.nixosModule
          nix-ros-overlay.nixosModule
          hydra.nixosModules.hydra
          nix-sdr.nixosModule
          radonpy.nixosModule
          water-level-monitor.nixosModule
        ];
      });
    in importMachines nixpkgs-unstable-custom [ "x86_64-linux" "aarch64-linux" ] //
       importMachines nixpkgs-master-custom [ "armv7l-linux" "armv6l-linux" "armv5tel-linux" ];

    hydraJobs = {
      machines = mapAttrs (name: config: config.config.system.build.toplevel)
        self.nixosConfigurations;
    };
  };
}
