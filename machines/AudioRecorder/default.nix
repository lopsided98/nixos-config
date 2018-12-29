{ hostName,
  ap ? false,
  bootPartitionID,
  rootPartitionUUID }:

{ lib, config, pkgs, secrets, ... }:

with lib;

let
  extraFirmwareConfig = ''
    dtoverlay=fe-pi-audio
    dtparam=audio=off
  '';
in {
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/sd-image.nix>

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
        kernel=kernel.img
        initramfs initrd followkernel
        ${extraFirmwareConfig}
      '';

      raspberrypi-builder =
        import <nixpkgs/nixos/modules/system/boot/loader/raspberrypi/raspberrypi-builder.nix> {
          inherit pkgs configTxt;
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
        version = 0;
        firmwareConfig = extraFirmwareConfig;
      };
    };
    kernelPackages = lib.mkForce pkgs.crossPackages.linuxPackages_rpi;
    /*kernelPatches = [ {
      name = "i2c-output-source-selection";
      patch = ./0001-ASoC-sgtl5000-add-I2S-output-source-selection.patch;
    } ];*/
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
  systemd.services.hostapd = mkIf ap {
    wantedBy = [ "network.target" ];
    before = [ "wpa_supplicant.service" ];
    # Hack to wait before starting wpa_supplicant
    serviceConfig.ExecStartPost = "${pkgs.coreutils}/bin/sleep 5";
  };

  systemd.network = {
    enable = true;
    networks = {
      # Home network
      "30-wlan0" = {
        name = "wlan0";
        DHCP = "v4";
        dhcpConfig.UseDNS = false;
        dns = [ "192.168.1.2" "2601:18a:0:7829:ba27:ebff:fe5e:6b6e" ];
        networkConfig = {
          LLMNR = "yes";
          MulticastDNS = "yes";
        };
        extraConfig = ''
          [IPv6AcceptRA]
          UseDNS=no
        '';
      };

      # Access point
      "30-ap0" = {
        name = "ap0";
        address = [ "10.9.0.1/24" ];
        networkConfig = {
          DHCPServer = true;
          IPv6PrefixDelegation = true;
          LLMNR = "yes";
          MulticastDNS = "yes";
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

  environment.systemPackages = with pkgs; [ sox tmux ];

  # List services that you want to enable:

  services.openssh.hostKeys = [
    { type = "rsa"; bits = 4096; path = secrets.getSecret secrets.AudioRecorder.ssh."${hostName}".hostRsaKey; }
    { type = "ed25519"; path = secrets.getSecret secrets.AudioRecorder.ssh."${hostName}".hostEd25519Key; }
  ];

  services.resolved = {
    llmnr = "true";
    extraConfig = ''
      MulticastDNS=true
    '';
  };

  # Time synchronization
  services.chrony = {
    enable = true;
    servers = optional (!ap) "audiorecorder1.local";
    initstepslew = {
      enabled = !ap;
      threshold = 0.1;
      servers = config.services.chrony.servers;
    };
    extraConfig = optionalString ap ''
      local stratum 8
      manual
      allow all
      # Always allow time to be stepped (using settime)
      makestep 1 -1
      # Don't allow any frequency offset (this clock is authoritative)
      maxdrift 0
    '';
  };
  # Don't start on boot except for master
  systemd.services.chronyd = optionalAttrs (!ap) {
    wantedBy = mkForce [];
  };

  # Audio recording service
  sound.enable = true;
  modules.audioRecorder = {
    enable = true;
    devices = map (d: optionalString (d != hostName) "http://${toLower d}.local") [
      "AudioRecorder1"
      "AudioRecorder2"
      "AudioRecorder3"
      "AudioRecorder4"
    ];
    clockMaster = ap;
  };

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

  # Disable HDMI
  systemd.services.disable-hdmi = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.raspberrypi-tools}/bin/tvservice -o";
      ExecStop = "${pkgs.raspberrypi-tools}/bin/tvservice -p";
    };

    description = "Disable HDMI port";
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
    allowedTCPPorts = [
      34876 # Allow access to audio server for debugging
      139 445 # SMB
      5355 # LLMNR
    ];
    allowedUDPPorts = [
      137 128 # NetBIOS
      5353 # mDNS
      5355 # LLMNR
    ] ++ optionals ap [
      67 # DHCP server
      123 # NTP
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
