{
  description = "Packages, modules and configurations for my NixOS machines";

  inputs = {
    fixed-wing-sampling.url = "git+ssh://git@gitlab.com/dartmouthrobotics/fixed_wing_sampling.git";
    flake-utils.url = "github:numtide/flake-utils";
    freefb.url = "git+ssh://git@github.com/lopsided98/freefb.git";
    kitty-cam.url = "github:lopsided98/kitty-cam";
    lib-net = {
      url = "https://gist.github.com/duairc/5c9bb3c922e5d501a1edb9e7b3b845ba/archive/3885f7cd9ed0a746a9d675da6f265d41e9fd6704.tar.gz";
      flake = false;
    };
    nix-ros-overlay.url = "github:lopsided98/nix-ros-overlay/develop";
    nix-sdr.url = "github:lopsided98/nix-sdr";
    nixos-secrets.url = "github:lopsided98/nixos-secrets";
    nixpkgs-master-custom.url = "github:lopsided98/nixpkgs/master-custom";
    nixpkgs-unstable-custom.url = "github:lopsided98/nixpkgs/unstable-custom";
    radonpy.url = "github:lopsided98/radonpy";
    ros-sailing.url = "git+ssh://git@gitlab.com/dartmouthrobotics/ros_sailing.git";
    secrets.url = "git+ssh://git@github.com/lopsided98/nixos-config-secrets.git";
    water-level-monitor.url = "github:lopsided98/WaterLevelMonitor";
    zeus-audio.url = "github:lopsided98/zeus_audio";
  };

  outputs = inputs:
  with inputs;
  with flake-utils.lib;
  let
    lib = nixpkgs-unstable-custom.lib;

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
      lib.listToAttrs (map (system: lib.nameValuePair system (import nixpkgs {
        inherit system;
        overlays = [
          self.overlays.default
          nixos-secrets.overlays.default
        ];
        config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
          "dropbox"
          "zoom"
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
      inherit
        dnsupdate
        nixos-secrets;
      deploy = runCommand "deploy" {
        inherit runtimeShell;
        nixosRoot = "/home/ben/nixos";
        secretsRoot = "/home/ben/nixos/secrets";
        path = lib.makeBinPath [ nix nixos-secrets coreutils openssh git rsync jq curl ];
      } ''
        substituteAll ${./deploy.sh} "$out"
        chmod +x "$out"
      '';

      user-env = pkgs.callPackage ./machines/Dell-Inspiron-15/user-env.nix { };
    };

    apps = rec {
      default = deploy;
      deploy = {
        type = "app";
        program = self.packages.${system}.deploy.outPath;
      };

      update-user-env = {
        type = "app";
        program = (pkgs.callPackage ./scripts/update-user-env.nix {
          inherit (self.packages.${system}) user-env;
        }).outPath;
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
