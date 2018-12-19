{ buildPythonPackage, fetchurlBoot, grpcio-tools, flask, flask-cors, grpcio, pyyaml, numpy, pyalsaaudio, pyserial }:
  
buildPythonPackage rec {
  pname = "audio_recorder";
  version = "0.3.0";

  # Use fetchurlBoot to use netrc file for authentication
  src = fetchurlBoot {
    name = "audio_recorder-${version}.tar.gz";
    url = "https://hydra.benwolsieffer.com/job/audio-recorder/release/web-interface.tarball/latest/download-by-type/file/source-dist";
    sha256 = "55f82fbec3d19aa1b119f74c50847c005adef4f0db760e3387979957d3b05fa3";
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
