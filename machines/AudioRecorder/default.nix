{ hostName,
  ap ? false,
  bootPartitionID,
  rootPartitionUUID }:

{ lib, config, pkgs, secrets, ... }:

with lib;

let
  extraFirmwareConfig = ''
    initramfs initrd followkernel
    dtoverlay=fe-pi-audio
    dtparam=audio=off
  '';
in {
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/sd-image.nix>

    ../../modules/config/nginx.nix

    ../../modules
  ];

  sdImage = {
    inherit bootPartitionID rootPartitionUUID;

    imageBaseName = "${hostName}-sd-image";

    populateBootCommands = let
      configTxt = pkgs.writeText "config.txt" ''
        # U-Boot used to need this to work, regardless of whether UART is actually used or not.
        # TODO: check when/if this can be removed.
        enable_uart=1
        # Prevent the firmware from smashing the framebuffer setup done by the mainline kernel
        # when attempting to show low-voltage or overtemperature warnings.
        avoid_warnings=1
        ${extraFirmwareConfig}
      '';

      raspberrypi-builder =
        import <nixpkgs/nixos/modules/system/boot/loader/raspberrypi/raspberrypi-builder.nix> {
          inherit pkgs configTxt;
          version = 1;
        };
    in ''
      pushd ${pkgs.raspberrypifw}/share/raspberrypi/boot
      cp -r overlays $NIX_BUILD_TOP/boot/
      popd
      ${raspberrypi-builder} -c ${config.system.build.toplevel} -d ./boot
    '';
  };

  boot = {
    loader = {
      grub.enable = false;
      raspberryPi = {
        enable = true;
        version = 1;
        firmwareConfig = extraFirmwareConfig;
      };
    };
    kernelPackages = lib.mkForce pkgs.linuxPackages_rpi;
  };

  nixpkgs.config.platform = lib.systems.platforms.raspberrypi;

  # Enable wifi firmware
  hardware.enableRedistributableFirmware = true;

  networking.wireless = {
    enable = true;
    interfaces = [ "wlan0" ];
  };

  # Create virtual AP
  networking.localCommands = mkIf ap ''
    ${pkgs.iw}/bin/iw dev wlan0 interface add ap0 type __ap
  '';

  services.hostapd = mkIf ap {
    enable = true;
    interface = "ap0";
    ssid = "AudioRecorder";
    extraConfig = ''
      wpa=2
      wpa_psk_file=${secrets.getSecret secrets.AudioRecorder.hostapd.wpaPsk}
    '';
  };

  systemd.network = {
    enable = true;
    networks = {
      # Home network
      wlan0 = {
        name = "wlan0";
        DHCP = "v4";
        dhcpConfig.UseDNS = false;
        dns = [ "192.168.1.2" "2601:18a:0:7829:ba27:ebff:fe5e:6b6e" ];
        extraConfig = ''
          [IPv6AcceptRA]
          UseDNS=no
        '';
      };

      # Access point
      ap0 = {
        name = "ap0";
        address = [ "10.9.0.1/24" ];
        networkConfig = {
          DHCPServer = "yes";
          IPv6PrefixDelegation = "yes";
        };
        extraConfig = ''
          [DHCPServer]
          EmitDNS=no
          EmitNTP=no

          [IPv6PrefixDelegation]
          EmitDNS=no
        '';
      };
    };
  };
  networking.hostName = hostName;

  # Allow access to audio devices
  users.users = {
    ben.extraGroups = [ "audio" "audio-recorder" ];
    gary = {
      isNormalUser = true;
      extraGroups = [ "wheel" "audio" "audio-recorder" ];
      uid = 1001;
      hashedPassword = "$6$aC3UnQWVt$y.uMfBSzkcdasHj.aWjtRvqJIRhi3OuervlLcyDiZmsF5rFPClOUTP5NaXdBPhMVLPUAEOIov/6pyTob2r0qx.";
      openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGmfMgjNEt/J4aW+CPj1JQjReapFe4y/NHZqLn9IxFCQ ed25519-key-20180907" ];
    };
  };

  environment.systemPackages = with pkgs; [ sox /* tmux */ ];

  # List services that you want to enable:

  services.openssh.hostKeys = [
    { type = "rsa"; bits = 4096; path = secrets.getSecret secrets.AudioRecorder.ssh."${hostName}".hostRsaKey; }
    { type = "ed25519"; path = secrets.getSecret secrets.AudioRecorder.ssh."${hostName}".hostEd25519Key; }
  ];

  services.avahi = {
    enable = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };

  # Audio recording service
  sound.enable = true;
  modules.audioRecorder.enable = true;

  # Samba file sharing
  services.samba = {
    enable = true;
    enableWinbindd = false;
    shares.audio = {
      path = "/var/lib/${config.modules.audioRecorder.audioDir}";
      "valid users" = "ben, gary";
      writable = "yes";
    };
    extraConfig = ''
      workgroup = MSHOME
      passdb backend = smbpasswd:${secrets.getSecret secrets.AudioRecorder.samba.smbpasswd}

      # Disable printing
      load printers = no
      printing = bsd
      printcap name = /dev/null
      disable spoolss = yes
    '';
  };

  # Enable SD card TRIM
  services.fstrim.enable = true;

  networking.firewall = {
    allowedTCPPorts = [
      34876 # Allow access to audio server for debugging
      139 445 # SMB
    ];
    allowedUDPPorts = mkIf ap [
      67 # DHCP server
      137 128 # NetBIOS
    ];
  };

  environment.secrets = mkMerge [
    (secrets.mkSecret secrets.AudioRecorder.wpaSupplicant."${if ap then "apConf" else "conf"}" {
      target = "wpa_supplicant.conf";
    })
    (mkIf ap (secrets.mkSecret secrets.AudioRecorder.hostapd.wpaPsk {}))
    (secrets.mkSecret secrets.AudioRecorder.ssh."${hostName}".hostRsaKey {})
    (secrets.mkSecret secrets.AudioRecorder.ssh."${hostName}".hostEd25519Key {})
    (secrets.mkSecret secrets.AudioRecorder.samba.smbpasswd {})
  ];
}
