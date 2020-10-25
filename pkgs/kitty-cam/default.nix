{ stdenv, buildPythonPackage, flask, flask-cors, lirc }:

buildPythonPackage rec {
  pname = "kitty-cam";
  version = "0.2";

  # Use fetchurlBoot to use netrc file for authentication
  src = stdenv.fetchurlBoot {
    name = "kitty-cam-${version}.tar.gz";
    url = "https://hydra.benwolsieffer.com/job/kitty-cam/release/tarball/latest/download/1";
    sha256 = "bda73fab231958af7609ea358b1b4b7ef3625b96068ff985571df15da53af7ac";
  };

  propagatedBuildInputs = [ flask flask-cors lirc ];
}
