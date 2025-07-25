{ config, lib, pkgs, secrets, inputs, ... }: {

  imports = [
    ../ssh.nix # Enable SSH on all systems
  ];

  # Include overlays
  nixpkgs.overlays = with inputs; [
    self.overlays.default
    freefb.overlay
    nix-sdr.overlay
    (self: super: {
      crossPackages = self.forceCross {
        system = "x86_64-linux";
      } config.nixpkgs.localSystem;
    })
  ];

  lib = let
    # IP address math library
    # https://gist.github.com/duairc/5c9bb3c922e5d501a1edb9e7b3b845ba
  in (import ./net.nix { inherit lib; }).lib;

  boot = {
    # Use the latest kernel. Some ARM systems and those with ZFS might use a
    # different kernel
    kernelPackages = pkgs.linuxPackages_latest;
    # Enable magic SysRq
    kernel.sysctl."kernel.sysrq" = 1;

    initrd = {
      # NixOS tries to include a bunch of random modules by default, some of which
      # are missing in some kernel configs (e.g. Raspberry Pi). A poorly thought
      # out change made missing modules cause the build to fail, so this option
      # is basically required to use NixOS on ARM now.
      includeDefaultModules = false;

      systemd = {
        enable = true;
        emergencyAccess = "$6$Sl0MAo3O/McVvTwo$tUk05vbppFJKBwgfffLQk2f1PWbnRqiJVAF9iF697KZ0KtjzOJX78sXIbL9lwNJWJXj9RiK2PRgTlaEijz0Mh.";
        tpm2.enable = lib.mkDefault false;
      };
    };

    tmp.cleanOnBoot = true;

    # Enable GRUB serial console
    loader.grub.extraConfig = ''
      serial --unit=0 --speed=115200
      terminal_input --append serial
      terminal_output --append serial
    '';
  };

  # All systems use USA Eastern Time
  time.timeZone = "America/New_York";

  # Packages considered absolutely essential for all machines
  # Add other useful but less critical packages to the standard profile, so they
  # won't be included in the minimal profile.
  environment = {
    systemPackages = with pkgs; [
      htop
      screen
      usbutils
      killall
    ];
    # Disable packages that would be automatically added to systemPackages
    # A subset of these are re-added in the standard profile
    defaultPackages = [];
  };

  # Select internationalisation properties.
  console.keyMap = "us";
  i18n.defaultLocale = "en_US.UTF-8";

  system.buildMachines = let
    machine = m: {
      sshUser = "build";
      sshKey = secrets.getSystemdSecret "nix" secrets.build.sshKey;
    } // m;
  in {
    "HP-Z420" = machine {
      systems = [ "x86_64-linux" "i686-linux" ];
      maxJobs = 8;
      speedFactor = 8;
      supportedFeatures = [ "big-parallel" "nixos-test" "kvm" ];
    };
    "p-3400" = machine {
      systems = [ "x86_64-linux" "i686-linux" ];
      maxJobs = 4;
      speedFactor = 6;
      supportedFeatures = [ "big-parallel" "nixos-test" "kvm" ];
    };
    "ODROID-XU4" = machine {
      systems = [ "armv6l-linux" "armv7l-linux" ];
      maxJobs = 1;
      speedFactor = 4;
      supportedFeatures = [ "big-parallel" ];
    };
    "Rock64" = machine {
      systems = [ "aarch64-linux" ];
      maxJobs = 2;
      speedFactor = 2;
      supportedFeatures = [ ];
    };
    "RockPro64" = machine {
      systems = [ "aarch64-linux" ];
      maxJobs = 4;
      speedFactor = 4;
      supportedFeatures = [ "big-parallel" ];
    };
  };

  nix = {
    distributedBuilds = true;

    settings = {
      # Set local maxJobs based on remote builder configuration.
      max-jobs = lib.mkDefault (config.system.buildMachines.${config.networking.hostName}.maxJobs or 1);
      trusted-users = [ "build" ];
      auto-optimise-store = true;
      builders-use-substitutes = true;
      experimental-features = "nix-command flakes";
      
      # Use my binary cache
      substituters = let
        isHydra = config.services.nginx.virtualHosts ? "hydra.benwolsieffer.com";
      in [ "https://ros.cachix.org" ] ++
        lib.optional (!isHydra) "https://hydra.benwolsieffer.com";
      trusted-public-keys = [
        "ros.cachix.org-1:dSyZxI8geDCJrwgvCOHDoAfOm5sV1wCPjBkKL+38Rvo="
        "hydra.benwolsieffer.com-1:ppeFHW/O9KtZTQkB7vzpfIOEd4wM0+JZ4SosfqosmOQ="
      ];

      min-free = toString (1024 * 1024 * 1024);
      max-free = toString (4096 * 1024 * 1024);
    };
    # Causes infinite recursion in nix.settings
    extraOptions = ''
      netrc-file = ${secrets.getSystemdSecret "nix" secrets.hydra.netrc}
    '';

    registry.nixpkgs.to = lib.mkIf (lib.hasAttr "rev" inputs.nixpkgs.sourceInfo) {
      type = "github";
      owner = "lopsided98";
      repo = "nixpkgs";
      rev = inputs.nixpkgs.sourceInfo.rev;
    };

    # Reference the flake registry entry defined above
    nixPath = [ "nixpkgs=flake:nixpkgs" ];
  };

  # This is manually done above in a way that doesn't include the source in the
  # closure.
  nixpkgs.flake = {
    setFlakeRegistry = false;
    setNixPath = false;
  };

  # Global SSH configuration for distributed builds
  programs.ssh = {
    extraConfig = ''
      CanonicalizeHostname yes
      CanonicalizeMaxDots 0
      CanonicalDomains benwolsieffer.com

      Host HP-Z420
        Port 4245

      Host ODROID-XU4
        Port 4243

      Host p-3400
        Port 4244

      Host RasPi2
        Port 4242

      Host Rock64
        Port 4246

      Host RockPro64
        Port 4247
    '';
    knownHosts = {
      "[raspi2.benwolsieffer.com]:4242".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH0OCWeV0gomOtQQEeJI+pciKQpJ3xuAXKrOQqMED0je";
      "[odroid-xu4.benwolsieffer.com]:4243".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFmm8yfHhvqtXYWm7ivS8nfoqFPj3EKLTtD0+GAzpYYR";
      "[p-3400.benwolsieffer.com]:4244".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA63giTolB7xmmyfxqlekRl97rncLwcNpsyvR2v1IsgE";
      "[hp-z420.benwolsieffer.com]:4245".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDFSy+BIOwCUMxM+ru0tjSOIovhGqMf8UVHj8UuRJ534";
      "[rock64.benwolsieffer.com]:4246".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJeI22j7yJpTJcRpHms2V1xMbDq8DF/zmoG02HNOYWjH";
      "[rockpro64.benwolsieffer.com]:4247".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFaErh4ggyVXfR2LcdevcWtkhImptp2iaQgY1bcrjCEW";
      "github.com".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
      "gitlab.com".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfuCHKVTjquxvt6CM6tdG4SLp1Btn/nOeHHE5UOzRdf";
    };
  };

  networking = {
    useNetworkd = true;
    # I configure my networks directly using networkd
    useDHCP = false;

    # Don't use hostnames because DNSSEC fails unless the time is correct
    timeServers = [
      "129.6.15.27"
      "129.6.15.28"
      "129.6.15.29"
      "129.6.15.30"
      "2610:20:6F15:15::27"
      "132.163.97.1"
      "2610:20:6f97:97::4"
      "132.163.96.1"
      "2610:20:6f96:96::4"
    ];
  };

  # Delete old logs after 3 months
  services.journald.extraConfig = ''
    MaxRetentionSec=3month
  '';

  # Disable UDisks by default (significantly reduces system closure size)
  services.udisks2.enable = lib.mkDefault false;

  # Automatically run garbage collection once a week
  nix.gc = {
    automatic = true;
    dates = "weekly";
  };

  users = {
    # Don't allow normal user management
    mutableUsers = false;
    users = {
      ben = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        uid = 1000;
        hashedPassword = "$6$7kgb.Sjp3Z5G$dvj96191PzKF/ODL9gzKHxmcyApYBZOeABnwGNgeX0hBhCaKdPp2Js31mQ4rqk4HnXvDohBmUVqV4Hy3tjE661";
        openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPvx2Ssc6lR5PXX7esEWehj2RDyyLdZW+LDM245cOM9u 64:9a:22:db:59:50:19:64:20:6e:bf:b0:db:ef:19:b9 Dell-Inspiron-15" ];
      };
      # User for distributed builds
      build = {
        isSystemUser = true;
        description = "";
        home = "/var/lib/build";
        createHome = true;
        shell = pkgs.bashInteractive;
        group = "build";
        openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICAo5DSurLPw8PhMJq11qdqy312ie2oLV478grGUjR+B NixOS Build User" ];
      };
    };
    groups.build = {};
  };

  # My personal root CA
  security.pki.certificateFiles = [ ./root_ca.pem ];

  # Global ACME settings. Doesn't do anything unless ACME is enabled.
  security.acme = {
    # Pretend I read the terms and conditions
    # This is totally legally binding...
    acceptTerms = true;
    defaults.email = "benwolsieffer@gmail.com";
  };

  systemd.secrets.nix = {
    units = [ "nix-daemon.service" ];
    files = lib.mkMerge [
      (secrets.mkSecret secrets.build.sshKey {})
      (secrets.mkSecret secrets.hydra.netrc {
        # Make world readable so nix can access the binary cache without going
        # through the daemon. This secret is not particularly sensitive, it
        # just prevents random people from accessing my cache.
        mode = "0444";
      })
    ];
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "23.11"; # Did you read the comment?
}
