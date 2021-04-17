{ stdenv, buildPythonPackage, flask, flask-cors, lirc }:

buildPythonPackage rec {
  pname = "kitty-cam";
  version = "0.2";

  # Use fetchurlBoot to use netrc file for authentication
  src = stdenv.fetchurlBoot {
    name = "kitty-cam-${version}.tar.gz";
    url = "https://hydra.benwolsieffer.com/job/kitty-cam/release/tarball/latest/download/1";
    sha256 = "1mcmq71b7ckby6ycw7zxnz58c4jcakqnk56n05zzz2ylcfzrv3hs";
  };

  propagatedBuildInputs = [ flask flask-cors lirc ];
}
