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
    kernelPackages = if pkgs.stdenv.isAarch32 then pkgs.crossPackages.linuxPackages_latest
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
  environment.systemPackages = with pkgs; [
    htop
    iotop
    screen
    usbutils
  ];

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
      supportedFeatures = [ "big-parallel" "nixos-test" ];
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
      "babylon1.thayer.dartmouth.edu".publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBP4kFknlR2wSVMEQpkKaF94oQknPSC1tn2LYQOmRaOfpTvHlriMdTxmJmLXQXJ9+sJDQjFER82pdHkUARkdixgw=";
      "babylon2.thayer.dartmouth.edu".publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBC/9qHbvq9MusqH3Hfg8IR12y4Ke7asjW8m2H1TG28LQFtqwS5wAeTZ+5rOvxYDGksuv+xn4rDdQ97BgeAl8igo=";
      "babylon3.thayer.dartmouth.edu".publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBF3JJkf9cYLO72VM16cAkJ6Odpv2fndns5EyhXH1vhHF7qzBOh0owxNztglQQju1WV2T9/oFNmDCOkQrq8ooIzM=";
      "babylon4.thayer.dartmouth.edu".publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBNFhs+i6NZvPfS+z1rPcZ0AO8BkZMwcGRfcOj6VoA8i3AMbeSLs9L0euCuGF3G7qVUXXs8cfJl16tjVqjXVqKvU=";
      "babylon5.thayer.dartmouth.edu".publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBIAkBc0Up3SrXSl5Ubd0dr61gF4FTp4NnrTGw0NcKqIXHo0KMbsMTCFyq4bN1nyo5IWop7eFF4FvGgnNzk2lOvM=";
      "babylon6.thayer.dartmouth.edu".publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBMd4NLcm9Gv2hUB35KK4Lb2T49kl2apWfTiqlLlydc3PTGYCfMm3rOL3LgW9atqT8pn2FWg6B2KZjHM8mZcy6O0=";
      "babylon7.thayer.dartmouth.edu".publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBPORxS4Hg9so30ktT2Dk5JrTMmkJp3rllfG9xXsFvX6C7hrMd1Aaiv4V0B2MNLBsvKEAkF+kDKoNmZ2kvVuYQzs=";
      "babylon8.thayer.dartmouth.edu".publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBHaH1x8SIinN8wMbafHc/fZBbTl0w2cJfzNHmlAD2gGt9iookORXMEvS4XW9zFKtKTGZjW0xO0iVj7rSa9SRtQU=";
      "bear.cs.dartmouth.edu".publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBI1q3WedIIRk5zZTxfxE8HZQBvTD5eARHEkQ4jpiCvy+5+hILMMMdNAPGFasXivCM6fgoNRhBYz+zC2iWXH416U=";
      "flume.cs.dartmouth.edu".publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBDpOEp1zfF9mKLza6VlGO5TX/vJ1wlapEQC9Lb7dke2CeMy61ytgnaBqpAcfiHP4BnCGeb37usHfTYiHyZd3UBs=";
      "tahoe.cs.dartmouth.edu".publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBHcGnvXB8fBeLdIMTYolAuxE+WTQH2JOeQPFwwfPh5ahYSk8bOkaWhRhinv3krWNter8HxNKcnwaBrFrCNOp28I=";
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
  # Stolen from Arch Linux
  programs.bash.promptInit = ''
    PS1='[\u@\h \W]\$ '

    case ''${TERM} in
      xterm*|rxvt*|Eterm|aterm|kterm|gnome*)
        PROMPT_COMMAND=''${PROMPT_COMMAND:+$PROMPT_COMMAND; }'printf "\033]0;%s@%s:%s\007" "''${USER}" "''${HOSTNAME%%.*}" "''${PWD/#$HOME/\~}"'

        ;;
      screen*)
        PROMPT_COMMAND=''${PROMPT_COMMAND:+$PROMPT_COMMAND; }'printf "\033_%s@%s:%s\033\\" "''${USER}" "''${HOSTNAME%%.*}" "''${PWD/#$HOME/\~}"'
        ;;
    esac
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
  system.stateVersion = "19.09"; # Did you read the comment?
}
