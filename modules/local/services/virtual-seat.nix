{
  config,
  lib,
  pkgs,
  utils,
  ...
}:
let
  cfg = config.local.services.virtual-seat;

  virtual-seat =
    let
      code = ''
        #include <fcntl.h>
        #include <unistd.h>
        #include <stdio.h>
        #include <linux/uinput.h>
        #include <systemd/sd-daemon.h>

        int main(int argc, char *argv[]) {
          if (argc < 2) {
            fprintf(stderr, "usage: %s: <name>\n", argv[0]);
            return 2;
          }
          const char *name = argv[1];

          int fd = open("/dev/uinput", O_WRONLY | O_NONBLOCK);
          if (fd < 0) {
            perror("opening /dev/uinput failed");
            return 1;
          }

          struct uinput_setup usetup = {
            .id = {
              .bustype = BUS_USB,
              .vendor = 0x9365,
              .product = 0x0d76,
            },
          };
          snprintf(usetup.name, sizeof(usetup.name), "%s", name);

          int ret = ioctl(fd, UI_DEV_SETUP, &usetup);
          if (ret < 0) {
            perror("ioctl(UI_DEV_SETUP)");
            return 1;
          }
          ret = ioctl(fd, UI_DEV_CREATE);
          if (ret < 0) {
            perror("ioctl(UI_DEV_CREATE)");
            return 1;
          }

          sd_notify(0, "READY=1");

          while (1) {
            sleep(1);
          }

          ret = ioctl(fd, UI_DEV_DESTROY);
          if (ret < 0) {
            perror("ioctl(UI_DEV_DESTROY)");
            return 1;
          }
          return 0;
        }
      '';
    in
    pkgs.runCommandCC "virtual-seat"
      {
        inherit code;
        executable = true;
        passAsFile = [ "code" ];
        buildInputs = [ pkgs.systemd ];
      }
      ''
        $CC -x c "$codePath" -l systemd -o "$out"
      '';
in
{
  options.local.services.virtual-seat.enable = lib.mkEnableOption "virtual logind seats";

  config = lib.mkIf cfg.enable {
    hardware.uinput.enable = true;

    systemd.services."virtual-seat@" = {
      enable = true;

      serviceConfig = {
        Type = "notify";
        ExecStart = "${virtual-seat} %I";
        DynamicUser = true;
        SupplementaryGroups = "uinput";
      };
    };

    services.udev.extraRules = ''
      SUBSYSTEM=="input", TAG=="seat", ATTR{id/bustype}=="0003", ATTR{id/product}=="0d76", ATTR{id/vendor}=="9365", TAG+="master-of-seat", ENV{ID_SEAT}="seat-$attr{name}"
    '';
  };
}
