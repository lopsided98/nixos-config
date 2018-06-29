{ config, lib, pkgs, ... }: with lib; let
  cfg = config.modules.doorman;

  doormanShell = (pkgs.writeScriptBin "doorman-shell" ''
    #!${pkgs.stdenv.shell}

    # Based on https://unix.stackexchange.com/a/311680

    # Exit when any command fails
    set -e

    # Save settings of current terminal to restore later
    original_settings="$(${pkgs.coreutils}/bin/stty -g)"

    # Kill background process and restore terminal when this shell exits
    trap 'set +e; ${pkgs.coreutils}/bin/stty "$original_settings"' EXIT

    port="${cfg.device}"

    # Set up serial port (9600 baud, disable DTR on close)
    ${pkgs.coreutils}/bin/stty -F "$port" raw -echo 9600 -hup

    # Set current terminal to pass through everything except Ctrl+Q
    # * "quit undef susp undef" will disable Ctrl+\ and Ctrl+Z handling
    # * "isig intr ^Q" will make Ctrl+D send SIGINT to this script
    ${pkgs.coreutils}/bin/stty raw -echo isig intr ^D quit undef susp undef

    # Let cat read the serial port to the screen in the background
    # Capture PID of background process so it is possible to terminate it
    (${pkgs.coreutils}/bin/cat "$port" 2>/dev/null) & bgPid=$!

    # Redirect all keyboard input to serial port
    ${pkgs.coreutils}/bin/cat > "$port"
  '') // {
    shellPath = "/bin/doorman-shell";
  };

in {

  options.modules.doorman = {
    enable = mkEnableOption "Doorman SSH connection";

    device = mkOption {
      type = types.str;
      description = "Serial port device";
      default = "/dev/ttyUSB0";
    };
  };

  config = mkIf cfg.enable {
    users.users.doorman = {
      isSystemUser = true;
      description = "doorman user";
      shell = doormanShell;
      group = "doorman";
      extraGroups = [ "dialout" ];
      openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDhd9kmFEprlheu8LUilI2NdOwtTcC81QFkrM07TyIO7wiHbz4WgqK5bnoWZ/fjR90Fbt0tldmXjNp/jBCitsKDJ5Ad7IFsyrh7NB99OrUfhBNQansZgjfJHL0fdT88H6w12ntSejI2wyXx/NwOyM4voZ2AHy/+saUQUFiQpDTdkYATQp5w+5NdrIuF8jrDzfuce8KnCg8CdM6be+XQquA3GJf8ybjVc9Xl63ACc+ywGD3NYXtmB4SNj322Iimd/vkLe9ppRjhJ14f5nJt8I3HT1AMjjWfp6Bsl9YHrQwWWU/W2YpPm4lE5DLiUiKwZCQ7aJQKfRulNxKaHbVa9TvUB Doorman" ];
    };

    users.groups.doorman = { };
  };
}
