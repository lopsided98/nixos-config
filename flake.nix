{
  description = "Packages, modules and configurations for my NixOS machines";

  inputs = {
    fixed-wing-sampling.url = "git+ssh://git@gitlab.com/dartmouthrobotics/fixed_wing_sampling.git";
    flake-utils.url = "github:numtide/flake-utils";
    freefb.url = "git+ssh://git@github.com/lopsided98/freefb.git";
    kitty-cam.url = "github:lopsided98/kitty-cam";
    nix-ros-overlay.url = "github:lopsided98/nix-ros-overlay/develop";
    nix-sdr.url = "github:lopsided98/nix-sdr";
    nixos-secrets.url = "github:lopsided98/nixos-secrets";
    nixpkgs-master-custom.url = "github:lopsided98/nixpkgs/master-custom";
    nixpkgs-unstable-custom.url = "github:lopsided98/nixpkgs/unstable-custom";
    radonpy.url = "github:lopsided98/radonpy";
    secrets.url = "git+ssh://git@github.com/lopsided98/nixos-config-secrets.git";
    water-level-monitor.url = "github:lopsided98/WaterLevelMonitor";
    zeus-audio.url = "github:lopsided98/zeus_audio";
  };

  outputs = { self, ... }@inputs: let
    lib = inputs.nixpkgs-unstable-custom.lib;

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

    nixpkgsForSystem = nixpkgs: buildSystem: hostSystem: import nixpkgs {
      system = buildSystem;
      crossSystem = hostSystem;
      overlays = [
        self.overlays.default
        inputs.nixos-secrets.overlays.default
      ];
      config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
        "dropbox"
        # used by dropbox, mostly unnecessary but a pain to remove
        "firefox-bin"
        "firefox-bin-unwrapped"
      ];
    };

    nixpkgsBySystem = {
      "x86_64-linux" = nixpkgsForSystem inputs.nixpkgs-unstable-custom "x86_64-linux" null;
      "aarch64-linux" = nixpkgsForSystem inputs.nixpkgs-unstable-custom "aarch64-linux" null;
      "armv7l-linux" = nixpkgsForSystem inputs.nixpkgs-master-custom "x86_64-linux" "armv7l-linux";
      "armv6l-linux" = nixpkgsForSystem inputs.nixpkgs-master-custom "x86_64-linux" "armv6l-linux";
      "armv5tel-linux" = nixpkgsForSystem inputs.nixpkgs-master-custom "x86_64-linux" "armv5tel-linux";
    };

    outputsForSystems = systems: func: inputs.flake-utils.lib.eachSystem systems
      (system: func system nixpkgsBySystem.${system});

    mergeOutputs = lib.foldl lib.recursiveUpdate { };

    outputsAllSystems = system: pkgs: {
      packages = with pkgs; {
        inherit
          dnsupdate
          nixos-secrets
          tinyssh;
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
    };

    outputsx86_64Only = system: pkgs: {
      packages.user-env = pkgs.callPackage ./machines/Dell-Inspiron-15/user-env.nix { };

      apps.update-user-env = {
        type = "app";
        program = (pkgs.callPackage ./scripts/update-user-env.nix {
          inherit (self.packages.${system}) user-env;
        }).outPath;
      };
    };

    outputsRpiArchOnly = system: pkgs: {
      packages = {
        inherit (pkgs) rpicam-apps;
      };
    };

    outputsNoSystem = {
      overlays.default = import ./pkgs;

      nixosModules.default = ./modules;

      nixosConfigurations = let
        importMachines = nixpkgs: hostSystems: (import ./machines {
          inherit (nixpkgs) lib;
          inherit hostSystems;
          modules = with inputs; [
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
      in importMachines inputs.nixpkgs-unstable-custom [ "x86_64-linux" "aarch64-linux" ] //
         importMachines inputs.nixpkgs-master-custom [ "armv7l-linux" "armv6l-linux" "armv5tel-linux" ];

      hydraJobs = {
        machines = lib.mapAttrs (name: config: config.config.system.build.toplevel)
          self.nixosConfigurations;
        packages = lib.getAttrs hydraSystems self.packages;
      };
    };
  in mergeOutputs [
    (outputsForSystems systems outputsAllSystems)
    (outputsForSystems [ "x86_64-linux" ] outputsx86_64Only)
    (outputsForSystems [ "armv6l-linux" "armv7l-linux" "aarch64-linux" ] outputsRpiArchOnly)
    outputsNoSystem
  ];
}
