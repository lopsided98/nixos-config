{ stdenv, buildPythonPackage, grpcio-tools, flask, flask-cors, grpcio, pyyaml
, numpy, pyalsaaudio, pyserial }:
  
buildPythonPackage rec {
  pname = "audio_recorder";
  version = "0.3.0";

  # Use fetchurlBoot to use netrc file for authentication
  src = stdenv.fetchurlBoot {
    name = "audio_recorder-${version}.tar.gz";
    url = "https://hydra.benwolsieffer.com/job/audio-recorder/release/web-interface.tarball/latest/download-by-type/file/source-dist";
    sha256 = "65d53974efe9f848d9fb7268ca169471d990390336cb8831c30c428282f88e38";
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
