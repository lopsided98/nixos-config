{ buildPythonPackage, fetchurlBoot, grpcio-tools, flask, flask-cors, grpcio, pyyaml, numpy, pyalsaaudio, pyserial }:
  
buildPythonPackage rec {
  pname = "audio_recorder";
  version = "0.3.0";

  # Use fetchurlBoot to use netrc file for authentication
  src = fetchurlBoot {
    name = "audio_recorder-${version}.tar.gz";
    url = "https://hydra.benwolsieffer.com/job/audio-recorder/release/web-interface.tarball/latest/download-by-type/file/source-dist";
    sha256 = "92d9dd9cf08b5a3982079d50a385a961c5bbe48dd009ad8d2214ad3f307394f6";
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
