{ buildPythonPackage, fetchurlBoot, grpcio-tools, flask, flask-cors, grpcio, pyyaml, numpy, pyalsaaudio, pyserial }:
  
buildPythonPackage rec {
  pname = "audio_recorder";
  version = "0.3.0";

  # Use fetchurlBoot to use netrc file for authentication
  src = fetchurlBoot {
    name = "audio_recorder-${version}.tar.gz";
    url = "https://hydra.benwolsieffer.com/job/audio-recorder/release/web-interface.tarball/latest/download-by-type/file/source-dist";
    sha256 = "fa3c45084ea7ca150953bcd83589919fc487d987f6d8643855fdf2d8e18181f8";
  };

  nativeBuildInputs = [
    grpcio-tools
  ];

  propagatedBuildInputs = [
    flask
    flask-cors
    grpcio
    pyyaml
  ];
}
