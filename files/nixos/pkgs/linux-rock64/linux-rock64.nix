{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

buildLinux (args // rec {
  version = "4.4.103";
  modDirVersion = "4.4.103";
  extraMeta.branch = "4.4";

  src = fetchFromGitHub {
    owner = "ayufan-rock64";
    repo = "linux-kernel";
    rev = "af94955ad8395aceaa820db3da3a9bf2bf7705f1";
    sha256 = "0qgjy54pxwk4g78fjl3zyk1aywx2y4njp4lk9xixmi52gbzmyk9q";
  };
  
  extraConfig = ''
    ARM_ROCKCHIP_DMC_DEVFREQ y
    
    HID_RKVR n
    SENSORS_PWM_FAN n
  '';
#    MALI400_PROFILING n

} // (args.argsOverride or {}))
