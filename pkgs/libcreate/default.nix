{ stdenv, fetchFromGitHub, cmake, boost }: 

stdenv.mkDerivation {
  name = "libcreate-1.6.0";
  
  src = fetchFromGitHub {
    owner = "AutonomyLab";
    repo = "libcreate";
    rev = "1.6.0";
    sha256 = "14sy38bpnw4hziqb5xczrwhwsn1jls8v2g6s2pkqv1a9cqnv60yn";
  };
  
  patches = [
    ./0001-Replace-serial_port.native-with-native_handle.patch
    ./0002-Add-missing-iostream-include.patch
  ];
  
  nativeBuildInputs = [ cmake ];
  propagatedBuildInputs = [ boost ];
  
  # Tests try to download gtest
  cmakeFlags = [ "-DLIBCREATE_BUILD_TESTS=OFF" ];
}
