{ buildPythonPackage, fetchurlBoot, grpcio-tools, flask, flask-cors, grpcio, pyyaml, numpy, pyalsaaudio, pyserial }:
  
buildPythonPackage rec {
  pname = "audio_recorder";
  version = "0.3.0";

  # Use fetchurlBoot to use netrc file for authentication
  src = fetchurlBoot {
    name = "audio_recorder-${version}.tar.gz";
    url = "https://hydra.benwolsieffer.com/job/audio-recorder/release/web-interface.tarball/latest/download-by-type/file/source-dist";
    sha256 = "b5619b4283d9dae7f489d69433dfd5ec9f182a08a67fd9b250ed13a123a300a5";
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
