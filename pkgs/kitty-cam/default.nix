{ stdenv, buildPythonPackage, flask, flask-cors, lirc }:

buildPythonPackage rec {
  pname = "kitty-cam";
  version = "0.2";

  # Use fetchurlBoot to use netrc file for authentication
  src = stdenv.fetchurlBoot {
    name = "kitty-cam-${version}.tar.gz";
    url = "https://hydra.benwolsieffer.com/job/kitty-cam/release/tarball/latest/download/1";
    sha256 = "1kbvnij6nksmn4xz2lymjf1ic0jjddz230icmfv2dc5xypmzdbkw";
  };

  propagatedBuildInputs = [ flask flask-cors lirc ];
}
