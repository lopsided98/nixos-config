{ config, lib, pkgs, ... }:

{

  imports = [
    ./ssh.nix # Enable SSH on all systems
  ];

  # Include my custom package overlay
  nixpkgs.overlays = [ (import ../pkgs/packages.nix) ];
  
  # Use the latest kernel. Some ARM systems and those with ZFS might use a 
  # different kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # All systems use USA Eastern Time
  time.timeZone = "America/New_York";
  
  # Standard set of packages
  environment.systemPackages = with pkgs; [
    htop iotop git python27 file vim
  ];
  
  # Select internationalisation properties.
  i18n = {
    consoleKeyMap = "us";
    defaultLocale = "en_US.UTF-8";
  };

  nix = {
    # Build packages in sandbox
    useSandbox = true;
    
    buildMachines = let
      # Automatically set current machine hostname to localhost
      machine = { hostName, ... }@m: m // {
        sshUser = "build";
        sshKey = "/var/lib/build/.ssh/id_ed25519";
      };
    in builtins.filter ({ hostName, ... }: hostName != config.networking.hostName) [
      (machine {
        hostName = "NixOS-Test";
        system = "x86_64-linux";
        maxJobs = 2;
      })
      (machine {
        hostName = "ODROID-XU4";
        system = "armv7l-linux";
        maxJobs = 4;
      }) 
      (machine {
        hostName = "Dell-Optiplex-780";
        system = "x86_64-linux";
        maxJobs = 2;
      })
    ];
    distributedBuilds = true;
    extraOptions = ''
      auto-optimise-store = true
      trusted-users = build
    '';
    
    nixPath = [
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos/nixpkgs"
      "nixos-config=/home/ben/nixos/configuration.nix"
      "nixpkgs-overlays=/home/ben/nixos/overlays"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  };
  
  # Public key for nix-copy-closure (might not be necessary with Nix 1.12?)
  # The private key is stored in Ansible Vault
  environment.etc."nix/signing-key.pub".text = ''
    -----BEGIN PUBLIC KEY-----
    MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAu1WFiLIaZVGL0/1Dk8ie
    dfACcBEEr94zZNrTRbGzlyyD1pGjwqzPTcEXCc97JzTucNqtQnTiW+rxD0yU/ZO7
    W3+1KBQPl93XHvezIItYVxEB4Rjf4GxHYqjZ/ahSesM3sK6jcbLuu1kAwrNiWBso
    qoBKfjHZW2TInUCGaFDX84T6KoXde/VcGqLghoT0D61Gmt0eTkIOpKK+FiJD8Ale
    6BahM0sMB2Z2z4WqkdNkL6b6IbFwuwd6y6OfWy5dQPxixoxU5CsZXH8xtFHjbvFD
    TCHMhkOb9YPuM/ltMKGU8/8lK+Bu9bdrTL2c3mf4UD2FAm01eZwFPDTjR8Rj+UAA
    ywIDAQAB
    -----END PUBLIC KEY-----
  '';

  
  # Global SSH configuration for distributed builds
  programs.ssh = let
    host = { name, port, hostName }: ''
      Host ${if name == config.networking.hostName then "localhost" else name}
          Port ${toString port}
          HostName ${hostName}
          IdentityFile /var/lib/build/.ssh/id_ed25519
    '';
  in {
    extraConfig = 
      (host {
        name = "NixOS-Test";
        port = 4247;
        hostName = "hp-z420.nsupdate.info";
      }) +
      (host {
        name = "ODROID-XU4";
        port = 4243;
        hostName = "odroid-xu4.benwolsieffer.com";
      }) +
      (host {
        name = "Dell-Optiplex-780";
        port = 4244;
        hostName = "dell-optiplex-780.benwolsieffer.com";
      });

    knownHosts = [
      {
        hostNames = [ "odroid-xu4.benwolsieffer.com" ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFmm8yfHhvqtXYWm7ivS8nfoqFPj3EKLTtD0+GAzpYYR";
      }
      {
        hostNames = [ "dell-optiplex-780.benwolsieffer.com" ];
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIODxgNjFuareM/XZEo7ZZrGddVj2Bx6RfaOTK1/DyNBJ";
      }
    ];
  };

  networking.firewall.enable = true;
  # Disable NixOS standard network configuration because I use systemd-networkd
  networking.useDHCP = false;
  
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

  users = {
    # Don't allow normal user management
    mutableUsers = false;
    extraUsers = {
      ben = {
        isNormalUser = true;
        home = "/home/ben";
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
    extraGroups = {
      build = {};
    };
  };
  
  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "18.03"; # Did you read the comment?
}
