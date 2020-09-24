{ lib, buildRosPackage, fetchFromGitHub, message-generation, message-runtime
, roscpp, sensor-msgs, cmake-modules, poco }:

buildRosPackage {
  pname = "ros-ntpd-driver";
  version = "1.2.0";
  
  src = fetchFromGitHub {
    owner = "vooon";
    repo = "ntpd_driver";
    rev = "1.2.0";
    sha256 = "13rsy8ws0b21dz22c8v4hif4a8sgnw0dij8j9hvhhy91bszyavrk";
  };

  buildInputs = [
    message-generation
    message-runtime
    roscpp
    sensor-msgs
    cmake-modules
    poco
  ];

  meta = with lib; {
    description = "Sends TimeReference message time to ntpd server";
    license = licenses.bsd3;
    maintainers = with maintainers; [ lopsided98 ];
    platforms = platforms.all;
  };
}
