{ config, lib, pkgs, secrets, ... }: {

  imports = [
    ../ssh.nix # Enable SSH on all systems
  ];

  # Include overlays
  nixpkgs.overlays = [
    (import ../../../pkgs)
    (self: super: {
      crossPackages = self.forceCross {
        system = "x86_64-linux";
        platform = lib.systems.platforms.pc64;
      } config.nixpkgs.localSystem;
    })
  ];

  boot = {
    # Use the latest kernel. Some ARM systems and those with ZFS might use a
    # different kernel
    kernelPackages =
      # Use cross-compiled kernel on ARM, if we aren't cross-compiling everything
      if pkgs.stdenv.isAarch32 && pkgs.stdenv.hostPlatform == pkgs.stdenv.buildPlatform 
      then pkgs.crossPackages.linuxPackages_latest
      else pkgs.linuxPackages_latest;

    # Enable a shell if boot fails. This is disabled by default because it
    # gives root access, but someone with access to this shell would also have
    # physical access to the machine, so this doesn't really matter.
    kernelParams = [ "boot.shell_on_fail" ];
    cleanTmpDir = true;

    # Enable magic SysRq
    kernel.sysctl."kernel.sysrq" = 1;

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
  # Add other useful but less critical packages to standard profile, so they
  # won't be included in the minimal profile.
  environment = {
    systemPackages = with pkgs; [
      htop
      iotop
      screen
      usbutils
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
    "Dell-Optiplex-780" = machine {
      systems = [ "x86_64-linux" "i686-linux" ];
      maxJobs = 2;
      speedFactor = 2;
      supportedFeatures = [ "nixos-test" "kvm" ];
    };
    "ODROID-XU4" = machine {
      systems = [ "armv6l-linux" "armv7l-linux" ];
      maxJobs = 6;
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
      maxJobs = 6;
      speedFactor = 4;
      supportedFeatures = [ "big-parallel" ];
    };
  };

  # Set local maxJobs based on remote builder configuration.
  nix.maxJobs = lib.mkDefault (config.system.buildMachines.${config.networking.hostName}.maxJobs or 1);

  nix = {
    trustedUsers = [ "build" ];
    distributedBuilds = true;
    autoOptimiseStore = true;
    extraOptions = ''
      builders-use-substitutes = true
      netrc-file = ${secrets.getSystemdSecret "nix" secrets.hydra.netrc}
      min-free = ${toString (1024 * 1024 * 1024)}
      max-free = ${toString (4096 * 1024 * 1024)}
    '';

    # Use my binary cache
    binaryCaches = let
      isHydra = config.services.nginx.virtualHosts ? "hydra.benwolsieffer.com";
    in [ "https://ros.cachix.org" ] ++
      lib.optional (!isHydra) "https://hydra.benwolsieffer.com";
    binaryCachePublicKeys = [
      "ros.cachix.org-1:dSyZxI8geDCJrwgvCOHDoAfOm5sV1wCPjBkKL+38Rvo="
      "hydra.benwolsieffer.com-1:ppeFHW/O9KtZTQkB7vzpfIOEd4wM0+JZ4SosfqosmOQ="
    ];
  };

  # Global SSH configuration for distributed builds
  programs.ssh = {
    extraConfig = ''
      CanonicalizeHostname yes
      CanonicalizeMaxDots 0
      CanonicalDomains benwolsieffer.com thayer.dartmouth.edu cs.dartmouth.edu

      Host HP-Z420
        Port 4245

      Host ODROID-XU4
        Port 4243

      Host Dell-Optiplex-780
        Port 4244

      Host RasPi2
        Port 4242

      Host Rock64
        Port 4246

      Host RockPro64
        Port 4247

      Host *.cs.dartmouth.edu
        User benwolsieffer

      Host *.thayer.dartmouth.edu
        User f002w9k
    '';
    knownHosts = {
      "[raspi2.benwolsieffer.com]:4242".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH0OCWeV0gomOtQQEeJI+pciKQpJ3xuAXKrOQqMED0je";
      "[odroid-xu4.benwolsieffer.com]:4243".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFmm8yfHhvqtXYWm7ivS8nfoqFPj3EKLTtD0+GAzpYYR";
      "[dell-optiplex-780.benwolsieffer.com]:4244".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIODxgNjFuareM/XZEo7ZZrGddVj2Bx6RfaOTK1/DyNBJ";
      "[hp-z420.benwolsieffer.com]:4245".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDFSy+BIOwCUMxM+ru0tjSOIovhGqMf8UVHj8UuRJ534";
      "[rock64.benwolsieffer.com]:4246".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJeI22j7yJpTJcRpHms2V1xMbDq8DF/zmoG02HNOYWjH";
      "[rockpro64.benwolsieffer.com]:4247".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFaErh4ggyVXfR2LcdevcWtkhImptp2iaQgY1bcrjCEW";
      "github.com".publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==";
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

  programs.bash.enableCompletion = true;

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
    email = "benwolsieffer@gmail.com";
  };

  systemd.secrets.nix = {
    units = [ "nix-daemon.service" ];
    files = lib.mkMerge [
      (secrets.mkSecret secrets.build.sshKey {})
      (secrets.mkSecret secrets.hydra.netrc {})
    ];
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "20.03"; # Did you read the comment?
}
