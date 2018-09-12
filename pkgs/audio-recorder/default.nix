{ buildPythonPackage, fetchurlBoot, flask, flask-cors, grpcio, grpcio-tools, numpy, pyyaml, pyalsaaudio, pyserial }:

buildPythonPackage rec {
  pname = "audio-recorder";
  version = "0.2";

  # Use fetchurlBoot to use netrc file for authentication
  src = fetchurlBoot {
    name = "audio_recorder-${version}.tar.gz";
    url = "https://hydra.benwolsieffer.com/job/audio-recorder/release/tarball/latest/download/1";
    sha256 = "16084274fb10810ac9d2706fabf5e9341fd11ef560d5c143f60977db2f51adf1";
  };

  nativeBuildInputs = [ grpcio-tools ];
  propagatedBuildInputs = [ flask flask-cors grpcio numpy pyyaml pyalsaaudio pyserial ];
}
