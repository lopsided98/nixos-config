{ buildPythonPackage, fetchurlBoot, flask, flask-cors, lirc }:

buildPythonPackage rec {
  pname = "kitty-cam";
  version = "0.2";

  # Use fetchurlBoot to use netrc file for authentication
  src = fetchurlBoot {
    name = "kitty-cam-${version}.tar.gz";
    url = "https://hydra.benwolsieffer.com/job/kitty-cam/release/tarball/latest/download/1";
    sha256 = "6584ea9b7db9637c61fa3f5b7084405ff23ee0713b48586b38b154eb8d12969f";
  };

  propagatedBuildInputs = [ flask flask-cors lirc ];
}
