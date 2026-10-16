{
  config,
  lib,
  pkgs,
  utils,
  secrets,
  ...
}:
let
  cfg = config.local.services.steam;

  steam = pkgs.steam.override (prev: {
    extraLibraries =
      pkgs:
      let
        prevLibs = if prev ? extraLibraries then prev.extraLibraries pkgs else [ ];
        additionalLibs =
          with config.hardware.graphics;
          if pkgs.stdenv.hostPlatform.is64bit then
            [ package ] ++ extraPackages
          else
            [ package32 ] ++ extraPackages32;
      in
      prevLibs ++ additionalLibs;
      buildFHSEnv = pkgs.buildFHSEnv.override {
        # use the setuid wrapped bubblewrap
        bubblewrap = "${config.security.wrapperDir}/..";
      };
  });
in
{
  options.local.services.steam = {
    enable = lib.mkEnableOption "Steam console machine";
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.config.allowUnfreePredicate =
      pkg:
      builtins.elem (lib.getName pkg) [
        "cccl"
        "cuda_compat"
        "cuda_crt"
        "cuda_cudart"
        "cuda_nvcc"
        "libnvvm"
        "nvidia-settings"
        "nvidia-x11"
        "steam-unwrapped"
        "steam"
      ];

    hardware = {
      graphics.enable = true;
      nvidia = {
        open = true;
        videoAcceleration = true;
        modesetting.enable = true;
      };
    };

    services.xserver.videoDrivers = [ "nvidia" ];

    services.pipewire = {
      enable = true;
      pulse.enable = true;
    };

    systemd.services.steam-session = {
      enable = true;
      after = [
        "systemd-user-sessions.service"
        "systemd-logind.service"
        "virtual-seat@steam.service"
      ];
      wants = [
        "dbus.socket"
        "systemd-logind.service"
        "virtual-seat@steam.service"
      ];
      before = [ "multi-user.target" ];
      wantedBy = [ "multi-user.target" ];

      restartIfChanged = false;
      serviceConfig = {
        ExecStart = utils.escapeSystemdExecArgs ([
          "${lib.getExe pkgs.labwc}"
        ]);
        User = "steam";
        # Set up a full user session for the user to allow allocating a seat
        PAMName = "steam";
      };
      environment = {
        # No input devices are available on startup, make wlroots accept this
        WLR_LIBINPUT_NO_DEVICES = "1";
        WLR_BACKENDS = "headless,libinput";
        XDG_SEAT = "seat-steam";
        XDG_SESSION_CLASS = "user";
        XDG_SESSION_TYPE = "wayland";
      };
    };

    # Configure PAM so that it a session will be created for steam
    security.pam.services.steam.text = ''
      auth    required pam_unix.so nullok
      account required pam_unix.so
      session required pam_unix.so
      session required pam_env.so conffile=/etc/pam/environment readenv=0
      session required ${config.systemd.package}/lib/security/pam_systemd.so
    '';

    services.sunshine = {
      enable = true;
      package = pkgs.sunshine.override { cudaSupport = true; };
      openFirewall = true;
      capSysAdmin = false;
    };

    systemd.user.services.sunshine = {
      # Only run Sunshine for the steam user
      unitConfig.ConditionUser = "steam";
      environment = {
        WAYLAND_DISPLAY = "wayland-0";
      };
    };

    programs.xwayland.enable = true;

    # needed or steam fails
    security.wrappers.bwrap = {
      owner = "root";
      group = "root";
      source = "${pkgs.bubblewrap}/bin/bwrap";
      setuid = true;
    };

    services.avahi.enable = false;

    hardware.uinput.enable = true;

    local.services.virtual-seat.enable = true;

    # Assign Sunshine uinput devices to steam seat
    services.udev.extraRules = ''
      SUBSYSTEM=="input", TAG=="seat", ATTR{name}=="* passthrough", ENV{ID_SEAT}="seat-steam"
    '';

    users = {
      users.steam = {
        isNormalUser = true;
        description = "Steam user";
        group = "steam";
        extraGroups = [
          "audio"
          "video"
          "render"
          "uinput"
        ];
        packages = [
          steam
          pkgs.gamescope
        ];
      };
      groups.steam = { };
    };
  };
}
