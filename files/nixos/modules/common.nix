{ lib, pkgs, ... }:

{
  # Build packages in sandbox
  nix.useSandbox = true;

  nixpkgs.overlays = [ (import ../pkgs/packages.nix) ];

  time.timeZone = "America/New_York";
  
  boot.tmpOnTmpfs = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  
  # Standard set of packages
  environment.systemPackages = with pkgs; [
    htop iotop git python27 file vim
  ];
  
  environment.variables = {
    NIX_PATH = lib.mkForce [ 
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos/nixpkgs"
      "nixos-config=/home/ben/nixos/configuration.nix"
      "nixpkgs-overlays=/home/ben/nixos/overlays"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  };
  
  # Select internationalisation properties.
  i18n = {
  #  consoleFont = "Lat2-Terminus16";
    consoleKeyMap = "us";
    defaultLocale = "en_US.UTF-8";
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
  
  # Don't allow normal user management
  users.mutableUsers = false;
  users.extraUsers.ben = {
    isNormalUser = true;
    home = "/home/ben";
    extraGroups = [ "wheel" ];
    uid = 1000;
    hashedPassword = "$6$7kgb.Sjp3Z5G$dvj96191PzKF/ODL9gzKHxmcyApYBZOeABnwGNgeX0hBhCaKdPp2Js31mQ4rqk4HnXvDohBmUVqV4Hy3tjE661";
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPvx2Ssc6lR5PXX7esEWehj2RDyyLdZW+LDM245cOM9u 64:9a:22:db:59:50:19:64:20:6e:bf:b0:db:ef:19:b9 Dell-Inspiron-15" ];
  };
  
  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "18.03"; # Did you read the comment?
}
