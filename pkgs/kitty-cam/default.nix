{ stdenv, buildPythonPackage, flask, flask-cors, lirc }:

buildPythonPackage rec {
  pname = "kitty-cam";
  version = "0.2";

  # Use fetchurlBoot to use netrc file for authentication
  src = stdenv.fetchurlBoot {
    name = "kitty-cam-${version}.tar.gz";
    url = "https://hydra.benwolsieffer.com/job/kitty-cam/release/tarball/latest/download/1";
    sha256 = "0bj19m2l616kxarxc57c9sz3nv27kwdfxz8gdf2kkvn78y92g8wm";
  };

  propagatedBuildInputs = [ flask flask-cors lirc ];
}
