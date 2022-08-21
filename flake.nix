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
    kitty-cam.url = "github:lopsided98/kitty-cam";
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
    hydraSystems = [
      "x86_64-linux"
      "aarch64-linux"
    ];

    nixpkgsSystemsAttrs = nixpkgs: systems:
      listToAttrs (map (system: nameValuePair system (import nixpkgs {
        inherit system;
        overlays = [
          self.overlays.default
          nixos-secrets.overlays.default
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
      deploy = runCommand "deploy" {
        inherit runtimeShell;
        nixosRoot = "/home/ben/nixos";
        secretsRoot = "/home/ben/nixos/secrets";
        path = lib.makeBinPath [ nix nixos-secrets coreutils openssh git rsync jq curl ];
      } ''
        substituteAll ${./deploy.sh} "$out"
        chmod +x "$out"
      '';
    };

    apps = rec {
      default = deploy;
      deploy = {
        type = "app";
        program = self.packages.${system}.deploy.outPath;
      };
    };
  }) // {
    overlays.default = import ./pkgs;

    nixosModules.default = import ./modules;

    nixosConfigurations = let
      importMachines = nixpkgs: hostSystems: (import ./machines {
        inherit (nixpkgs) lib;
        inherit hostSystems;
        modules = [
          nixos-secrets.nixosModules.default
          secrets.nixosModule
          zeus-audio.nixosModule
          nix-ros-overlay.nixosModules.default
        ];
        # Allow modules to access flake inputs
        specialArgs.inputs = inputs // {
          # Add fake nixpkgs input that selects the right branch for the
          # machine
          inherit nixpkgs;
        };
      });
    in importMachines nixpkgs-unstable-custom [ "x86_64-linux" "aarch64-linux" ] //
       importMachines nixpkgs-master-custom [ "armv7l-linux" "armv6l-linux" "armv5tel-linux" ];

    hydraJobs = {
      machines = mapAttrs (name: config: config.config.system.build.toplevel)
        self.nixosConfigurations;
      packages = getAttrs hydraSystems self.packages;
    };
  };
}
