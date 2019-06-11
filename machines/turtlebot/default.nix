{ id,
  hostName ? "turtlebot${toString id}",
  bootPartitionID,
  rootPartitionUUID }:

{ lib, config, pkgs, secrets, ... }:

with lib;

{
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/sd-image.nix>

    ../../modules
  ];

  sdImage = {
    inherit bootPartitionID rootPartitionUUID;

    imageBaseName = "${hostName}-sd-image";

    populateBootCommands = let
      extlinux-conf-builder =
        import <nixpkgs/nixos/modules/system/boot/loader/generic-extlinux-compatible/extlinux-conf-builder.nix> {
          pkgs = pkgs.buildPackages;
        };
      configTxt = pkgs.writeText "config.txt" ''
        kernel=u-boot-rpi3.bin
        # Boot in 64-bit mode.
        arm_control=0x200
        # U-Boot used to need this to work, regardless of whether UART is actually used or not.
        # TODO: check when/if this can be removed.
        enable_uart=1
        # Prevent the firmware from smashing the framebuffer setup done by the mainline kernel
        # when attempting to show low-voltage or overtemperature warnings.
        avoid_warnings=1
      '';
    in ''
      (cd ${pkgs.raspberrypifw}/share/raspberrypi/boot && cp bootcode.bin fixup*.dat start*.elf $NIX_BUILD_TOP/boot/)
      cp ${pkgs.ubootRaspberryPi3_64bit}/u-boot.bin boot/u-boot-rpi3.bin
      cp ${configTxt} boot/config.txt
      ${extlinux-conf-builder} -t 3 -c ${config.system.build.toplevel} -d ./boot
    '';
  };

  boot.loader = {
    grub.enable = false;
    generic-extlinux-compatible.enable = true;
  };

  nixpkgs.config.platform = lib.systems.platforms.aarch64-multiplatform;

  # Enable wifi firmware
  hardware.enableRedistributableFirmware = true;

  networking.supplicant = {
    wlan0 = {
      driver = "wext";
      configFile.path = secrets.getSecret secrets.turtlebot.wpaSupplicant.eduroam;
    };
    wlan1.configFile.path = secrets.getSecret secrets.turtlebot.wpaSupplicant.adhoc;
  };
  environment.etc."wpa_supplicant/eduroam_ca.pem".source = ./eduroam_ca.pem;

  environment.variables.TURTLEBOT3_MODEL = "burger";

  users = {
    users.ben.extraGroups = [ "robot" ];
    groups.robot = {};
  };

  # Allow access to robot peripherals
  services.udev.extraRules = ''
    KERNEL=="ttyUSB0", SUBSYSTEMS=="usb", MODE="0660", GROUP="robot"
    KERNEL=="ttyACM0", SUBSYSTEMS=="usb", MODE="0660", GROUP="robot"
  '';

  services.hostapd = {
    enable = true;
    interface = "ap0";
    ssid = hostName;
    extraConfig = ''
      wpa=2
      wpa_psk_file=${secrets.getSecret secrets.turtlebot.hostapd.wpaPsk}
    '';
  };

  systemd.network = {
    enable = true;
    networks = {
      "30-wlan0" = {
        name = "wlan0";
        DHCP = "v4";
      };

      # Access point
      "30-ap0" = {
        name = "ap0";
        address = [ "10.9.${toString id}.1/24" ];
        networkConfig = {
          DHCPServer = true;
          IPv6PrefixDelegation = true;
        };
        extraConfig = ''
          [DHCPServer]
          EmitDNS=no
          EmitNTP=no

          [IPv6PrefixDelegation]
          EmitDNS=no
        '';
      };
      
      # Adhoc network
      "30-wlan1" = {
        name = "wlan1";
        address = [ "192.168.42.${toString id}/24" ];
      };
    };
  };
  networking.hostName = hostName;

  # List services that you want to enable:

  services.openssh.hostKeys = [
    { type = "rsa"; bits = 4096; path = secrets.getSecret secrets.turtlebot.ssh.${hostName}.hostRsaKey; }
    { type = "ed25519"; path = secrets.getSecret secrets.turtlebot.ssh.${hostName}.hostEd25519Key; }
  ];

  # mDNS
  services.avahi = {
    enable = true;
    publish = {
      enable = true;
      addresses = true;
    };
    nssmdns = true;
  };

  # Save/restore time
  systemd.services.fake-hwclock = {
    before = [ "sysinit.target" "shutdown.target" ];
    after = [ "local-fs.target" ];
    wantedBy = [ "sysinit.target" ];
    conflicts = [ "shutdown.target" ];
    unitConfig.DefaultDependencies = false;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      StateDirectory = "fake-hwclock";
      ExecStart = pkgs.writeScript "fake-hwclock-start" ''
        #!${pkgs.stdenv.shell}

        if [ -e /var/lib/fake-hwclock/clock ]; then
          ${pkgs.coreutils}/bin/date -s "$(cat /var/lib/fake-hwclock/clock)"
        fi
      '';
      ExecStop = pkgs.writeScript "fake-hwclock-stop" ''
        #!${pkgs.stdenv.shell}
        ${pkgs.coreutils}/bin/date > /var/lib/fake-hwclock/clock
      '';
    };
  };

  # Enable SD card TRIM
  services.fstrim.enable = true;

  networking.firewall = {
    allowedUDPPorts = [
      5353 # mDNS
      67 # DHCP server
      123 # NTP
    ];
    # ROS needs arbitrary ports
    trustedInterfaces = [ "wlan1" ];
  };

  environment.secrets = mkMerge [
    (secrets.mkSecret secrets.turtlebot.wpaSupplicant.adhoc {})
    (secrets.mkSecret secrets.turtlebot.wpaSupplicant.eduroam {})
    (secrets.mkSecret secrets.turtlebot.hostapd.wpaPsk {})
    (secrets.mkSecret secrets.turtlebot.ssh.${hostName}.hostRsaKey {})
    (secrets.mkSecret secrets.turtlebot.ssh.${hostName}.hostEd25519Key {})
  ];
}
