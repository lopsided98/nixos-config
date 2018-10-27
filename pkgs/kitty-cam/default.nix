{ buildPythonPackage, fetchurlBoot, flask, flask-cors, lirc }:

buildPythonPackage rec {
  pname = "kitty-cam";
  version = "0.2";

  # Use fetchurlBoot to use netrc file for authentication
  src = fetchurlBoot {
    name = "kitty-cam-${version}.tar.gz";
    url = "https://hydra.benwolsieffer.com/job/kitty-cam/release/tarball/latest/download/1";
    sha256 = "61aad0c0b1fd65acdedad007db0cd223801b43e201c06255a135d8f33763a7f4";
  };

  propagatedBuildInputs = [ flask flask-cors lirc ];
}
